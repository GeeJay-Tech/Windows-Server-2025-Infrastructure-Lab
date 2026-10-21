# Windows Server 2025 Infrastructure Lab

A hands-on infrastructure lab built in Hyper-V to practise Windows domain administration, network services, file access control and endpoint policy management. The environment connects Windows Server 2025 infrastructure with a domain-joined Windows 11 client on a private NAT network.

The project demonstrates practical skills relevant to IT support and junior systems administration: managing Active Directory, troubleshooting DNS, configuring DHCP, assigning group-based access, applying Group Policy and investigating Windows Security events.

**Current status:** Core domain, networking, file services and policy exercises are implemented. File access auditing was demonstrated using local `auditpol` configuration and Security event **4663**. Central deployment of the auditing settings through Group Policy remains unresolved.

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
- Enabled local file-system auditing with `auditpol` and observed event 4663.
- Investigated name resolution and policy application issues, recording both the workaround and the remaining limitation.

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
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
Get-ADUser -Filter * | Select-Object Name, Enabled
Get-ADGroup -Filter * | Select-Object Name, GroupScope, GroupCategory
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

File auditing also requires an applicable auditing entry in the target object's SACL. With that entry in place, a matching file access operation can produce event 4663 on FS01. The event should be checked for the account, object path and access performed.

**Known limitation:** Event 4663 demonstrates the local auditing test. It does not establish successful deployment of the auditing configuration through domain Group Policy. That GPO issue remains open, and the local configuration is documented as a workaround.

## Validation evidence

The lab exercises cover the following outcomes. Commands are provided so that the configuration can be checked again; they were not executed against the lab while preparing this README.

| Area | Evidence to inspect |
| --- | --- |
| Network configuration | Static addresses on DC01/FS01; DHCP lease, gateway and DNS on CLIENT01 using `ipconfig /all` |
| Domain services | `Get-ADDomain`, OU structure, test users and security groups |
| DHCP | Active scope, options and CLIENT01 lease using `Get-DhcpServerv4Lease -ScopeId 192.168.100.0` on DC01 |
| DNS | FS01 resolves to `192.168.100.3` using `Resolve-DnsName FS01.CTRL-TECH.net -Server 192.168.100.2` |
| SMB connectivity | `Test-NetConnection FS01.CTRL-TECH.net -Port 445` from CLIENT01 |
| User access | Test each user's permitted access and denial outside the intended permissions |
| Workstation policy and drive mapping | `gpresult /r`, visible workstation settings and mapped drives in the user's session |
| Password and lockout policy | Effective domain settings from `Get-ADDefaultDomainPasswordPolicy` |
| File auditing | Local `auditpol` output and FS01 Security event 4663 |

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

The auditing screenshot supports the local auditing exercise; it does not establish that the unresolved auditing GPO was fixed.

## Troubleshooting

### FS01 name resolution: manual DNS repair

FS01 required a manual DNS A-record fix. An A record for **FS01 → 192.168.100.3** was added in the `CTRL-TECH.net` forward lookup zone on DC01. This addressed the missing name-to-address mapping; it does not prove that automatic DNS registration was repaired.

An equivalent command, if the record is absent, is:

```powershell
# DC01: inspect first to avoid adding a duplicate record.
Get-DnsServerResourceRecord -ZoneName 'CTRL-TECH.net' -Name 'FS01' -RRType A

# Run only if the required record is absent.
Add-DnsServerResourceRecordA -ZoneName 'CTRL-TECH.net' `
    -Name 'FS01' -IPv4Address '192.168.100.3'

Resolve-DnsName FS01.CTRL-TECH.net -Server 192.168.100.2
```

### Auditing Group Policy: unresolved

The intended auditing settings were not successfully established through Group Policy. Local `auditpol` configuration enabled the auditing test and produced event 4663, but central enforcement remains unverified.

Further investigation should compare the GPO's configured settings with FS01's effective policy: check computer OU placement, the GPO link, security filtering and the computer's resultant policy report. Then compare `auditpol /get` output before and after policy refresh, including any interaction between basic and advanced audit policy settings. These are investigation steps, not completed fixes.

## Lessons learned

- **DNS is a dependency to verify early.** An IP connection can work while access by hostname fails. Inspecting the record and testing directly against DC01 makes the fault easier to isolate.
- **Configured policy and effective policy are different evidence.** A setting visible in a GPO needs confirmation on the target computer and in the correct user or computer context.
- **File access involves several controls.** Domain group membership, share permissions and NTFS permissions all contribute to the final result. Testing as each user is essential.
- **Auditing requires both policy and an object auditing entry.** A local success is useful evidence, but central policy deployment needs its own validation.
- **Document workarounds honestly.** The manual DNS record and local auditing configuration demonstrate troubleshooting while preserving a clear record of remaining work.

## Next steps

- Resolve and validate central auditing policy on FS01.
- Investigate FS01 automatic DNS registration so the manual record is not the only documented remedy.
- Capture before-and-after access tests and policy reports for repeatable validation.
- Record exact OU names, group memberships, permission entries and policy values alongside future build automation.

This is a learning lab and portfolio project. Its scope is a small Windows domain with documented implementation decisions, validation methods and an openly tracked policy issue.
