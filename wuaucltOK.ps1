# Chemin du fichier TXT contenant la liste des serveurs (un par ligne)
$serverList = Get-Content "C:\Temp\SRVTrancheTest.txt"

foreach ($server in $serverList) {
    Write-Host "---- $server ----" -ForegroundColor Cyan

    try {
        Invoke-Command -ComputerName $server -ScriptBlock {
            $regOK = "Non"
            $wsusValue = ""
            $wuaucltOK = "Non exécuté"
            $gpupdateOK = "Non exécuté"

            # Vérification clé registre WSUS
            try {
                $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Stop
                if ($reg.WUServer) {
                    $regOK = "Oui"
                    $wsusValue = $reg.WUServer
                }
            } catch {}

            # Lancement wuauclt /detectnow
            try {
                & wuauclt /detectnow
                $wuaucltOK = "OK"
            } catch {
                $wuaucltOK = "Erreur"
            }

            # Lancement gpupdate /force
            try {
                gpupdate /force | Out-Null
                $gpupdateOK = "OK"
            } catch {
                $gpupdateOK = "Erreur"
            }

            # Résumé à afficher
            [PSCustomObject]@{
                Date      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Hostname  = $env:COMPUTERNAME
                WSUS_Clé  = $regOK
                WSUS_URL  = $wsusValue
                Wuauclt   = $wuaucltOK
                GPUpdate  = $gpupdateOK
            }
        } -ErrorAction Stop | Format-Table -AutoSize
    }
    catch {
        Write-Host "Impossible de contacter $server" -ForegroundColor Red
    }
}
# Export CSV à la fin
$results | Export-Csv -Path "C:\Temp\Resultats_WSUS.csv" -NoTypeInformation -Delimiter ";"
Write-Host "Export terminé : C:\Temp\Resultats_WSUS.csv" -ForegroundColor Green