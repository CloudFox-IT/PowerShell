Invoke-Command -ComputerName "xxx.","xxx" -ScriptBlock {
    winrm quickconfig -force
    Set-Service -Name WinRM -StartupType Automatic
}