$InputFile = "C:\Temp\pcs_missing_in_wsus.txt"
$OutputFile = "C:\Temp\rapport_wsus_winrm3.csv"
$Machines = Get-Content $InputFile
$Results = @()

foreach ($Machine in $Machines) {
    $Status = [PSCustomObject]@{
        Machine        = $Machine
        Ping           = "NOK"
        WinRM_Reachable= "NOK"
        WSUS_Config    = ""
        WU_Service     = ""
        Detect_Status  = ""
        Last_Error     = ""
    }

    if (Test-Connection -ComputerName $Machine -Count 1 -Quiet) {
        $Status.Ping = "OK"
        try {
            if (Test-WsMan -ComputerName $Machine -ErrorAction Stop) {
                $Status.WinRM_Reachable = "OK"
                try {
                    $WUReg = Invoke-Command -ComputerName $Machine -ScriptBlock {
                        Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
                    }
                    $Status.WSUS_Config = $WUReg.WUServer

                    $Service = Invoke-Command -ComputerName $Machine -ScriptBlock {
                        Get-Service -Name wuauserv
                    }
                    $Status.WU_Service = $Service.Status

                    Invoke-Command -ComputerName $Machine -ScriptBlock {
                        wuauclt.exe /detectnow
                        wuauclt.exe /reportnow
                    }
                    $Status.Detect_Status = "Déclenché"
                } catch {
                    $Status.Last_Error = $_.Exception.Message
                }
            }
        } catch {
            $Status.Last_Error = "WinRM inaccessible : " + $_.Exception.Message
        }
    } else {
        $Status.Last_Error = "Ping KO"
    }
    $Results += $Status
}

$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
