# Lire la liste des ordinateurs depuis un fichier texte
$pcs = Get-Content -Path "C:\Temp\listepcverif1906.txt"

# Créer une liste pour stocker les résultats
$results = @()

# Calculer la durée pendant laquelle chaque PC est éteint
foreach ($pc in $pcs) {
    $pcName = $pc.Name
    $lastBootTime = (Get-CimInstance -ComputerName $pcName -ClassName Win32_OperatingSystem).LastBootUpTime
    $currentTime = Get-Date
    $shutdownDuration = $currentTime - $lastBootTime
    $results += [PSCustomObject]@{
        Name = $pcName
        ShutdownDuration = $shutdownDuration
    }
}

# Exporter les résultats dans un nouveau fichier CSV
$results | Export-Csv -Path "C:\Temp\shutdown_durations.csv" -NoTypeInformation

Write-Output "Les durées d'arrêt ont été enregistrées avec succès dans shutdown_durations.csv."

