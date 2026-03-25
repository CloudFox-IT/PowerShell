# Lire les noms de postes depuis un fichier CSV
$computers = Import-Csv -Path "C:\Temp\forwinrm200625.txt"

# Liste pour stocker les résultats
$verifResults = @()

foreach ($pc in $computers) {
    $hostname = $pc.Nom_PC

    if ([string]::IsNullOrWhiteSpace($hostname)) {
        $verifResults += [PSCustomObject]@{
            Nom_PC = "<Ligne vide ou invalide>"
            WinRM  = "Non testé"
            Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        continue
    }

    Write-Host "Vérification WinRM sur $hostname ..."
    try {
        $winrmOK = Test-WSMan -ComputerName $hostname -ErrorAction Stop
        $status = "WinRM OK"
    } catch {
        $status = "WinRM NON DISPONIBLE : $($_.Exception.Message)"
    }

    $verifResults += [PSCustomObject]@{
        Nom_PC = $hostname
        WinRM  = $status
        Date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Exporter les résultats dans un fichier CSV
$verifResults | Export-Csv -Path "C:\Temp\verif_winrm2.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Vérification WinRM terminée : C:\Temp\verif_winrm2.csv"
