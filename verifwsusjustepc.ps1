$server = "xxxx"
Invoke-Command -ComputerName $server -ScriptBlock {
    try {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Stop
        if ($reg.WUServer) {
            "OK : $($reg.WUServer)"
        } else {
            "Clé présente, mais WUServer non renseigné"
        }
    } catch {
        "KO : Clé absente"
    }
}
