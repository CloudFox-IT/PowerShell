$serverList = Get-Content "C:\Temp\listepcnomaj25062025ok.txt"
$results = @()

foreach ($server in $serverList) {
    Write-Host "---- $server ----" -ForegroundColor Cyan

    try {
        $result = Invoke-Command -ComputerName $server -ScriptBlock {
            $regOK = "Non"
            $wsusValue = ""
            $wuaucltOK = "Non exécuté"
            $gpupdateOK = "Non exécuté"

            try {
                $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Stop
                if ($reg.WUServer) {
                    $regOK = "Oui"
                    $wsusValue = $reg.WUServer
                }
            } catch {}

            try {
                & wuauclt /detectnow
                $wuaucltOK = "OK"
            } catch {
                $wuaucltOK = "Erreur"
            }

            try {
                gpupdate /force | Out-Null
                $gpupdateOK = "OK"
            } catch {
                $gpupdateOK = "Erreur"
            }

            # On retourne l'objet AVEC les bons noms de colonnes
            [PSCustomObject]@{
                Date           = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                Hostname       = $env:COMPUTERNAME
                PresenceRegKey = $regOK
                WUServerHTTPS  = $wsusValue
                DetectNow      = $wuaucltOK
                ReportNow      = ""
                GPResultContainsWSUS = ""
                GPUpdate       = $gpupdateOK
            }
        } -ErrorAction Stop

        $result | Format-Table -AutoSize
        $results += $result
    }
    catch {
        Write-Host "Impossible de contacter $server" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Date           = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Hostname       = $server
            PresenceRegKey = "Not OK"
            WUServerHTTPS  = "Not OK"
            DetectNow      = "Not OK"
            ReportNow      = "Not OK"
            GPResultContainsWSUS = "Not OK"
            GPUpdate       = "Not OK"
        }
    }
}

# Export CSV à la fin
$results | Export-Csv -Path "C:\Temp\Resultats_WSUS_25062025.csv" -NoTypeInformation -Delimiter ";"
Write-Host "Export terminé : C:\Temp\Resultats_WSUS_25062025.csv" -ForegroundColor Green
