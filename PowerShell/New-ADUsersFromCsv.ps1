<#
.SYNOPSIS
    Creates Active Directory lab users from a CSV and adds them to departmental groups.
.DESCRIPTION
    Designed for the CTRL-TECH.net Windows Server 2025 training lab.
    CSV columns: FirstName, LastName, Username, Department, Group.
    Prompts separately for each user's temporary password.
    Creates accounts disabled first and enables them only after password
    configuration and group assignment succeed.

    IMPORTANT: If a step fails, a disabled, partially configured account
    may remain. Resolve failures manually before retrying; existing
    usernames are deliberately skipped.
.EXAMPLE
    .\New-ADUsersFromCsv.ps1 -CsvPath "C:\Users\Administrator\Desktop\NewEmployees.csv"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$OU = 'OU=Users,OU=CTRLTECH,DC=ctrl-tech,DC=net'
$Employees = Import-Csv -LiteralPath $CsvPath -ErrorAction Stop

foreach ($Employee in $Employees) {
    $Username = $Employee.Username
    $FullName = "$($Employee.FirstName) $($Employee.LastName)"

    try {
        # Avoid duplicates before making any changes.
        $Existing = Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction Stop

        if ($Existing) {
            Write-Host "$FullName already exists - skipped."
            continue
        }

        $Password = Read-Host "Enter temporary password for $FullName" -AsSecureString

        New-ADUser `
            -Name $FullName `
            -GivenName $Employee.FirstName `
            -Surname $Employee.LastName `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@ctrl-tech.net" `
            -Department $Employee.Department `
            -Path $OU `
            -Enabled $false `
            -ErrorAction Stop

        Set-ADAccountPassword `
            -Identity $Username `
            -Reset `
            -NewPassword $Password `
            -ErrorAction Stop

        Set-ADUser `
            -Identity $Username `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Add-ADGroupMember `
            -Identity $Employee.Group `
            -Members $Username `
            -ErrorAction Stop

        Enable-ADAccount -Identity $Username -ErrorAction Stop

        Write-Host "$FullName - onboarding completed successfully."
    }
    catch {
        Write-Warning "$FullName - onboarding failed: $($_.Exception.Message)"
    }
}
