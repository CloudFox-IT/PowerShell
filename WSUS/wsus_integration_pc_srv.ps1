# Chemin du fichier d'import (doit avoir une colonne "Hostname")
$importPath = "C:\Temp\SRVTrancheTest.txt"
# Chemin du fichier d'export
$exportPath = "C:\Temp\resultats_winrm-srv_16H08_23.06.2025.csv"

# Import du CSV
$pcList = Import-Csv -Path $importPath

# Tableau pour stocker les résultats
$results = @()

foreach ($pc in $pcList) {
    $hostname = $pc.Hostname
    Write-Host "Traitement de $hostname..."

    try {
        $result = Invoke-Command -ComputerName $hostname -ScriptBlock {
            $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $hostname = $env:COMPUTERNAME

            # Vérif clé registre WSUS
            $PresenceRegKey = "Not OK"
            $WUServerHTTPS = "Not OK"
            try {
                $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Stop
                if ($reg.WUServer -like "*xxxxxxx*") { $PresenceRegKey = "OK" }
                if ($reg.WUServer -like "https*") { $WUServerHTTPS = "OK" }
            } catch {}

            # DetectNow
            try {
                wuauclt /detectnow
                $DetectNow = "OK"
            } catch { $DetectNow = "Not OK" }

            # ReportNow
            try {
                wuauclt /reportnow
                $ReportNow = "OK"
            } catch { $ReportNow = "Not OK" }

            # GPResultContainsWSUS
            try {
                $gpresult = gpresult /r | Select-String "xxxxxx" -ErrorAction SilentlyContinue
                if ($gpresult) { $GPResultContainsWSUS = "OK" } else { $GPResultContainsWSUS = "Not OK" }
            } catch { $GPResultContainsWSUS = "Not OK" }

            # GPUpdate
            try {
                gpupdate /force | Out-Null
                $GPUpdate = "OK"
            } catch { $GPUpdate = "Not OK" }

            return [PSCustomObject]@{
                Date                  = $date
                Hostname              = $hostname
                PresenceRegKey        = $PresenceRegKey
                WUServerHTTPS         = $WUServerHTTPS
                DetectNow             = $DetectNow
                ReportNow             = $ReportNow
                GPResultContainsWSUS  = $GPResultContainsWSUS
                GPUpdate              = $GPUpdate
            }
        } -ErrorAction Stop

        $results += $result

    } catch {
        # Si la connexion échoue ou autre erreur
        $results += [PSCustomObject]@{
            Date                  = ""
            Hostname              = $hostname
            PresenceRegKey        = "Not OK"
            WUServerHTTPS         = "Not OK"
            DetectNow             = "Not OK"
            ReportNow             = "Not OK"
            GPResultContainsWSUS  = "Not OK"
            GPUpdate              = "Not OK"
        }
    }
}

# Export final
$results | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ Rapport global généré : $exportPath"
