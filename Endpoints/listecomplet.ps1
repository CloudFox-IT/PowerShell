Get-Content "C:\Temp\pcaucunetat.txt" | ForEach-Object {
    $_.Split("`t")[0]
} | Set-Content "C:\Temp\\ListeNomsPCkowsus.txt"
