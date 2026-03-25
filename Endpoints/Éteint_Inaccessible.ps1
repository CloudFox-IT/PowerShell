# Lire le fichier CSV
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$csvPath = Join-Path $scriptPath "pc_list.csv"
$pcList = Import-Csv -Path $csvPath

# Liste des résultats
$resultats = @()

foreach ($pc in $pcList) {
    $nomPC = $pc.Nom.Trim()

    # Vérifie que le nom n'est pas vide
    if (![string]::IsNullOrWhiteSpace($nomPC)) {
        $etat = if (Test-Connection -ComputerName $nomPC -Count 1 -Quiet) {
            "Allumé"
        } else {
            "Éteint ou Inaccessible"
        }

        $resultats += [PSCustomObject]@{
            NomPC = $nomPC
            État  = $etat
        }
    }
}

# Exporter les résultats
$resultats | Export-Csv -Path "C:\Temp\wsusforpc_status_result.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Vérification terminée. Résultats enregistrés dans 'resultats_etat_pc.csv'."
