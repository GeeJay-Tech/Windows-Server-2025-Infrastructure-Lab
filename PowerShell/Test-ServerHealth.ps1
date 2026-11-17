# Infrastructure Health Monitoring
# Checks critical services on DC01 and FS01

$ServerServices = @{
    "DC01" = @("LanmanServer", "WinRM", "DNS")
    "FS01" = @("LanmanServer", "WinRM")
}

$HealthReport = foreach ($Server in $ServerServices.Keys) {
    foreach ($ServiceName in $ServerServices[$Server]) {
        try {
            $Service = Get-Service -ComputerName $Server -Name $ServiceName -ErrorAction Stop

            [PSCustomObject]@{
                Server  = $Server
                Service = $ServiceName
                Status  = $Service.Status
            }
        }
        catch {
            [PSCustomObject]@{
                Server  = $Server
                Service = $ServiceName
                Status  = "Check Failed"
            }
        }
    }
}

# Display the results
$HealthReport | Sort-Object Server, Service | Format-Table -AutoSize

# Export the results to CSV
$ReportPath = "$env:USERPROFILE\Desktop\Infrastructure-HealthReport.csv"

$HealthReport | Export-Csv -Path $ReportPath -NoTypeInformation

Write-Host "Health report exported to $ReportPath"
