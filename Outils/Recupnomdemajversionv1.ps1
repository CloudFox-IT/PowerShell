# --- PARAMÉTRAGE ---
$ImportPath = "C:\Temp\listeadall.txt"   # Un nom de PC par ligne
$ExportPath = "C:\Temp\listeadall-9072025.csv"

# --- IMPORT DE LA LISTE ---
$PCList = Get-Content $ImportPath

# --- INITIALISATION DES RÉSULTATS ---
$Results = @()

# --- DEMANDE DES CREDENTIALS ---
$cred = Get-Credential

foreach ($ComputerName in $PCList) {
    Write-Host "`n[$ComputerName] Test de ping..." -ForegroundColor Green
    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        Write-Host "[$ComputerName] Répond au ping. Récupération WMI..." -ForegroundColor Green
        try {
            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $cred -ErrorAction Stop
            $ip = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -Credential $cred | Where-Object { $_.IPEnabled }).IPAddress[0]
            $caption = $os.Caption
            $version = $os.Version
            $buildNumber = $os.BuildNumber

            # --- Dernière MAJ KB ---
            $hotfixes = Get-HotFix -ComputerName $ComputerName -Credential $cred
            if ($hotfixes) {
                $lastHotfix = $hotfixes | Sort-Object {[datetime]$_.InstalledOn} -Descending | Select-Object -First 1
                $lastUpdateKB = $lastHotfix.HotFixID
            } else {
                $lastUpdateKB = "Aucune"
            }

            $Results += [PSCustomObject]@{
                "PC"                 = $ComputerName
                "IP"                 = $ip
                "OS"                 = $caption
                "Version complète"   = $version
                "Build"              = $buildNumber
                "Dernière MAJ KB"    = $lastUpdateKB
                "Méthode"            = "WMI"
            }
        }
        catch {
            Write-Host "[$ComputerName] Erreur WMI : $_" -ForegroundColor Red
            $Results += [PSCustomObject]@{
                "PC"                 = $ComputerName
                "IP"                 = "Erreur"
                "OS"                 = "Inconnu"
                "Version complète"   = "?"
                "Build"              = "?"
                "Dernière MAJ KB"    = "?"
                "Méthode"            = "WMI"
            }
        }
    }
    else {
        Write-Host "[$ComputerName] Ne répond pas au ping." -ForegroundColor Red
        $Results += [PSCustomObject]@{
            "PC"                 = $ComputerName
            "IP"                 = "Injoignable"
            "OS"                 = "Inconnu"
            "Version complète"   = "?"
            "Build"              = "?"
            "Dernière MAJ KB"    = "?"
            "Méthode"            = "Injoignable"
        }
    }
}

# --- EXPORT EN CSV ---
$Results | Export-Csv -Path $ExportPath -NoTypeInformation -Delimiter "`t"
Write-Host "`nFichier CSV exporté ici : $ExportPath" -ForegroundColor Green
