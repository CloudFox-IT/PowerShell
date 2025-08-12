$Machines = Get-Content "C:\Temp\liste_postes_a_corriger.txt"

foreach ($Machine in $Machines) {
    try {
        Invoke-Command -ComputerName $Machine -ScriptBlock {
            # Arrêt du service Windows Update
            Stop-Service -Name wuauserv -Force

            # Suppression de l'ID WSUS existant
            Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\AccountDomainSid" -ErrorAction SilentlyContinue
            Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\PingID" -ErrorAction SilentlyContinue
            Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SusClientId" -ErrorAction SilentlyContinue
            Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\SusClientIdValidation" -ErrorAction SilentlyContinue

            # Redémarrage du service
            Start-Service -Name wuauserv

            # Forcer la re-génération de l'ID et la détection WSUS
            wuauclt.exe /resetauthorization /detectnow
            wuauclt.exe /reportnow
        } -ErrorAction Stop
        Write-Host "$Machine : Réinitialisation et détection OK" -ForegroundColor Green
    } catch {
        Write-Host "$Machine : Erreur - $_" -ForegroundColor Red
    }
}
