<#
.SYNOPSIS
    Toggles between Standing and Sitting display profiles based on fuzzy coordinate matching.
.DESCRIPTION
    Uses MartinGC94.DisplayConfig to compare the current live display topology 
    against saved XML profiles. It calculates the "distance" (difference in X/Y coordinates) 
    to determine the current state and applies the opposite profile.
#>

param (
    [string]$ProfilePath = "$HOME",
    [string]$StandingFile = "StandingDisplayProfile.xml",
    [string]$SittingFile = "SittingDisplayProfile.xml"
)

# Import the module
Import-Module DisplayConfig

# Construct full paths
$StandingXml = Join-Path -Path $ProfilePath -ChildPath $StandingFile
$SittingXml  = Join-Path -Path $ProfilePath -ChildPath $SittingFile

# Error handling if files don't exist
if (-not (Test-Path $StandingXml) -or -not (Test-Path $SittingXml)) {
    Write-Error "Profile XML files not found in $ProfilePath."
    exit 1
}

# 1. Load the saved configurations
$StandingConfig = Import-Clixml -Path $StandingXml
$SittingConfig  = Import-Clixml -Path $SittingXml

# 2. Get Display Info for comparisons
# Note: Get-DisplayInfo can parse offline configs via the -DisplayConfig parameter
$StandingInfo = Get-DisplayInfo -DisplayConfig $StandingConfig
$SittingInfo  = Get-DisplayInfo -DisplayConfig $SittingConfig
$CurrentInfo  = Get-DisplayInfo # Live current state

# 3. Define Fuzzy Logic Function
# Calculates total pixel deviation between current state and a target profile
function Get-ConfigDeviation {
    param ($SourceInfo, $TargetInfo)
    
    $TotalDeviation = 0
    
    foreach ($Display in $SourceInfo) {
        # Find corresponding display in target by ID
        $Match = $TargetInfo | Where-Object { $_.DisplayId -eq $Display.DisplayId }
        
        if ($Match) {
            # Calculate absolute difference in X and Y
            $DiffX = [Math]::Abs($Display.Position.x - $Match.Position.x)
            $DiffY = [Math]::Abs($Display.Position.y - $Match.Position.y)
            $TotalDeviation += ($DiffX + $DiffY)
        }
    }
    return $TotalDeviation
}

# 4. Compare Current State to Profiles
$ScoreStanding = Get-ConfigDeviation -SourceInfo $CurrentInfo -TargetInfo $StandingInfo
$ScoreSitting  = Get-ConfigDeviation -SourceInfo $CurrentInfo -TargetInfo $SittingInfo

# 5. Determine Action
# We switch to the state that has the HIGHER deviation (meaning we are NOT currently in that state)
# If scores are equal or close, default to Standing.

$UseAdapterIds = $true # Recommended for imported configs

Add-Type -AssemblyName System.Windows.Forms
$Notification = New-Object System.Windows.Forms.NotifyIcon
$Notification.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
$Notification.Visible = $true

if ($ScoreStanding -le $ScoreSitting) {
    # We are currently closer to Standing -> Switch to SITTING
    Write-Host "Detected State: Standing (Deviation: $ScoreStanding). Switching to Sitting..."
    
    $SittingConfig | Use-DisplayConfig -UpdateAdapterIds:$UseAdapterIds -AllowChanges
    $Notification.ShowBalloonTip(1000, "Display Toggle", "Switched to SITTING Mode", [System.Windows.Forms.ToolTipIcon]::Info)
}
else {
    # We are currently closer to Sitting -> Switch to STANDING
    Write-Host "Detected State: Sitting (Deviation: $ScoreSitting). Switching to Standing..."
    
    $StandingConfig | Use-DisplayConfig -UpdateAdapterIds:$UseAdapterIds -AllowChanges
    $Notification.ShowBalloonTip(1000, "Display Toggle", "Switched to STANDING Mode", [System.Windows.Forms.ToolTipIcon]::Info)
}

# Cleanup notification icon from tray
Start-Sleep -Seconds 2
$Notification.Dispose()