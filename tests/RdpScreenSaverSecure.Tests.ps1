$ErrorActionPreference = 'Stop'

$ModulePath = Join-Path $PSScriptRoot '..\RdpScreenSaverSecure.psm1'

if (-not (Test-Path -LiteralPath $ModulePath)) {
    throw "Expected module to exist at $ModulePath"
}

Import-Module $ModulePath -Force

function Assert-Equal {
    param(
        [AllowNull()]
        $Expected,

        [AllowNull()]
        $Actual,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if ($null -eq $Expected) {
        if ($null -ne $Actual) {
            throw "$Message. Expected <null>, got <$Actual>."
        }

        return
    }

    if ($Expected -ne $Actual) {
        throw "$Message. Expected <$Expected>, got <$Actual>."
    }
}

$ModeCases = @(
    @{ Name = 'RDP-Tcp sessions are off'; SessionName = 'RDP-Tcp#12'; Expected = 'Off' },
    @{ Name = 'RDP dash sessions are off'; SessionName = 'RDP-ABC'; Expected = 'Off' },
    @{ Name = 'lowercase rdp-tcp sessions are off'; SessionName = 'rdp-tcp#1'; Expected = 'Off' },
    @{ Name = 'console sessions are on'; SessionName = 'Console'; Expected = 'On' },
    @{ Name = 'unknown sessions are skipped'; SessionName = 'Services'; Expected = $null }
)

foreach ($Case in $ModeCases) {
    $Actual = Resolve-RdpScreenSaverSecureMode -RequestedMode Auto -SessionName $Case.SessionName
    Assert-Equal -Expected $Case.Expected -Actual $Actual -Message $Case.Name
}

Assert-Equal `
    -Expected 'On' `
    -Actual (Resolve-RdpScreenSaverSecureMode -RequestedMode On -SessionName 'RDP-Tcp#12') `
    -Message 'explicit On ignores session name'

Assert-Equal `
    -Expected 'Off' `
    -Actual (Resolve-RdpScreenSaverSecureMode -RequestedMode Off -SessionName 'Console') `
    -Message 'explicit Off ignores session name'

Assert-Equal `
    -Expected '1' `
    -Actual (ConvertTo-RdpScreenSaverSecureRegistryValue -Mode On) `
    -Message 'On maps to registry value 1'

Assert-Equal `
    -Expected '0' `
    -Actual (ConvertTo-RdpScreenSaverSecureRegistryValue -Mode Off) `
    -Message 'Off maps to registry value 0'

$WhatIfResult = Set-RdpScreenSaverSecure `
    -Mode On `
    -DesktopKeyPath 'HKCU:\Control Panel\Desktop' `
    -LogPath '' `
    -SessionName 'Console' `
    -SkipSystemRefresh `
    -WhatIf

Assert-Equal `
    -Expected $false `
    -Actual $WhatIfResult.Changed `
    -Message 'WhatIf reports no change'

Write-Host 'RdpScreenSaverSecure tests passed.'
