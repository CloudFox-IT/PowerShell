
# ==============================================================================
#  Export-GroupComputers - PowerShell
#  Auteur  : Sylvain Mirlaud
#  Version : 1.0
#  Description : Extraction des postes d'un groupe
#  Format CSV : une colonne "ComputerName" 
#  Extrait les noms des ordinateurs d'un groupe AD -> CSV
# ============================================================

param (
    [string]$GroupName  = "GS - T - Win-Devices",
    [string]$ExportPath = "C:\temp\computers_GS-T-Win-Devices.csv"
)

# Si pas de paramètre, demander interactivement
if (-not $GroupName) {
    $GroupName = Read-Host "GS - T - Win-Devices"
}

Write-Host ""
Write-Host "Extraction des membres du groupe : $GroupName" -ForegroundColor Cyan

try {
    # Récupérer tous les membres (y compris sous-groupes imbriqués)
    $members = Get-ADGroupMember -Identity $GroupName -Recursive `
               | Where-Object { $_.objectClass -eq "computer" } `
               | Select-Object -ExpandProperty Name `
               | Sort-Object

    if ($members.Count -eq 0) {
        Write-Host "Aucun ordinateur trouvé dans ce groupe." -ForegroundColor Yellow
        exit
    }

    # Afficher dans la console
    Write-Host ""
    Write-Host "  Ordinateurs trouvés : $($members.Count)" -ForegroundColor Green
    $members | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

    # Exporter en CSV
    $members | ForEach-Object { [PSCustomObject]@{ ComputerName = $_ } } `
             | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host "Export terminé : $ExportPath" -ForegroundColor Green
}
catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
}