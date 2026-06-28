Set-StrictMode -Version Latest

function Get-RdpScreenSaverSecureSessionName {
    [CmdletBinding()]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:SESSIONNAME)) {
        return $env:SESSIONNAME
    }

    try {
        $Output = & "$env:windir\System32\qwinsta.exe" 2>$null

        foreach ($Line in $Output) {
            if ($Line -match '^\s*>(\S+)') {
                return $Matches[1]
            }
        }
    }
    catch {
        return ''
    }

    return ''
}

function Resolve-RdpScreenSaverSecureMode {
    [CmdletBinding()]
    param(
        [ValidateSet('On', 'Off', 'Auto')]
        [string] $RequestedMode = 'Auto',

        [AllowNull()]
        [string] $SessionName = ''
    )

    if ($RequestedMode -eq 'On' -or $RequestedMode -eq 'Off') {
        return $RequestedMode
    }

    if ([string]::IsNullOrWhiteSpace($SessionName)) {
        return $null
    }

    if ($SessionName -match '^(RDP-|rdp-tcp)') {
        return 'Off'
    }

    if ($SessionName -ieq 'Console') {
        return 'On'
    }

    return $null
}

function ConvertTo-RdpScreenSaverSecureRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('On', 'Off')]
        [string] $Mode
    )

    if ($Mode -eq 'On') {
        return '1'
    }

    return '0'
}

function Set-RdpScreenSaverSecure {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('On', 'Off', 'Auto')]
        [string] $Mode = 'Auto',

        [string] $DesktopKeyPath = 'HKCU:\Control Panel\Desktop',

        [string] $LogPath = (Join-Path (Join-Path $env:LOCALAPPDATA 'RdpScreenSaverSecure') 'events.log'),

        [AllowNull()]
        [string] $SessionName,

        [switch] $SkipSystemRefresh
    )

    if (-not $PSBoundParameters.ContainsKey('SessionName')) {
        $SessionName = Get-RdpScreenSaverSecureSessionName
    }

    $EffectiveMode = Resolve-RdpScreenSaverSecureMode -RequestedMode $Mode -SessionName $SessionName

    if ($null -eq $EffectiveMode) {
        return [pscustomobject] @{
            SessionName         = $SessionName
            RequestedMode       = $Mode
            AppliedMode         = $null
            ScreenSaverIsSecure = $null
            Changed             = $false
        }
    }

    $Value = ConvertTo-RdpScreenSaverSecureRegistryValue -Mode $EffectiveMode
    $Target = Join-Path $DesktopKeyPath 'ScreenSaverIsSecure'
    $Changed = $false

    if ($PSCmdlet.ShouldProcess($Target, "Set to $Value")) {
        New-ItemProperty `
            -Path $DesktopKeyPath `
            -Name ScreenSaverIsSecure `
            -Value $Value `
            -PropertyType String `
            -Force | Out-Null

        if (-not $SkipSystemRefresh) {
            & "$env:windir\System32\rundll32.exe" user32.dll,UpdatePerUserSystemParameters
        }

        if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
            $LogRoot = Split-Path -Path $LogPath -Parent

            if (-not [string]::IsNullOrWhiteSpace($LogRoot)) {
                New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
            }

            "$(Get-Date -Format o) Session=$SessionName Requested=$Mode Applied=$EffectiveMode ScreenSaverIsSecure=$Value" |
                Add-Content -Path $LogPath
        }

        $Changed = $true
    }

    return [pscustomobject] @{
        SessionName         = $SessionName
        RequestedMode       = $Mode
        AppliedMode         = $EffectiveMode
        ScreenSaverIsSecure = $Value
        Changed             = $Changed
    }
}

Export-ModuleMember -Function `
    Get-RdpScreenSaverSecureSessionName, `
    Resolve-RdpScreenSaverSecureMode, `
    ConvertTo-RdpScreenSaverSecureRegistryValue, `
    Set-RdpScreenSaverSecure
