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

## Explore the documentation

The detailed implementation commands, troubleshooting investigations, validation evidence and PowerShell learning notes are organised by topic:

| Topic | Documentation |
| --- | --- |
| Hyper-V virtual networking and NAT | [01 — Hyper-V Networking](Documentation/01-Hyper-V-Networking.md) |
| Active Directory, DNS and DHCP | [02 — Active Directory, DNS and DHCP](Documentation/02-Active-Directory-DNS-DHCP.md) |
| Domain membership, file shares and permissions | [03 — File Server Permissions](Documentation/03-File-Server-Permissions.md) |
| Group Policy and file access auditing | [04 — Group Policy and Auditing](Documentation/04-Group-Policy-Auditing.md) |
| Resolved DNS and GPO incidents | [05 — Troubleshooting](Documentation/05-Troubleshooting.md) |
| PowerShell Automation Session 1 | [06 — PowerShell Automation](Documentation/06-PowerShell-Automation.md) |
| Screenshots and validation checklist | [07 — Validation Evidence](Documentation/07-Validation-Evidence.md) |
| Lessons learned and planned work | [08 — Lessons Learned](Documentation/08-Lessons-Learned.md) |

## Featured PowerShell script

[**Test-ServerHealth.ps1**](PowerShell/Test-ServerHealth.ps1) — a first reusable health-check script for DC01 and FS01, checking ICMP reachability and the `LanmanServer` service. See the [session walkthrough](Documentation/06-PowerShell-Automation.md) for the commands, observed results and current limitations.

---

This is a learning lab and portfolio project. Its scope is a small Windows domain with documented implementation decisions, validation methods, resolved troubleshooting issues and progressively developed PowerShell automation.
