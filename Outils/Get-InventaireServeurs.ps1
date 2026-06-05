###############################################################
# Nom        : Get-InventaireServeurs.ps1
# Description: Inventaire des serveurs Eurazeo – statut en
#              ligne, OS (Windows/Linux), export CSV + HTML
# Auteur     : Sylvain Mirlaud (smadmin) 
# Mission    : Eurazeo DSI – Paris
# Version    : 1.0
# Date       : 2026-06-04
###############################################################

$ExportPath  = "C:\Temp\Inventaire_Serveurs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$ExportHTML  = "C:\Temp\Inventaire_Serveurs_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

# --- Liste des serveurs (dédoublonnée) ---
$Serveurs = @(
    "nom de serveur" ou import cvs 
)

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   INVENTAIRE SERVEURS - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan
Write-Host "   $($Serveurs.Count) serveurs à interroger" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# --- Fonction inventaire ---
function Get-InfoServeur {
    param([string]$Nom)

    $Resultat = [PSCustomObject]@{
        NomServeur   = $Nom.ToUpper()
        Statut       = ""
        TypeOS       = ""
        OS           = ""
        IP           = ""
        RAM_Go       = ""
        CPU          = ""
        NombreCoeurs = ""
        Uptime_Jours = ""
        DerniereMAJ  = ""
        CollecteDate = (Get-Date -Format "dd/MM/yyyy HH:mm")
    }

    # Ping
    $Ping = Test-Connection -ComputerName $Nom -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $Ping) {
        $Resultat.Statut = "HORS LIGNE"
        Write-Host "  [-] $Nom" -ForegroundColor Red
        return $Resultat
    }

    $Resultat.Statut = "EN LIGNE"

    # Tentative WMI/CIM → Windows
    try {
        $OS   = Get-CimInstance Win32_OperatingSystem  -ComputerName $Nom -ErrorAction Stop
        $CS   = Get-CimInstance Win32_ComputerSystem   -ComputerName $Nom -ErrorAction Stop
        $Proc = Get-CimInstance Win32_Processor        -ComputerName $Nom -ErrorAction Stop | Select-Object -First 1

        $Resultat.TypeOS       = "Windows"
        $Resultat.OS           = $OS.Caption
        $Resultat.IP           = ([System.Net.Dns]::GetHostAddresses($Nom) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | Select-Object -First 1).IPAddressToString
        $Resultat.RAM_Go       = [math]::Round($CS.TotalPhysicalMemory / 1GB, 0)
        $Resultat.CPU          = $Proc.Name.Trim()
        $Resultat.NombreCoeurs = ($Proc | Measure-Object NumberOfCores -Sum).Sum
        $Resultat.Uptime_Jours = [math]::Round(((Get-Date) - $OS.LastBootUpTime).TotalDays, 1)

        $HotFix = Get-CimInstance Win32_QuickFixEngineering -ComputerName $Nom -ErrorAction SilentlyContinue |
            Sort-Object InstalledOn -Descending | Select-Object -First 1
        $Resultat.DerniereMAJ = if ($HotFix.InstalledOn) { $HotFix.InstalledOn.ToString("dd/MM/yyyy") } else { "Inconnue" }

        Write-Host "  [W] $Nom — $($Resultat.OS)" -ForegroundColor Green

    } catch {
        # WMI échoue → probablement Linux ou firewall
        $Resultat.TypeOS = "Linux/Inconnu"
        $Resultat.IP     = try { ([System.Net.Dns]::GetHostAddresses($Nom) | Where-Object { $_.AddressFamily -eq "InterNetwork" } | Select-Object -First 1).IPAddressToString } catch { "N/A" }
        $Resultat.OS     = "Non accessible via WMI (Linux ?)"
        Write-Host "  [L] $Nom — Linux ou WMI bloqué" -ForegroundColor Yellow
    }

    return $Resultat
}

# --- Boucle ---
$Resultats = foreach ($srv in $Serveurs) {
    Get-InfoServeur -Nom $srv
}

# --- Stats ---
$Total   = $Resultats.Count
$ON      = ($Resultats | Where-Object { $_.Statut -eq "EN LIGNE" }).Count
$OFF     = ($Resultats | Where-Object { $_.Statut -eq "HORS LIGNE" }).Count
$Windows = ($Resultats | Where-Object { $_.TypeOS -eq "Windows" }).Count
$Linux   = ($Resultats | Where-Object { $_.TypeOS -eq "Linux/Inconnu" }).Count

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Total      : $Total"
Write-Host "  En ligne   : $ON"      -ForegroundColor Green
Write-Host "  Hors ligne : $OFF"     -ForegroundColor Red
Write-Host "  Windows    : $Windows" -ForegroundColor Blue
Write-Host "  Linux/Autre: $Linux"   -ForegroundColor Yellow
Write-Host "============================================================`n" -ForegroundColor Cyan

# --- Export CSV ---
$Resultats | Sort-Object Statut, NomServeur |
    Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "[+] CSV exporté : $ExportPath" -ForegroundColor Green

# --- Export HTML ---
$Lignes = foreach ($r in $Resultats | Sort-Object Statut, NomServeur) {
    $couleur = switch ($r.Statut) {
        "EN LIGNE"   { if ($r.TypeOS -eq "Windows") { "#d4edda" } else { "#fff3cd" } }
        "HORS LIGNE" { "#f8d7da" }
        default      { "#ffffff" }
    }
    "<tr style='background:$couleur'>
        <td><b>$($r.NomServeur)</b></td>
        <td>$($r.Statut)</td>
        <td>$($r.TypeOS)</td>
        <td>$($r.OS)</td>
        <td>$($r.IP)</td>
        <td>$($r.RAM_Go)</td>
        <td>$($r.CPU)</td>
        <td>$($r.NombreCoeurs)</td>
        <td>$($r.Uptime_Jours)</td>
        <td>$($r.DerniereMAJ)</td>
        <td>$($r.CollecteDate)</td>
    </tr>"
}

$HTML = @"
<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8">
<title>Inventaire Serveurs</title>
<style>
  body { font-family: Segoe UI, Arial, sans-serif; margin:20px; background:#f4f6f9; }
  h1   { color:#2c3e50; }
  .cards { display:flex; gap:15px; margin-bottom:20px; }
  .card  { padding:12px 22px; border-radius:8px; color:#fff; font-size:1.1em; font-weight:bold; }
  .total { background:#3498db; } .ok { background:#27ae60; }
  .down  { background:#e74c3c; } .win { background:#2980b9; } .lnx { background:#f39c12; }
  table  { border-collapse:collapse; width:100%; background:#fff; border-radius:8px; box-shadow:0 2px 8px #0001; }
  th { background:#2c3e50; color:#fff; padding:9px 7px; text-align:left; font-size:.83em; }
  td { padding:7px; font-size:.82em; border-bottom:1px solid #eee; }
  tr:hover td { filter:brightness(0.95); }
</style></head><body>
<h1>Inventaire Serveurs Eurazeo</h1>
<p>Généré le <b>$(Get-Date -Format 'dd/MM/yyyy à HH:mm')</b></p>
<div class="cards">
  <div class="card total">Total : $Total</div>
  <div class="card ok">En ligne : $ON</div>
  <div class="card down">Hors ligne : $OFF</div>
  <div class="card win">Windows : $Windows</div>
  <div class="card lnx">Linux/Autre : $Linux</div>
</div>
<table><thead><tr>
  <th>Serveur</th><th>Statut</th><th>Type OS</th><th>OS</th><th>IP</th>
  <th>RAM (Go)</th><th>CPU</th><th>Cœurs</th><th>Uptime (j)</th>
  <th>Dernière MAJ</th><th>Date collecte</th>
</tr></thead><tbody>
$($Lignes -join "`n")
</tbody></table></body></html>
"@

$HTML | Out-File -FilePath $ExportHTML -Encoding UTF8
Write-Host "[+] HTML exporté : $ExportHTML" -ForegroundColor Green