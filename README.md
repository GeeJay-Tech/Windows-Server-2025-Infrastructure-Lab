# Windows Server 2025 Infrastructure Lab

A hands-on infrastructure lab built in Hyper-V to practise Windows domain administration, network services, file access control and endpoint policy management. The environment connects Windows Server 2025 infrastructure with a domain-joined Windows 11 client on a private NAT network.

The project demonstrates practical skills relevant to IT support, systems administration and infrastructure engineering: managing Active Directory, troubleshooting DNS, configuring DHCP, assigning group-based access, applying Group Policy, investigating Windows Security events and developing PowerShell automation.

**Current status:** Core domain, networking, file services and policy exercises are implemented. The FS01 secure dynamic DNS registration issue has been resolved. The file-server auditing GPO application and winning-policy verification are complete. PowerShell Automation Session 1 is complete, including basic server connectivity checks, remote service checks and a reusable health-check script.

## At a glance

| Component | Configuration |
| --- | --- |
| Virtualisation | Hyper-V |
| Lab subnet | `192.168.100.0/24` |
| NAT gateway | `192.168.100.1` |
| AD domain | `CTRL-TECH.net` |
| DC01 | `192.168.100.2` — AD DS, DNS and DHCP |
| FS01 | `192.168.100.3` — domain member and file server |
| CLIENT01 | Windows 11 — domain member, DHCP addressing |

## Architecture

```text
                      External network
                             |
                        Hyper-V host
                             |
                   NAT gateway: 192.168.100.1
                             |
              Lab virtual network: 192.168.100.0/24
                             |
           +------------------+------------------+
           |                  |                  |
         DC01               FS01              CLIENT01
    192.168.100.2       192.168.100.3         DHCP address
    Windows Server     Windows Server        Windows 11
    2025               2025
    AD DS / DNS /      SMB file services     Domain sign-in
    DHCP                                   Mapped drives
           |                  |                  |
           +---------- CTRL-TECH.net ------------+
```

DC01 provides domain identity, internal name resolution and client address allocation. FS01 hosts shared folders, with access assigned through domain groups. CLIENT01 provides the user-facing test environment for domain sign-in, policy application and mapped drives.

## What I implemented

- Built a Hyper-V NAT lab using the `192.168.100.0/24` network and `.1` gateway.
- Established the `CTRL-TECH.net` Active Directory domain with AD DS and DNS on DC01.
- Configured DHCP on DC01 and used DHCP addressing for CLIENT01.
- Organised directory objects into OUs and created two test users with associated security groups.
- Configured SMB shares on FS01 and exercised group-based share and NTFS permissions.
- Configured workstation security through Group Policy and mapped network drives for domain users.
- Configured domain password and account lockout policy.
- Enabled local file-system auditing with `auditpol` and observed Security Event ID 4663.
- Resolved a file-server auditing GPO application issue by correcting FS01's Active Directory OU placement.
- Verified that `GPO-File-Server-Auditing` is the winning GPO for Audit File System on FS01 using Windows Group Policy Results.
- Diagnosed and resolved secure dynamic DNS registration failure on FS01, including investigation of Event ID 8018 and DNS record permissions.
- Developed PowerShell connectivity checks using `Test-Connection`.
- Used arrays, variables, `foreach` loops and conditional statements to automate server checks.
- Used PowerShell to inspect Windows services locally and remotely.
- Created a reusable `Test-ServerHealth` function to check server connectivity and the Windows Server service.
- Saved the health-check automation as a `.ps1` script for reuse and further development.

## Implementation notes and commands

Much of the lab was configured through Windows management consoles. The commands below are representative implementation and inspection examples for this topology; they are not a transcript or an unattended rebuild script. Switch names, interface aliases, share paths and policy values must match the actual lab.

### Hyper-V networking

On the Hyper-V host, the following illustrates creating an internal switch, assigning the gateway address and adding NAT. Use only when equivalent objects do not already exist.

```powershell
# Run in elevated PowerShell on the Hyper-V host.
# LabNAT is an example switch/NAT name.

New-VMSwitch -Name 'LabNAT' -SwitchType Internal

New-NetIPAddress -InterfaceAlias 'vEthernet (LabNAT)' `
    -IPAddress 192.168.100.1 -PrefixLength 24

New-NetNat -Name 'LabNAT' `
    -InternalIPInterfaceAddressPrefix '192.168.100.0/24'

Get-VMSwitch
Get-NetNat
```

Connect the three virtual machines to the lab switch. DC01 and FS01 use their static addresses; CLIENT01 obtains its configuration from DHCP. Domain members use DC01 for internal DNS resolution.

### Domain and infrastructure services

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

### Domain membership, file access and policy

Join FS01 and CLIENT01 after configuring their DNS client to use DC01:

```powershell
Add-Computer -DomainName 'CTRL-TECH.net' -Credential (Get-Credential) -Restart
```

The file access exercise combines SMB share permissions with NTFS permissions. Group membership supplies access to the intended folders, and client testing checks the resulting user experience. OU placement and policy scope matter when applying workstation settings and drive mappings.

```powershell
# FS01: inspect published shares and their access entries.

Get-SmbShare | Where-Object Special -eq $false

# Substitute an actual share name before running:
# Get-SmbShareAccess -Name '<share-name>'
# Get-Acl -Path '<shared-folder-path>' | Format-List

# CLIENT01: refresh policy and inspect the signed-in user's context.

gpupdate /force
gpresult /r
whoami /groups
Get-SmbMapping
```

Password and account lockout settings were configured at domain level. Their effective values can be inspected with `Get-ADDefaultDomainPasswordPolicy`; exact thresholds are not reproduced here without the original configuration evidence.

### File access auditing

Local auditing on FS01 was initially used to demonstrate file access events:

```powershell
# Elevated shell on FS01; subcategory name assumes an English installation.

auditpol /set /subcategory:"File System" /success:enable /failure:enable

auditpol /get /subcategory:"File System"

Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663} -MaxEvents 10 |
    Select-Object TimeCreated, Id, Message
```

File auditing also requires an applicable auditing entry in the target object's SACL. With that entry in place, a matching file access operation can produce Event ID 4663 on FS01. The event should be checked for the account, object path and access performed.

**Auditing status:** The GPO application issue on FS01 has been resolved. Windows Group Policy Results identifies `GPO-File-Server-Auditing` as the winning GPO for Audit File System, configured for Success and Failure. The effective audit policy also reports Success and Failure. A separate local-policy override test was not performed.

## PowerShell Automation

### Session 1 — Basic Infrastructure Health Checks (27 October 2026)

**Objective**

Develop practical PowerShell automation skills by creating a reusable script to check the connectivity and service status of Windows servers in the lab environment.

The exercise simulates an infrastructure engineer performing routine operational checks across multiple servers rather than manually logging into each server.

**Environment**

- Windows Server 2025
- Windows PowerShell 5.1
- DC01 — Domain Controller
- FS01 — File Server
- Active Directory domain: `CTRL-TECH.net`

### Task 1 — Network Connectivity Testing

Used PowerShell to check whether FS01 responded to ICMP requests.

```powershell
Test-Connection -ComputerName FS01 -Count 2
```

The command successfully returned two ICMP responses.

Introduced the `-Quiet` parameter:

```powershell
Test-Connection -ComputerName FS01 -Count 2 -Quiet
```

Result:

```text
True
```

**Learning outcome:** Understood how ICMP connectivity testing works and how Boolean output can be used within automation.

ICMP responses confirm basic network reachability but do not guarantee that the server or its applications are functioning correctly.

### Task 2 — Variables and Arrays

Created an array containing the servers to check:

```powershell
$Servers = @("DC01", "FS01")
```

Used PowerShell to display the contents:

```powershell
$Servers
```

Output:

```text
DC01
FS01
```

**Learning outcome:** Understood how variables store information and how arrays allow multiple server names to be processed.

### Task 3 — Foreach Loops

Created a loop to process the servers individually:

```powershell
foreach ($Server in $Servers) {
    Write-Host "Checking server: $Server"
}
```

Output:

```text
Checking server: DC01
Checking server: FS01
```

Expanded the loop to perform connectivity checks:

```powershell
foreach ($Server in $Servers) {
    Test-Connection -ComputerName $Server -Count 2 -Quiet
}
```

Both servers returned `True`.

**Learning outcome:** Understood how a `foreach` loop executes a command for each item in an array, reducing repetitive manual work.

### Task 4 — Conditional Logic

Introduced `if` and `else` statements to interpret connectivity results.

```powershell
foreach ($Server in $Servers) {

    if (Test-Connection -ComputerName $Server -Count 2 -Quiet) {
        Write-Host "$Server is reachable"
    }
    else {
        Write-Host "$Server is NOT reachable"
    }

}
```

Successful checks displayed readable messages for both servers.

**Learning outcome:** Learned how to make a PowerShell script take different actions depending on the result of a condition.

### Task 5 — Windows Service Monitoring

Checked the Windows Server service on FS01.

Executed locally on FS01:

```powershell
Get-Service -Name LanmanServer
```

Result:

```text
Running
```

Executed remotely from DC01:

```powershell
Get-Service -ComputerName FS01 -Name LanmanServer
```

The remote service check also returned `Running`.

Stored the service information in a variable:

```powershell
$Service = Get-Service -ComputerName FS01 -Name LanmanServer
```

Inspected the service status:

```powershell
$Service.Status
```

Result:

```text
Running
```

Used conditional logic to evaluate the service state:

```powershell
if ($Service.Status -eq 'Running') {
    Write-Host "FS01 Server service is running"
}
else {
    Write-Host "FS01 Server service is NOT running"
}
```

**Learning outcome:** Learned how to retrieve Windows service information remotely, inspect object properties and evaluate service status programmatically.

### Task 6 — Creating Reusable Functions

Introduced PowerShell functions to group commands into reusable operations.

Created a basic function:

```powershell
function Show-ServerMessage {
    Write-Host "Infrastructure health check started"
}
```

Successfully executed the function.

Developed a more practical function named `Test-ServerHealth`.

The function accepts a server name, checks connectivity and inspects the Windows Server service.

```powershell
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
```

Executed the function against FS01:

```powershell
Test-ServerHealth -Server FS01
```

Output:

```text
FS01 is reachable
FS01 Server service is running
```

Executed the function against DC01:

```powershell
Test-ServerHealth -Server DC01
```

Output:

```text
DC01 is reachable
DC01 Server service is running
```

Both tests completed successfully.

**Learning outcome:** Understood how PowerShell functions, parameters, conditional statements and service queries can be combined to automate routine infrastructure checks.

### Task 7 — Saving and Reusing the Script

Prepared the health-check function as a reusable PowerShell script.

**Script filename:** `Test-ServerHealth.ps1`

**Lab location:** `C:\Scripts\Test-ServerHealth.ps1`

**GitHub location:** [PowerShell/Test-ServerHealth.ps1](PowerShell/Test-ServerHealth.ps1)

The saved version includes function calls for DC01 and FS01 so both servers can be checked when the script executes.

To execute the saved script from PowerShell on DC01:

```powershell
& "C:\Scripts\Test-ServerHealth.ps1"
```

The script provides a starting point for developing more advanced infrastructure monitoring and operational automation.

### Session 1 — Results and Validation

| Test | Server | Result |
| --- | --- | --- |
| ICMP connectivity | DC01 | Successful |
| ICMP connectivity | FS01 | Successful |
| Windows Server service | DC01 | Running |
| Windows Server service | FS01 | Running |
| Reusable PowerShell function | DC01 | Successful |
| Reusable PowerShell function | FS01 | Successful |

These results were observed during the interactive PowerShell training session. The saved script is available for future execution and validation.

### Session 1 — Limitations

The current script is an introductory automation exercise rather than a complete production monitoring solution.

- An ICMP failure prevents the script from proceeding to the service check.
- ICMP failure does not necessarily mean a server is offline.
- The script currently checks only the `LanmanServer` service.
- Remote service-query failures are not handled using structured error handling.
- Results are displayed using `Write-Host` rather than returned as structured PowerShell objects.
- No CSV, HTML or historical monitoring report is generated.

These limitations will be addressed progressively in future automation sessions.

### Session 1 — Skills Demonstrated

- Windows PowerShell scripting
- Variables and arrays
- `foreach` loops
- `if` and `else` conditional statements
- PowerShell functions and parameters
- ICMP connectivity testing
- Windows service administration
- Remote infrastructure checks
- Basic infrastructure automation
- Operational validation and troubleshooting

### Session 2 — Planned Improvements

- Introduce `try` and `catch` error handling.
- Improve handling of unreachable servers and remote service failures.
- Check additional Windows services.
- Develop structured output using PowerShell objects.
- Generate reusable reports.
- Continue developing automation relevant to infrastructure engineering and systems administration.

## Validation evidence

The lab exercises cover the following outcomes. Commands are provided so that the configuration can be checked again; they were not executed against the lab while preparing this README.

| Area | Evidence to inspect |
| --- | --- |
| Network configuration | Static addresses on DC01/FS01; DHCP lease, gateway and DNS on CLIENT01 using `ipconfig /all` |
| Domain services | `Get-ADDomain`, OU structure, test users and security groups |
| DHCP | Active scope, options and CLIENT01 lease using `Get-DhcpServerv4Lease -ScopeId 192.168.100.0` on DC01 |
| DNS | FS01 A record registered automatically in the `ctrl-tech.net` zone, owned by `CTRL-TECH\FS01$`; resolution can be checked using `Resolve-DnsName FS01.CTRL-TECH.net -Server 192.168.100.2` |
| SMB connectivity | `Test-NetConnection FS01.CTRL-TECH.net -Port 445` from CLIENT01 |
| User access | Test each user's permitted access and denial outside the intended permissions |
| Workstation policy and drive mapping | `gpresult /r`, visible workstation settings and mapped drives in the user's session |
| Password and lockout policy | Effective domain settings from `Get-ADDefaultDomainPasswordPolicy` |
| File auditing | FS01 Security Event ID 4663, `auditpol` output and Group Policy Results identifying `GPO-File-Server-Auditing` as the winning GPO |
| PowerShell automation | Successful interactive connectivity and remote service checks against DC01 and FS01; reusable script in `PowerShell/Test-ServerHealth.ps1` |

### Screenshots

The screenshots below document policy configuration, client behaviour, file access, local auditing and central Group Policy verification.

| # | Evidence | Screenshot |
| --- | --- | --- |
| 01 | Workstation GPO link | [Workstation policy link](01-GPO-Workstation-Link.png) |
| 02 | Account lockout settings in Group Policy | [GPO account lockout policy](02-GPO-Account-Lockout-Policy.png) |
| 03 | Policy application on CLIENT01 | [CLIENT01 applied GPO](03-CLIENT01-GPO-Applied.png) |
| 04 | Client account lockout verification | [CLIENT01 lockout verification](04-CLIENT01-Account-Lockout-Verification.png) |
| 05 | File share permission testing | [CLIENT01 share permissions](05-CLIENT01-File-Share-Permissions.png) |
| 06 | Finance drive mapping | [Finance mapped drive](06-CLIENT01-Finance-Drive-Mapping.png) |
| 07 | IT drive mapping | [IT mapped drive](07-CLIENT01-IT-Drive-Mapping.png) |
| 08 | Domain account lockout policy | [Domain lockout policy](08-Domain-Account-Lockout-Policy.png) |
| 09 | Cross-department access testing | [Cross-department access](09-Shared-Folder-Cross-Department-Access.png) |
| 10 | File-system auditing on FS01 | [FS01 local auditing evidence](10-FS01-File-System-Auditing.png) |
| 11 | FS01 Group Policy Results: Audit File System, Success and Failure, winning auditing GPO | [FS01 GPO auditing verification](11-FS0-GPO-Auditing-Verification.png) |

Screenshot 10 documents the original local auditing test. Screenshot 11 provides evidence that Windows identifies `GPO-File-Server-Auditing` as the winning GPO for Audit File System on FS01.

## Troubleshooting

### FS01 DNS Registration: Secure Dynamic Update Issue Resolved (27 October 2026)

**Issue identified**

FS01 was unable to register its DNS A record automatically in the `ctrl-tech.net` DNS zone. A record had previously been created manually on DC01 to restore hostname resolution.

Although the manually created record allowed hostname resolution, it did not resolve the underlying dynamic DNS registration problem.

**Investigation**

Examined the Windows System event log on FS01 and identified **DNS Client Event ID 8018**, reporting that the DNS server had refused the dynamic update request.

The event confirmed that FS01 was attempting to register its hostname and IP address with DC01 (`192.168.100.2`).

Further investigation established that:

- The DNS zone was configured to allow **Secure** dynamic updates.
- The existing FS01 A record had been created manually.
- The existing record had no timestamp displayed.
- The `CTRL-TECH\FS01$` computer account did not have effective write permissions on the existing record.

**Root cause**

The evidence strongly indicated that the manually created DNS record's permissions were preventing FS01 from updating its own record through secure dynamic DNS.

**Resolution**

Removed the existing manually created FS01 A record from the `ctrl-tech.net` forward lookup zone on DC01.

On FS01, initiated dynamic DNS registration:

```powershell
ipconfig /registerdns
```

**Validation**

- Refreshed DNS Manager on DC01 and confirmed that a new FS01 A record had been created automatically.
- Verified that the new DNS record was owned by `CTRL-TECH\FS01$`, rather than the administrator account.
- Confirmed that FS01 could register its own DNS record without manually recreating it.

**Outcome**

Automatic DNS registration was successfully restored for FS01. The investigation demonstrated how DNS record permissions and Active Directory computer accounts interact with secure dynamic DNS updates.

**Skills demonstrated:** Windows Server DNS, secure dynamic updates, Active Directory security permissions, Windows Event Viewer, PowerShell and infrastructure troubleshooting.

### Auditing Group Policy: Application and Winning Policy Verified (27 October 2026)

**Issue identified**

The `GPO-File-Server-Auditing` policy was not applying to FS01, despite the GPO already existing and being configured for file-system auditing.

Investigation using `gpresult /r /scope computer` revealed that FS01 was located in the default Active Directory `CN=Computers` container rather than the dedicated Servers OU.

**Root cause**

The auditing GPO was linked to `OU=Servers,OU=CTRLTECH,DC=ctrl-tech,DC=net`, but FS01 was outside that OU. Consequently, the server was not within the scope of the GPO link.

**Resolution**

On DC01, moved the FS01 computer account into the existing Servers OU using PowerShell:

```powershell
Move-ADObject -Identity "CN=FS01,CN=Computers,DC=ctrl-tech,DC=net" -TargetPath "OU=Servers,OU=CTRLTECH,DC=ctrl-tech,DC=net"
```

On FS01, refreshed Group Policy:

```powershell
gpupdate /force
```

**Validation**

- Confirmed FS01 was now located in the Servers OU.
- Used `gpresult /r /scope computer` to confirm that `GPO-File-Server-Auditing` appeared under Applied Group Policy Objects.
- Inspected the GPO's `audit.csv` file in SYSVOL, confirming Audit File System was configured for Success and Failure, with setting value `3`.
- Inspected FS01's local audit policy file and confirmed it contained the matching Audit File System configuration.
- Ran `auditpol /get /subcategory:"File System" /r` on FS01 and confirmed effective Success and Failure auditing.
- Generated a Windows Group Policy Results HTML report using:

```powershell
gpresult /h "C:\Windows\Temp\FS01-GPO-Report.html" /scope computer /f
```

- Confirmed that `GPO-File-Server-Auditing` appeared under Applied Group Policy Objects in the report.
- Confirmed **Audit File System: Success, Failure** under Advanced Audit Policy Configuration.
- Confirmed that the report identified **GPO-File-Server-Auditing** as the **Winning GPO**.
- Captured screenshot 11 as supporting evidence.

**Outcome**

The GPO application issue was resolved by correcting FS01's Active Directory OU placement.

Subsequent Windows Group Policy Results verification identified `GPO-File-Server-Auditing` as the winning GPO for the Audit File System setting. The centrally configured policy and FS01's effective audit settings both specify Success and Failure.

This completes the GPO application and winning-policy verification. A separate test removing or overriding the earlier local audit configuration was not performed.

**Skills demonstrated:** Active Directory administration, OU management, Group Policy troubleshooting, PowerShell, Advanced Audit Policy Configuration, Resultant Set of Policy reporting and evidence-based validation.

## Lessons learned

- **DNS is a dependency to verify early.** An IP connection can work while access by hostname fails. Inspecting the record and testing directly against DC01 makes the fault easier to isolate.
- **Secure dynamic DNS updates depend on record permissions.** A manually created DNS record may resolve correctly while preventing the associated computer account from updating it. Event ID 8018, effective permission checks and DNS record ownership helped identify and resolve the issue.
- **Configured policy and effective policy are different evidence.** A setting visible in a GPO needs confirmation on the target computer and in the correct user or computer context.
- **The Winning GPO provides valuable troubleshooting evidence.** Group Policy Results can identify which GPO Windows reports as responsible for a configured setting, providing stronger evidence than simply checking that a GPO appears in the applied list.
- **File access involves several controls.** Domain group membership, share permissions and NTFS permissions all contribute to the final result. Testing as each user is essential.
- **Auditing requires both policy and an object auditing entry.** Audit policy configuration and SACL entries serve different purposes, and both are relevant when validating file access events.
- **Document workarounds and resolutions honestly.** Temporary fixes can restore functionality, but investigating their underlying causes provides stronger evidence of troubleshooting ability. Verification results should be recorded accurately without claiming tests that were not performed.
- **PowerShell can reduce repetitive administration.** Using functions, variables, loops and conditional logic allows routine checks to be reused across multiple servers.
- **Connectivity and service health are separate checks.** A server responding to ICMP does not necessarily mean its services are functioning correctly.
- **Automation should be developed incrementally.** Starting with simple checks and gradually introducing error handling, reporting and more comprehensive validation helps build reliable scripts.

## Next steps

- Capture additional before-and-after access tests and policy reports for repeatable validation.
- Record exact OU names, group memberships, permission entries and policy values alongside future build automation.
- Continue PowerShell Automation Session 2 with error handling, expanded service checks and structured reporting.
- Capture supporting screenshots of PowerShell automation execution.
- Expand infrastructure monitoring, troubleshooting and operational validation scenarios.
- Continue developing Windows Server and Microsoft Azure infrastructure engineering skills.

---

This is a learning lab and portfolio project. Its scope is a small Windows domain with documented implementation decisions, validation methods, resolved troubleshooting issues and progressively developed PowerShell automation.
