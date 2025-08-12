# Liste des postes à cibler
$PCList = @("xxxx")

foreach ($PC in $PCList) {
    Write-Host "------ $PC ------" -ForegroundColor Cyan

    # Test WinRM
    $winrm = Test-WSMan -ComputerName $PC -ErrorAction SilentlyContinue

    if ($winrm) {
        Write-Host "WinRM est actif sur $PC." -ForegroundColor Green

        try {
            Invoke-Command -ComputerName $PC -ScriptBlock {
                Write-Host "1. gpupdate /force"
                gpupdate /force

                Write-Host "2. klist purge"
                klist purge

                Write-Host "3. Recherche et installation des mises à jour Windows"
                # Recherche des mises à jour
                wuauclt /detectnow
                # Installation des mises à jour (commande silencieuse, ne force pas le redémarrage)
                wuauclt /updatenow
            }
            Write-Host "Commandes exécutées sur $PC." -ForegroundColor Green
        } catch {
            Write-Host "Erreur lors de l'exécution distante sur $PC : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "WinRM n'est PAS actif sur $PC. Tentative d'activation..." -ForegroundColor Yellow

        try {
            Invoke-WmiMethod -ComputerName $PC -Class Win32_Process -Name Create -ArgumentList "winrm quickconfig -force"
            Write-Host "Commande winrm quickconfig lancée sur $PC." -ForegroundColor Green
        } catch {
            Write-Host "Impossible d'activer WinRM sur $PC : $_" -ForegroundColor Red
        }
    }
}
