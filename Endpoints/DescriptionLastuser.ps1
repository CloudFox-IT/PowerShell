# Chemin du fichier contenant la liste des PCs (un nom par ligne)
$PCList = Get-Content "C:\Temp\ListeNomsPCkowsus.txt"

# Résultat final
$results = @()

foreach ($PC in $PCList) {
    # Récupérer l'objet AD Computer
    $adComputer = Get-ADComputer -Identity $PC -Properties Description

    # Récupérer la description AD
    $description = $adComputer.Description

    # Tenter de récupérer le dernier utilisateur connecté via WMI
    try {
        $lastUser = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $PC -ErrorAction Stop).UserName
    } catch {
        $lastUser = "Erreur ou inaccessible"
    }

    # Ajouter au tableau de résultats
    $results += [PSCustomObject]@{
        ComputerName = $PC
        Description  = $description
        LastUser     = $lastUser
    }
}

# Exporter les résultats dans un CSV
$results | Export-Csv "C:\Temp\Resultatspcko.csv" -NoTypeInformation -Delimiter ";"

# Afficher les résultats à l'écran
$results
