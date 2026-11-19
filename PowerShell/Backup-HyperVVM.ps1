param(
    [string]$VMName = "FS01",
    [string]$BackupRoot = "D:\Hyper-V-Backups"
)

$ErrorActionPreference = "Stop"

# Generate backup timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$Destination = Join-Path $BackupRoot $Timestamp

# CSV log location
$LogFolder = "C:\Scripts\Logs"
$LogFile = Join-Path $LogFolder "HyperV-BackupLog.csv"

# Default result
$Status = "Failed"
$ErrorDetails = ""

try {
    # Check the VM exists
    $VM = Get-VM -Name $VMName

    # Safety check
    if ($VM.State -ne "Off") {
        throw "VM must be shut down before this backup."
    }

    # Create destination folder
    New-Item -Path $Destination `
        -ItemType Directory -ErrorAction Stop | Out-Null

    # Export virtual machine
    Export-VM -Name $VMName `
        -Path $Destination -ErrorAction Stop

    # Verify exported files
    $Files = Get-ChildItem $Destination -Recurse -File

    if (-not ($Files.Extension -contains ".vhdx") -or
        -not ($Files.Extension -contains ".vmcx")) {
        throw "Export files are incomplete."
    }

    $Status = "Success"

    Write-Host "Backup completed successfully."
}
catch {
    $ErrorDetails = $_.Exception.Message

    Write-Warning "Backup failed: $ErrorDetails"
}
finally {
    # Ensure logging folder exists
    New-Item -Path $LogFolder `
        -ItemType Directory -Force | Out-Null

    # Build the CSV record
    $LogEntry = [PSCustomObject]@{
        Date        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        VMName      = $VMName
        Status      = $Status
        Destination = $Destination
        Error       = $ErrorDetails
    }

    # Append the result to the CSV
    $LogEntry | Export-Csv `
        -Path $LogFile `
        -NoTypeInformation `
        -Append

    Write-Host "Backup result recorded in $LogFile"
}
