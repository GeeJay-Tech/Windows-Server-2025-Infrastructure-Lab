function Test-ServerHealth {
    param(
        [string]$Server
    )

    if (Test-Connection -ComputerName $Server -Count 2 -Quiet) {
        Write-Host "$Server is reachable"

        $Service = Get-Service -ComputerName $Server -Name LanmanServer

        if ($Service.Status -eq 'Running') {
            Write-Host "$Server Server service is running"
        }
        else {
            Write-Host "$Server Server service is NOT running"
        }
    }
    else {
        Write-Host "$Server is NOT reachable via ICMP"
    }
}

Test-ServerHealth -Server FS01
Test-ServerHealth -Server DC01
