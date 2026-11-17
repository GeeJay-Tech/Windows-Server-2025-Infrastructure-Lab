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

# ==========================================
# Windows Event Log Monitoring
# ==========================================

$Servers = @("DC01", "FS01")
$StartTime = (Get-Date).AddDays(-7)

$EventReport = foreach ($Server in $Servers) {

    try {
        $Events = Get-WinEvent -ComputerName $Server `
            -FilterHashtable @{
                LogName   = "System"
                Level     = 2, 3
                StartTime = $StartTime
            } `
            -MaxEvents 20 `
            -ErrorAction Stop

        foreach ($Event in $Events) {

            [PSCustomObject]@{
                Server    = $Server
                Time      = $Event.TimeCreated
                EventID   = $Event.Id
                Severity  = $Event.LevelDisplayName
                Source    = $Event.ProviderName
                Status    = "Retrieved"
            }
        }
    }
    catch {
        $Result = if ($_.FullyQualifiedErrorId -like "NoMatchingEventsFound*") {
            "No matching events"
        }
        else {
            "Query Failed: $($_.Exception.Message)"
        }

        [PSCustomObject]@{
            Server    = $Server
            Time      = $null
            EventID   = $null
            Severity  = $null
            Source    = $null
            Status    = $Result
        }
    }
}

# Display the results
Write-Host "`nWindows Event Log Report"

$EventReport |
    Sort-Object Server, Time -Descending |
    Format-Table -AutoSize

# Export the results
$EventReportPath = "$env:USERPROFILE\Desktop\Infrastructure-EventReport.csv"

$EventReport |
    Export-Csv -Path $EventReportPath -NoTypeInformation

Write-Host "Event report exported to $EventReportPath"
