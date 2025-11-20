# toggle-display-settings
Create a shortcut in Win11 to quickly toggle display settings [relative positions] between sitting and standing configuration. <br>
I got sick of manually going into System > Display and manually dragging displays to rearrange

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
         3 PHL BDM3270        True     True 0 0         2560x1440@60 Hz          DisplayPort
         4 S27B350            True    False -1920 285   1920x1080@59.9400...            HDMI


PS C:\Users\jon> # configure the sitting display settings manually
PS C:\Users\jon> Get-DisplayConfig | Export-Clixml $home\SittingDisplayProfile.xml
PS C:\Users\jon> Get-DisplayInfo

 DisplayId DisplayName      Active  Primary Position    Mode                  ConnectionType
 --------- -----------      ------  ------- --------    ----                  --------------
         1 DELL U2412M        True    False -3840 1     1920x1200@60 Hz                  DVI
         2 DELL U2412M        True    False -1920 1     1920x1200@60 Hz          DisplayPort
         3 PHL BDM3270        True     True 0 0         2560x1440@60 Hz          DisplayPort
         4 S27B350            True    False -1920 -1079 1920x1080@59.9400...            HDMI


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


### Gemini prompt (for reference)
```
help write a powershell windows script, utilizing https://github.com/MartinGC94/DisplayConfig.
the script will toggle between 2 configurations StandingDisplayProfile.xml  and SittingDisplayProfile.xml .   so it needs to first detect which state it is in by using Get-DisplayInfo.  there should be some flexibility in detecting which one, like not exact coordinate match.
finally , how should i make this an icon in my taskbar with a nice icon of a display sit/stand with toggle indicator so it is visually clear what it does
```
