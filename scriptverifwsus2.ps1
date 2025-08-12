# === CONFIGURATION ===
$InputFile = "C:\Temp\listepcko270625ko.txt"     # Ou .csv selon ton cas
$OutputFile = "C:\Temp\listepcko270625ko1.csv"

# === Préparation ===
$Results = @()

# === Charger la liste de machines ===
$Machines = Get-Content $InputFile

# === Boucle sur chaque machine ===
foreach ($Machine in $Machines) {
    Write-Host "`n--- $Machine ---" -ForegroundColor Cyan
    $Status = [PSCustomObject]@{
        Machine        = $Machine
        Ping           = "NOK"
        WSUS_Config    = "Inaccessible"
        WU_Service     = "Inconnu"
        Detect_Status  = "Non lancé"
        Last_Error     = ""
    }

    # Vérifie la connectivité
    if (Test-Connection -ComputerName $Machine -Count 1 -Quiet) {
        $Status.Ping = "OK"

        try {
            # Lire le registre distant pour WSUS config
            $WUReg = Invoke-Command -ComputerName $Machine -ScriptBlock {
                Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
            }

            $Status.WSUS_Config = $WUReg.WUServer

            # Vérifie le service Windows Update
            $Service = Invoke-Command -ComputerName $Machine -ScriptBlock {
                Get-Service -Name wuauserv
            }
            $Status.WU_Service = $Service.Status

            # Lancer la détection des mises à jour
            Invoke-Command -ComputerName $Machine -ScriptBlock {
                wuauclt.exe /detectnow
                wuauclt.exe /reportnow
            }

            $Status.Detect_Status = "Déclenché"

        } catch {
            $Status.Last_Error = $_.Exception.Message
        }
    } else {
        $Status.Last_Error = "Ping KO"
    }

    # Ajouter aux résultats
    $Results += $Status
}

# === Export CSV final ===
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "`nAudit terminé. Rapport exporté vers $OutputFile" -ForegroundColor Green
