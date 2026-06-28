<#
.SYNOPSIS
    Installs scheduled tasks that toggle the screen saver secure checkbox for RDP and local sessions.
#>

[CmdletBinding()]
param(
    [string] $Root = (Join-Path $env:LOCALAPPDATA 'RdpScreenSaverSecure'),

    [switch] $SkipInitialRun
)

$ErrorActionPreference = 'Stop'

$SwitcherSource = Join-Path $PSScriptRoot 'Set-ScreenSaverSecure.ps1'
$ModuleSource = Join-Path $PSScriptRoot 'RdpScreenSaverSecure.psm1'

foreach ($Source in @($SwitcherSource, $ModuleSource)) {
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Required file not found: $Source"
    }
}

New-Item -ItemType Directory -Path $Root -Force | Out-Null

$SwitcherPath = Join-Path $Root 'Set-ScreenSaverSecure.ps1'
$ModulePath = Join-Path $Root 'RdpScreenSaverSecure.psm1'
$LogPath = Join-Path $Root 'events.log'

Copy-Item -LiteralPath $SwitcherSource -Destination $SwitcherPath -Force
Copy-Item -LiteralPath $ModuleSource -Destination $ModulePath -Force

$TaskFolderName = 'RdpScreenSaverSecure'
$TaskFolderPath = "\$TaskFolderName"

$UserId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$PowerShellExe = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"

$TASK_ACTION_EXEC = 0
$TASK_CREATE_OR_UPDATE = 6
$TASK_LOGON_INTERACTIVE_TOKEN = 3
$TASK_TRIGGER_LOGON = 9
$TASK_TRIGGER_SESSION_STATE_CHANGE = 11

$TASK_CONSOLE_CONNECT = 1
$TASK_REMOTE_CONNECT = 3
$TASK_SESSION_UNLOCK = 8

$Service = New-Object -ComObject Schedule.Service
$Service.Connect()

$RootFolder = $Service.GetFolder('\')

try {
    $Folder = $Service.GetFolder($TaskFolderPath)
}
catch {
    $Folder = $RootFolder.CreateFolder($TaskFolderName)
}

function Register-RdpScreenSaverSecureTask {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Description,

        [Parameter(Mandatory)]
        [ValidateSet('On', 'Off', 'Auto')]
        [string] $Mode,

        [int[]] $SessionStateChanges = @(),

        [switch] $AtLogon
    )

    $Task = $Service.NewTask(0)

    $Task.RegistrationInfo.Author = $UserId
    $Task.RegistrationInfo.Description = $Description

    $Task.Principal.UserId = $UserId
    $Task.Principal.LogonType = $TASK_LOGON_INTERACTIVE_TOKEN
    $Task.Principal.RunLevel = 0

    $Task.Settings.Enabled = $true
    $Task.Settings.Hidden = $false
    $Task.Settings.AllowDemandStart = $true
    $Task.Settings.StartWhenAvailable = $true
    $Task.Settings.DisallowStartIfOnBatteries = $false
    $Task.Settings.StopIfGoingOnBatteries = $false
    $Task.Settings.ExecutionTimeLimit = 'PT1M'

    if ($AtLogon) {
        $Trigger = $Task.Triggers.Create($TASK_TRIGGER_LOGON)
        $Trigger.Enabled = $true
        $Trigger.UserId = $UserId
    }

    foreach ($StateChange in $SessionStateChanges) {
        $Trigger = $Task.Triggers.Create($TASK_TRIGGER_SESSION_STATE_CHANGE)
        $Trigger.Enabled = $true
        $Trigger.UserId = $UserId
        $Trigger.StateChange = $StateChange
    }

    $Action = $Task.Actions.Create($TASK_ACTION_EXEC)
    $Action.Path = $PowerShellExe
    $Action.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$SwitcherPath`" -Mode $Mode"

    $Folder.RegisterTaskDefinition(
        $Name,
        $Task,
        $TASK_CREATE_OR_UPDATE,
        $UserId,
        $null,
        $TASK_LOGON_INTERACTIVE_TOKEN
    ) | Out-Null
}

Register-RdpScreenSaverSecureTask `
    -Name 'RDP login sets screen saver secure OFF' `
    -Description 'Unchecks "On resume, display logon screen" when connecting by RDP.' `
    -Mode Off `
    -SessionStateChanges @($TASK_REMOTE_CONNECT)

Register-RdpScreenSaverSecureTask `
    -Name 'Local login sets screen saver secure ON' `
    -Description 'Checks "On resume, display logon screen" when returning to the local console.' `
    -Mode On `
    -SessionStateChanges @($TASK_CONSOLE_CONNECT)

Register-RdpScreenSaverSecureTask `
    -Name 'Logon unlock applies correct screen saver secure state' `
    -Description 'At logon or unlock, sets the checkbox based on whether the session is Console or RDP.' `
    -Mode Auto `
    -AtLogon `
    -SessionStateChanges @($TASK_SESSION_UNLOCK)

if (-not $SkipInitialRun) {
    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $SwitcherPath -Mode Auto
}

Write-Host ''
Write-Host 'Done.'
Write-Host ''
Write-Host 'Created script:'
Write-Host "  $SwitcherPath"
Write-Host ''
Write-Host 'Created scheduled tasks:'
Write-Host "  Task Scheduler Library\$TaskFolderName\RDP login sets screen saver secure OFF"
Write-Host "  Task Scheduler Library\$TaskFolderName\Local login sets screen saver secure ON"
Write-Host "  Task Scheduler Library\$TaskFolderName\Logon unlock applies correct screen saver secure state"
Write-Host ''
Write-Host 'Log file:'
Write-Host "  $LogPath"
