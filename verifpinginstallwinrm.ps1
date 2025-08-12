# Lire les noms de postes depuis un fichier CSV
$computers = Import-Csv -Path "C:\Temp\liste_postes.csv"

# Commande à exécuter sur chaque poste
$fwRuleCmd = 'netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985'

# Liste pour stocker les résultats
$results = @()

foreach ($pc in $computers) {
    $hostname = $pc.Nom_PC

    if ([string]::IsNullOrWhiteSpace($hostname)) {
        $results += [PSCustomObject]@{
            Nom_PC = "<Ligne vide ou invalide>"
            Ping   = "Non testé"
            Statut = "Erreur : Nom de poste vide"
            Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        continue
    }

    Write-Host "Test de connexion (ping) vers $hostname ..."
    $pingOK = Test-Connection -ComputerName $hostname -Count 1 -Quiet -ErrorAction SilentlyContinue

    if ($pingOK) {
        Write-Host "Ping OK. Ajout de la règle WinRM ..."
        try {
            $result = Invoke-WmiMethod -ComputerName $hostname -Class Win32_Process -Name Create -ArgumentList $fwRuleCmd -ErrorAction Stop
            if ($result.ProcessId) {
                $status = "Succès (PID $($result.ProcessId))"
            } else {
                $status = "Commande envoyée, pas de PID"
            }
        } catch {
            $status = "Échec WinRM : $($_.Exception.Message)"
        }
    } else {
        $status = "Échec : Ping non répondu"
    }

    $results += [PSCustomObject]@{
        Nom_PC = $hostname
        Ping   = if ($pingOK) { "OK" } else { "Échec" }
        Statut = $status
        Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Exporter les résultats dans un fichier CSV
$results | Export-Csv -Path "C:\Temp\resultats_winrm_ping.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Export terminé : C:\Temp\resultats_winrm_ping.csv"
