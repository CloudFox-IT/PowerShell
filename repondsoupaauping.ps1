# Chemin du CSV source
$csvPath = "C:\Temp\etat_pc_resultats_250625okk.csv"
# Chemin du CSV de sortie
$outputPath = "C:\Temp\resultats_ping.csv"

# Importer la liste des PC
$pcList = Import-Csv -Path $csvPath

# Liste pour stocker les résultats
$resultats = @()

foreach ($pc in $pcList) {
    $nomPC = $pc.NomPC.Trim()
    if (![string]::IsNullOrWhiteSpace($nomPC)) {
        $pingOK = $false
        $tempsKO = 0

        # Mesurer le temps de ping
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $pingOK = Test-Connection -ComputerName $nomPC -Count 1 -TimeoutSeconds 2 -Quiet
        $sw.Stop()
        $tempsKO = $sw.Elapsed.TotalSeconds

        if ($pingOK) {
            $etat = "Répond"
            $tempsKO = 0
        } else {
            $etat = "Ne répond pas"
            # $tempsKO contient le temps d'attente avant l'échec
        }

        $resultats += [PSCustomObject]@{
            NomPC    = $nomPC
            Etat     = $etat
            TempsKO  = [Math]::Round($tempsKO, 2)
        }
    }
}

# Exporter les résultats
$resultats | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Output "Résultats enregistrés dans '$outputPath'"
