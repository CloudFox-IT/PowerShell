# Lire les noms de postes depuis un fichier CSV
$computers = Import-Csv -Path "C:\Temp\listepcnomaj25062025ok.txt"  # Le fichier doit avoir une colonne "Nom_PC"

# Commande à exécuter sur chaque poste
$fwRuleCmd = 'netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985'

# Liste pour stocker les résultats
$results = @()

foreach ($pc in $computers) {
    $hostname = $pc.Nom_PC
    Write-Host "Ajout de la règle WinRM sur $hostname ..."
    try {
        $result = Invoke-WmiMethod -ComputerName $hostname -Class Win32_Process -Name Create -ArgumentList $fwRuleCmd -ErrorAction Stop
        if ($result.ProcessId) {
            $status = "Succès (PID $($result.ProcessId))"
        } else {
            $status = "Commande envoyée, pas de PID"
        }
    } catch {
        $status = "Échec : $($_.Exception.Message)"
    }

    # Ajouter le résultat à la liste
    $results += [PSCustomObject]@{
        Nom_PC = $hostname
        Statut = $status
        Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Exporter les résultats dans un fichier CSV
$results | Export-Csv -Path "C:\Temp\Tranche1_resultats_winrm.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Export terminé : C:\Temp\Tranche1_resultats_winrm.csv"
