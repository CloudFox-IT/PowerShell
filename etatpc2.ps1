# Chemin du fichier contenant la liste des PC (un nom par ligne)
$csvPath = "C:\Temp\listepcnojoigniable170725.txt"
$pcList = Get-Content -Path $csvPath

# Liste des résultats
$resultats = @()

foreach ($nomPC in $pcList) {
    $nomPC = $nomPC.Trim()
    if (![string]::IsNullOrWhiteSpace($nomPC)) {
        # Test de l'état
        if (Test-Connection -ComputerName $nomPC -Count 1 -Quiet) {
            $etat = "Allumé"
            # Durée depuis le dernier démarrage (en jours, heures, minutes)
            try {
                $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $nomPC -ErrorAction Stop
                $lastBoot = $os.LastBootUpTime
                $uptime = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($lastBoot))
                $uptimeText = "{0} jours, {1} heures, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
            } catch {
                $uptimeText = "Non disponible"
            }

            # Dernier utilisateur connecté (via Win32_ComputerSystem)
            try {
                $cs = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $nomPC -ErrorAction Stop
                $dernierUtilisateur = $cs.UserName
                if (-not $dernierUtilisateur) { $dernierUtilisateur = "Non disponible" }
            } catch {
                $dernierUtilisateur = "Non disponible"
            }

            # Dernier profil utilisateur local (le plus récent utilisé)
            try {
                $profiles = Get-WmiObject -Class Win32_UserProfile -ComputerName $nomPC -ErrorAction Stop | 
                    Where-Object { $_.LocalPath -like "C:\Users\*" -and $_.LastUseTime } |
                    Sort-Object -Property LastUseTime -Descending
                $dernierProfil = if ($profiles) { $profiles[0].LocalPath.Split('\')[-1] } else { "Non trouvé" }
            } catch {
                $dernierProfil = "Non disponible"
            }

            $depuisEteint = "N/A"
        } else {
            $etat = "Éteint ou Inaccessible"
            $uptimeText = "Non disponible"
            $dernierProfil = "Non disponible"
            $dernierUtilisateur = "Non disponible"

            # Pour estimer depuis combien de temps le poste est éteint,
            # on peut utiliser le timestamp du dernier événement 6006 (arrêt) dans l'EventLog si les logs sont collectés ailleurs,
            # mais à distance, sans accès, ce n'est pas possible en natif.
            $depuisEteint = "Inconnu"
        }

        $resultats += [PSCustomObject]@{
            NomPC               = $nomPC
            Etat                = $etat
            Uptime              = $uptimeText
            DernierUtilisateur  = $dernierUtilisateur
            DernierProfil       = $dernierProfil
            DepuisEteint        = $depuisEteint
        }
    }
}

# Exporter les résultats
$resultats | Export-Csv -Path "C:\Temp\etat_pc_resultats_180725okk.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Vérification terminée. Résultats enregistrés dans 'C:\Temp\etat_pc_resultats_250625okk.csv'."
