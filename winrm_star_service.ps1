$computers = Get-Content -Path "C:\Temp\forwinrm200625.txt"

Invoke-Command -ComputerName $computers -ScriptBlock {
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
    Get-Service -Name WinRM
}