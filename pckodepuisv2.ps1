# Lire la liste des ordinateurs depuis un fichier texte
$pcs = Get-Content -Path "C:\Temp\Tranche4.5.6.txt"

# Créer une liste pour stocker les résultats
$results = @()

foreach ($pc in $pcs) {
    try {
        # Obtenir la dernière heure de démarrage
        $os = Get-CimInstance -ComputerName $pc -ClassName Win32_OperatingSystem -ErrorAction Stop
        $lastBoot = $os.LastBootUpTime
        $now = Get-Date
        $uptime = $now - $lastBoot

        # Ajouter les résultats à la liste
        $results += [PSCustomObject]@{
            Nom_PC           = $pc
            Dernier_Demarrage = $lastBoot
            Duree_Allumage   = $uptime.ToString()
        }
    }
    catch {
        # En cas d'erreur (PC inaccessible, éteint, etc.)
        $results += [PSCustomObject]@{
            Nom_PC           = $pc
            Dernier_Demarrage = "Inaccessible"
            Duree_Allumage   = "Inconnu ou éteint"
        }
    }
}

# Exporter les résultats dans un nouveau fichier CSV
$results | Export-Csv -Path "C:\Temp\shutdown_durations4.5.6.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Export terminé : C:\Temp\shutdown_durations4.5.6.csv"
