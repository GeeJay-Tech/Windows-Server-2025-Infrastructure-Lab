# Active Directory, DNS and DHCP

## Domain and infrastructure services

On a fresh DC01, the core role installation and forest creation can be expressed as:

```powershell
Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

Install-ADDSForest -DomainName 'CTRL-TECH.net' -InstallDns
```

Forest creation prompts for the Directory Services Restore Mode password and requires a restart. DHCP authorisation, scope creation and scope options are separate configuration steps. The lab uses `.1` as the router and `.2` as the DNS server; the DHCP pool must exclude infrastructure addresses.

Inspect the configured services and directory structure on DC01:

```powershell
Get-ADDomain

Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName

Get-ADUser -Filter * |
    Select-Object Name, Enabled

Get-ADGroup -Filter * |
    Select-Object Name, GroupScope, GroupCategory

Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue
Get-ADDefaultDomainPasswordPolicy
```

## Departmental user onboarding with PowerShell (30 October 2026)

Expanded the existing lab's user accounts while preserving the existing Users OU and departmental security groups.

**Existing accounts:** Sarah Mitchell (Finance), James Wilson (IT). **New accounts:** Daniel Brooks and Emily Carter (Finance); Olivia Bennett and Marcus Reed (IT).

| Employee | SamAccountName | Department | Group outcome |
| --- | --- | --- | --- |
| Sarah Mitchell | Existing | Finance | Existing `SG-Finance-Staff` member; unchanged |
| James Wilson | Existing | IT | Existing account; unchanged |
| Daniel Brooks | `dbrooks` | Finance | Added to `SG-Finance-Staff` |
| Emily Carter | `ecarter` | Finance | Initially omitted from `SG-Finance-Staff` for a controlled access scenario; added after investigation |
| Olivia Bennett | `obennett` | IT | Added to `SG-IT-Staff` |
| Marcus Reed | `mreed` | IT | Added to `SG-IT-Staff` |

All new users were targeted to `OU=Users,OU=CTRLTECH,DC=ctrl-tech,DC=net`; departmental access is managed through security groups in the existing Groups OU. No new departmental OUs were required.

### Creating three accounts in one interactive PowerShell session

A PowerShell array and `foreach` loop were used to create Emily, Olivia and Marcus without repeating the onboarding procedure for each person:

```powershell
Import-Module ActiveDirectory -ErrorAction Stop

$Users = @(
    @{ FirstName = "Emily"; LastName = "Carter"; Username = "ecarter"; Department = "Finance"; Group = $null }
    @{ FirstName = "Olivia"; LastName = "Bennett"; Username = "obennett"; Department = "IT"; Group = "SG-IT-Staff" }
    @{ FirstName = "Marcus"; LastName = "Reed"; Username = "mreed"; Department = "IT"; Group = "SG-IT-Staff" }
)

$OU = "OU=Users,OU=CTRLTECH,DC=ctrl-tech,DC=net"
$Password = Read-Host "Enter a temporary password for the new employees" -AsSecureString

foreach ($User in $Users) {
    $FullName = "$($User.FirstName) $($User.LastName)"
    $Username = $User.Username

    try {
        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction Stop
        if ($ExistingUser) {
            Write-Host "$FullName already exists - skipped."
            continue
        }

        New-ADUser `
            -Name $FullName `
            -GivenName $User.FirstName `
            -Surname $User.LastName `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@ctrl-tech.net" `
            -Department $User.Department `
            -Path $OU `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        if ($User.Group) {
            Add-ADGroupMember -Identity $User.Group -Members $Username -ErrorAction Stop
        }

        Write-Host "$FullName - onboarding completed."
    }
    catch {
        Write-Warning "$FullName - onboarding failed: $($_.Exception.Message)"
    }
}
```

**Observed outcome:** All three new employees reported `onboarding completed`. The script was executed interactively on DC01; it was **not** saved or published as a tested `.ps1` file during this session. The training deliberately kept Emily out of the Finance group until the simulated access investigation.

**Security and reliability notes:** These test accounts initially used the same temporary password and were configured to change it at sign-in; use unique secure credentials or an approved onboarding process in production. The example skips existing usernames but does not repair partially created accounts or roll back a successful user creation if group assignment fails.

## CSV-driven onboarding — PowerShell Session 3 (3 November 2026)

Created `NewEmployees.csv` on DC01 with two additional lab employees:

| Employee | Username | Department | Group |
| --- | --- | --- | --- |
| Charlotte Evans | `cevans` | Finance | `SG-Finance-Staff` |
| Thomas Hughes | `thughes` | IT | `SG-IT-Staff` |

Imported the file using `Import-Csv` and used the employee records as input to a `foreach` loop. An interactive onboarding routine on DC01 completed successfully for both accounts. Each new employee was prompted for an individual temporary password; the process created the account disabled, configured a password, required password change at first logon, assigned the departmental group and enabled the account.

The reusable version is saved in [`PowerShell/New-ADUsersFromCsv.ps1`](../PowerShell/New-ADUsersFromCsv.ps1). It expects a CSV with the columns `FirstName,LastName,Username,Department,Group` and accepts a `-CsvPath` parameter:

```powershell
.\New-ADUsersFromCsv.ps1 -CsvPath "$env:USERPROFILE\Desktop\NewEmployees.csv"
```

**Validation status:** The *interactive onboarding commands* were run successfully for Charlotte and Thomas. The newly committed standalone `.ps1` file has not yet been executed and independently validated on DC01. It skips existing usernames, but does not automatically repair a partially created account following an error. Avoid storing passwords in the CSV and use controlled onboarding procedures in production.
