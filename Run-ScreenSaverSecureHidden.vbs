Option Explicit

Dim Shell
Dim PowerShellPath
Dim ScriptPath
Dim Mode
Dim Command

If WScript.Arguments.Count <> 2 Then
    WScript.Quit 2
End If

Set Shell = CreateObject("WScript.Shell")

PowerShellPath = Shell.ExpandEnvironmentStrings( _
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
ScriptPath = WScript.Arguments(0)
Mode = WScript.Arguments(1)

Command = Quote(PowerShellPath) & _
    " -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File " & _
    Quote(ScriptPath) & " -Mode " & Quote(Mode)

WScript.Quit Shell.Run(Command, 0, True)

Function Quote(Value)
    Quote = Chr(34) & Value & Chr(34)
End Function
