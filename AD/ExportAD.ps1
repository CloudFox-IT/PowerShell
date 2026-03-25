# Récupérer tous les ordinateurs de l'AD
$allComputers = Get-ADComputer -Filter * -Property Name, OperatingSystem, LastLogonDate

# Sélectionner les infos utiles
$allComputers | Select-Object Name, OperatingSystem, LastLogonDate |
    Export-Csv -Path "C:\Temp\Liste_Computers_AD.csv" -NoTypeInformation -Encoding UTF8

Write-Output "Export terminé : C:\Temp\Liste_Computers_AD-090725.csv"
