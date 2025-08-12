# Charger la liste des postes depuis un fichier CSV
$computers = Import-Csv -Path "C:\Temp\verif_winrm2.csv"  # Le fichier doit contenir une colonne "Nom_PC"

# Résultats
$results = @()

foreach ($pc in $computers) {
    $hostname = $pc.Nom_PC

    if ([string]::IsNullOrWhiteSpace($hostname)) {
        $results += [PSCustomObject]@{
            Nom_PC = "<Nom vide>"
            Statut = "Erreur : nom de poste vide"
            Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        continue
    }

    Write-Host "Configuration WinRM sur $hostname ..."
    try {
        $cmd = 'winrm quickconfig -quiet'
        $result = Invoke-WmiMethod -ComputerName $hostname -Class Win32_Process -Name Create -ArgumentList $cmd -ErrorAction Stop

        if ($result.ProcessId) {
            $status = "Succès (PID $($result.ProcessId))"
        } else {
            $status = "Commande envoyée, pas de PID"
        }
    } catch {
        $status = "Échec : $($_.Exception.Message)"
    }

    $results += [PSCustomObject]@{
        Nom_PC = $hostname
        Statut = $status
        Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Exporter les résultats
$results | Export-Csv -Path "C:\Temp\resultats_winrm_quickconfig.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Configuration terminée. Résultats : C:\Temp\resultats_winrm_quickconfig.csv"
