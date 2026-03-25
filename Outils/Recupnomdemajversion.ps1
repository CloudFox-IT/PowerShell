# --- PARAMÉTRAGE ---
$ImportPath = "C:\Temp\listeadall.txt"   # Un nom de PC par ligne
$ExportPath = "C:\Temp\listeadall-0972025.csv.csv"

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

            # --- Statut Green si Win10 22H2 19045 ---
            if ($caption -like "*Windows 10*" -and $version -like "10.0.19045*" -and $os.BuildBranch -eq "22h2") {
                $statut = "Green"
            } else {
                $statut = "Pas à jour"
            }

            # --- Dernière MAJ KB et date ---
            $hotfixes = Get-HotFix -ComputerName $ComputerName -Credential $cred
            $validHotfixes = $hotfixes | Where-Object {
                $_.InstalledOn -and ($_.InstalledOn -match '^\d{2}/\d{2}/\d{4}$' -or $_.InstalledOn -match '^\d{4}-\d{2}-\d{2}$')
            }
            if ($validHotfixes) {
                $lastHotfix = $validHotfixes |
                    Select-Object -Property HotFixID, InstalledOn |
                    Sort-Object {[datetime]$_.InstalledOn} -Descending |
                    Select-Object -First 1
                $lastUpdateDate = $lastHotfix.InstalledOn
                $lastUpdateKB = $lastHotfix.HotFixID
            } else {
                $lastUpdateDate = "Aucune"
                $lastUpdateKB = "Aucune"
            }

            # --- Dernier utilisateur connecté ---
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
            try {
                $lastUser = Invoke-Command -ComputerName $ComputerName -Credential $cred -ScriptBlock {
                    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
                    if (Test-Path $path) {
                        (Get-ItemProperty -Path $path).LastLoggedOnUser
                    } else {
                        "Inconnu"
                    }
                }
                if ($lastUser -and $lastUser -match '\\') {
                    $lastUser = $lastUser.Split('\')[-1]
                }
            } catch {
                $lastUser = "Erreur"
            }

            # --- Date/heure dernière connexion ---
            try {
                $lastLogonDate = Invoke-Command -ComputerName $ComputerName -Credential $cred -ScriptBlock {
                    $evt = Get-WinEvent -LogName Security -MaxEvents 100 |
                        Where-Object { $_.Id -eq 4624 -and $_.Properties[5].Value -ne "ANONYMOUS LOGON" } |
                        Select-Object -First 1
                    if ($evt) { $evt.TimeCreated } else { "Inconnu" }
                }
            } catch {
                $lastLogonDate = "Erreur"
            }

            $Results += [PSCustomObject]@{
                "PC" = $ComputerName
                "IP" = $ip
                "OS" = $caption
                "Version complète" = $version
                "Build" = $buildNumber
                "Statut" = $statut
                "Dernier utilisateur" = $lastUser
                "Dernière connexion" = $lastLogonDate
                "Dernière MAJ KB" = $lastUpdateKB
                "Date dernière MAJ" = $lastUpdateDate
                "Méthode" = "WMI"
            }
        }
        catch {
            Write-Host "[$ComputerName] Erreur WMI : $_" -ForegroundColor Red
            $Results += [PSCustomObject]@{
                "PC" = $ComputerName
                "IP" = "Erreur"
                "OS" = "Inconnu"
                "Version complète" = "?"
                "Build" = "?"
                "Statut" = "?"
                "Dernier utilisateur" = "?"
                "Dernière connexion" = "?"
                "Dernière MAJ KB" = "?"
                "Date dernière MAJ" = "?"
                "Méthode" = "Erreur WMI"
            }
        }
   
