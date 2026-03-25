$wsusServer = "http://tonserveurwsus:8530"

Write-Host "WSUS Config:"
reg query HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate

Write-Host "Etat du service Windows Update:"
Get-Service wuauserv

Write-Host "Détection manuelle en cours..."
wuauclt.exe /detectnow
wuauclt.exe /reportnow

Write-Host "Contenu du log Windows Update:"
Get-Content C:\Windows\WindowsUpdate.log -Tail 30
