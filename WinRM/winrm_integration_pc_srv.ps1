# Liste des noms de postes
$computers = @(
    "xxxx",
    "xxxx",
    "xxx",
    "xxxx",
    "xxxx",
    "xxxx",
    "xxxxx",
    "xxx",
    "xxx",
    "xxx",
    "xxxx",
    "xxxx",
    "xxxxx",
    "xxxx",
    "xxx"
    )

# Commande à exécuter sur chaque poste
$fwRuleCmd = 'netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985'

foreach ($hostname in $computers) {
    Write-Host "Ajout de la règle WinRM sur $hostname ..."
    try {
        $result = Invoke-WmiMethod -ComputerName $hostname -Class Win32_Process -Name Create -ArgumentList $fwRuleCmd
        if ($result.ProcessId) {
            Write-Host "Succès sur $hostname (PID $($result.ProcessId))" -ForegroundColor Green
        } else {
            Write-Warning "Commande envoyée, mais pas de retour de PID sur $hostname"
        }
    } catch {
        Write-Warning "Échec sur $hostname : $_"
    }
}
