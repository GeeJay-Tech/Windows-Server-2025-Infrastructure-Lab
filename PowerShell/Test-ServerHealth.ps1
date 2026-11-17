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

# Disk Space Monitoring
# Checks fixed disks on DC01 and FS01

$Servers = @("DC01", "FS01")

$DiskReport = foreach ($Server in $Servers) {

    try {
        $Disks = Get-WmiObject -Class Win32_LogicalDisk `
            -ComputerName $Server `
            -Filter "DriveType=3" `
            -ErrorAction Stop

        foreach ($Disk in $Disks) {

            if ($Disk.Size -le 0) {
                continue
            }

            $UsedPercent = [math]::Round(
                (($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100, 2
            )

            if ($UsedPercent -ge 90) {
                $Status = "Critical"
            }
            elseif ($UsedPercent -ge 80) {
                $Status = "Warning"
            }
            else {
                $Status = "Healthy"
            }

            [PSCustomObject]@{
                Server      = $Server
                Drive       = $Disk.DeviceID
                TotalGB     = [math]::Round($Disk.Size / 1GB, 2)
                FreeGB      = [math]::Round($Disk.FreeSpace / 1GB, 2)
                UsedPercent = $UsedPercent
                Status      = $Status
            }
        }
    }
    catch {
        Write-Warning "Disk check failed for ${Server}: $($_.Exception.Message)"
    }
}

# Display disk results
$DiskReport | Sort-Object Server, Drive | Format-Table -AutoSize

# Export disk report to CSV
$DiskReportPath = "$env:USERPROFILE\Desktop\Infrastructure-DiskReport.csv"

$DiskReport | Export-Csv -Path $DiskReportPath -NoTypeInformation

Write-Host "Disk report exported to $DiskReportPath"
