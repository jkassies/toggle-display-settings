# toggle-display-settings
Create a shortcut in Win11 to quickly toggle display settings [relative positions] between sitting and standing configuration. <br>
I got sick of manually going into System > Display and dragging displays to rearrange

update powershell
```powershell
winget install --id Microsoft.PowerShell --source winget
```
install [DisplayConfig](https://github.com/MartinGC94/DisplayConfig)
```powershell
Install-Module -Name DisplayConfig
```

Export desired settings
```powershell
PS C:\Users\jon> # from the standing position
PS C:\Users\jon> Get-DisplayConfig | Export-Clixml $home\StandingDisplayProfile.xml
PS C:\Users\jon> Get-DisplayInfo

 DisplayId DisplayName      Active  Primary Position    Mode                  ConnectionType
 --------- -----------      ------  ------- --------    ----                  --------------
         1 DELL U2412M        True    False -3840 1365  1920x1200@60 Hz                  DVI
         2 DELL U2412M        True    False -1920 1365  1920x1200@60 Hz          DisplayPort
         3 LS37D80xU          True     True 0 0         3840x2160@60 Hz          DisplayPort
         4 PHL BDM3270        True    False -2561 285   2560x1440@60 Hz                 HDMI


PS C:\Users\jon> # configure the sitting display settings manually (Samsung Viewfinity 37" 4K = LS37D80xU)
PS C:\Users\jon> Get-DisplayConfig | Export-Clixml $home\SittingDisplayProfile.xml
PS C:\Users\jon> Get-DisplayInfo

 DisplayId DisplayName      Active  Primary Position    Mode                  ConnectionType
 --------- -----------      ------  ------- --------    ----                  --------------
         1 DELL U2412M        True    False -3840 773   1920x1200@60 Hz                  DVI
         2 DELL U2412M        True    False -1920 773   1920x1200@60 Hz          DisplayPort
         3 LS37D80xU          True     True 0 0         3840x2160@60 Hz          DisplayPort
         4 PHL BDM3270        True    False -2561 -667  2560x1440@60 Hz                 HDMI


PS C:\Users\jon> Import-Module DisplayConfig
PS C:\Users\jon> Import-Clixml $home\StandingDisplayProfile.xml | Use-DisplayConfig -UpdateAdapterIds
PS C:\Users\jon> # now back to standing
```


### Create the Shortcut

1. Right-click on your Desktop -> New -> Shortcut.
2. Paste the following into the location box (adjusting the path to your script):
  
```Plaintext
pwsh.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\jon\Toggle-DisplayState.ps1"
```
(Note: Use powershell.exe if you are not using PowerShell Core/7, though pwsh is preferred for modern setups).

3. Name it "Toggle Display Mode".

### RDP screen saver secure checkbox

Windows stores the screen saver setting "On resume, display logon screen" in:

```powershell
HKCU:\Control Panel\Desktop\ScreenSaverIsSecure
```

`0` means unchecked. `1` means checked.

This repo includes a setup script for this behavior:

```text
RDP login / reconnect -> checkbox OFF
Local login / unlock  -> checkbox ON
```

It only changes `ScreenSaverIsSecure`. It does not change the screen saver, timeout, sleep, or power settings.

Install the scheduled tasks:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-RdpScreenSaverSecure.ps1
```

The installer copies the runner to:

```powershell
$env:LOCALAPPDATA\RdpScreenSaverSecure\Set-ScreenSaverSecure.ps1
```

It creates these scheduled tasks under `Task Scheduler Library\RdpScreenSaverSecure`:

- `RDP login sets screen saver secure OFF`
- `Local login sets screen saver secure ON`
- `Logon unlock applies correct screen saver secure state`

Verify the current value:

```powershell
Get-ItemProperty 'HKCU:\Control Panel\Desktop' |
    Select-Object ScreenSaverIsSecure
```

Manual controls:

```powershell
& "$env:LOCALAPPDATA\RdpScreenSaverSecure\Set-ScreenSaverSecure.ps1" -Mode Off
& "$env:LOCALAPPDATA\RdpScreenSaverSecure\Set-ScreenSaverSecure.ps1" -Mode On
& "$env:LOCALAPPDATA\RdpScreenSaverSecure\Set-ScreenSaverSecure.ps1" -Mode Auto
```

Logs are written to:

```powershell
$env:LOCALAPPDATA\RdpScreenSaverSecure\events.log
```

Remove the setup:

```powershell
Unregister-ScheduledTask -TaskPath '\RdpScreenSaverSecure\' -TaskName 'RDP login sets screen saver secure OFF' -Confirm:$false
Unregister-ScheduledTask -TaskPath '\RdpScreenSaverSecure\' -TaskName 'Local login sets screen saver secure ON' -Confirm:$false
Unregister-ScheduledTask -TaskPath '\RdpScreenSaverSecure\' -TaskName 'Logon unlock applies correct screen saver secure state' -Confirm:$false

$Service = New-Object -ComObject Schedule.Service
$Service.Connect()
$Service.GetFolder('\').DeleteFolder('RdpScreenSaverSecure', 0)

Remove-Item "$env:LOCALAPPDATA\RdpScreenSaverSecure" -Recurse -Force
```


### Gemini prompt (for reference)
```
help write a powershell windows script, utilizing https://github.com/MartinGC94/DisplayConfig.
the script will toggle between 2 configurations StandingDisplayProfile.xml  and SittingDisplayProfile.xml .   so it needs to first detect which state it is in by using Get-DisplayInfo.  there should be some flexibility in detecting which one, like not exact coordinate match.
finally , how should i make this an icon in my taskbar with a nice icon of a display sit/stand with toggle indicator so it is visually clear what it does
```
