# Chemin du fichier source
$fichierSource = "C:\Temp\listepcko270625.txt"
# Chemin du fichier de sortie
$fichierSortie = "C:\Temp\listepcko270625ko.txt"

# Extraction et sauvegarde
Get-Content $fichierSource | ForEach-Object {
    $ligne = $_.Trim()
    if ($ligne -and -not ($ligne -like "Nom_PC*")) { # Ignore l'entête si présente
        ($ligne -split '\.')[0]
    }
} | Set-Content $fichierSortie

Write-Output "Extraction terminée. Résultats dans $fichierSortie"
