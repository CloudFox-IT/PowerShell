# Charger le module WSUS
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null

# Connexion au serveur WSUS
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer("https:\\xxxxx.xxxxxx", $False)

# Charger la liste des PC depuis un fichier
$listePC = Get-Content "listepcnojoigniable170725.txt"

# Récupérer tous les ordinateurs dans WSUS
$wsusComputers = $wsus.GetComputerTargetGroups() | ForEach-Object {
    $_.GetComputerTargets() | ForEach-Object {
        [PSCustomObject]@{
            NomPC = $_.FullDomainName
            Groupe = $_.ComputerTargetGroupName
        }
    }
}

# Comparer la liste avec WSUS
foreach ($pc in $listePC) {
    $resultat = $wsusComputers | Where-Object { $_.NomPC -like "*$pc*" }
    if ($resultat) {
        Write-Host "$pc trouvé dans WSUS - Groupe: $($resultat.Groupe)"
    } else {
        Write-Host "$pc non trouvé dans WSUS"
    }
}
