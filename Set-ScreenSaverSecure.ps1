<#
.SYNOPSIS
    Sets the "On resume, display logon screen" screen saver checkbox.
.DESCRIPTION
    On sets HKCU:\Control Panel\Desktop\ScreenSaverIsSecure to 1.
    Off sets it to 0. Auto turns it off for RDP sessions and on for Console sessions.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('On', 'Off', 'Auto')]
    [string] $Mode = 'Auto',

    [int] $DelayMilliseconds = 500,

    [string] $LogPath = (Join-Path (Join-Path $env:LOCALAPPDATA 'RdpScreenSaverSecure') 'events.log')
)

$ErrorActionPreference = 'Stop'

$ModulePath = Join-Path $PSScriptRoot 'RdpScreenSaverSecure.psm1'
Import-Module $ModulePath -Force

if ($DelayMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $DelayMilliseconds
}

Set-RdpScreenSaverSecure -Mode $Mode -LogPath $LogPath -WhatIf:$WhatIfPreference
