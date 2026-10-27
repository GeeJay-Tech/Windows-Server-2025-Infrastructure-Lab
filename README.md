# Windows Server 2025 Infrastructure Lab

A hands-on infrastructure lab built in Hyper-V to practise Windows domain administration, network services, file access control and endpoint policy management. The environment connects Windows Server 2025 infrastructure with a domain-joined Windows 11 client on a private NAT network.

The project demonstrates practical skills relevant to IT support, systems administration and infrastructure engineering: managing Active Directory, troubleshooting DNS, configuring DHCP, assigning group-based access, applying Group Policy and investigating Windows Security events.

**Current status:** Core domain, networking, file services and policy exercises are implemented. The FS01 DNS registration issue has been resolved, with secure dynamic DNS registration successfully creating a record owned by the FS01 computer account. The file-server auditing GPO application issue has also been resolved. Independent verification of central audit-policy enforcement remains outstanding.

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
- Diagnosed and resolved secure dynamic DNS registration failure on FS01, including investigation of Event ID 8018 and DNS record permissions.

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

Local auditing on FS01 was used to demonstrate file access events:

```powershell
# Elevated shell on FS01; subcategory name assumes an English installation.

auditpol /set /subcategory:"File System" /success:enable /failure:enable

auditpol /get /subcategory:"File System"

Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663} -MaxEvents 10 |
    Select-Object TimeCreated, Id, Message
```

File auditing also requires an applicable auditing entry in the target object's SACL. With that entry in place, a matching file access operation can produce Event ID 4663 on FS01. The event should be checked for the account, object path and access performed.

**Auditing status:** The GPO application issue on FS01 has been resolved. Event ID 4663 demonstrates the earlier local auditing test. Effective Success and Failure auditing remains enabled following a Group Policy refresh, but central enforcement has not yet been independently isolated from the previous local configuration.

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
| File auditing | Local `auditpol` output, FS01 Security Event ID 4663 and applied auditing GPO |

### Screenshots

The screenshots below document policy configuration, client behaviour, file access and the local auditing test.

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

The auditing screenshot documents the original local auditing test. Subsequent troubleshooting resolved the auditing GPO application issue on FS01.

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

### Auditing Group Policy: GPO Application Issue Resolved (27 October 2026)

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
- Generated and inspected an HTML GPO report on DC01, confirming that Audit File System was configured for Success and Failure.
- Ran `auditpol /get /subcategory:"File System"` on FS01 and confirmed that Success and Failure auditing remained enabled after another Group Policy refresh.

**Outcome**

The original GPO application issue was successfully resolved by correcting FS01's Active Directory OU placement.

File-system auditing is enabled and remains effective following a Group Policy refresh. However, because auditing had previously been enabled locally using `auditpol`, independent verification that the GPO alone enforces these settings remains outstanding.

**Skills demonstrated:** Active Directory administration, OU management, Group Policy troubleshooting, PowerShell, audit policy configuration and validation.

## Lessons learned

- **DNS is a dependency to verify early.** An IP connection can work while access by hostname fails. Inspecting the record and testing directly against DC01 makes the fault easier to isolate.
- **Secure dynamic DNS updates depend on record permissions.** A manually created DNS record may resolve correctly while preventing the associated computer account from updating it. Event ID 8018, effective permission checks and DNS record ownership helped identify and resolve the issue.
- **Configured policy and effective policy are different evidence.** A setting visible in a GPO needs confirmation on the target computer and in the correct user or computer context.
- **File access involves several controls.** Domain group membership, share permissions and NTFS permissions all contribute to the final result. Testing as each user is essential.
- **Auditing requires both policy and an object auditing entry.** A local success is useful evidence, but central policy deployment needs its own validation.
- **Document workarounds and resolutions honestly.** Temporary fixes can restore functionality, but investigating their underlying causes provides stronger evidence of troubleshooting ability. Outstanding validation should remain documented until independently confirmed.

## Next steps

- Independently validate central enforcement of file-system auditing on FS01, distinguishing it from previously configured local auditing settings.
- Capture before-and-after access tests and policy reports for repeatable validation.
- Record exact OU names, group memberships, permission entries and policy values alongside future build automation.
- Continue developing PowerShell-based infrastructure administration and automation exercises.

---

This is a learning lab and portfolio project. Its scope is a small Windows domain with documented implementation decisions, validation methods, resolved troubleshooting issues and clearly identified remaining work.
