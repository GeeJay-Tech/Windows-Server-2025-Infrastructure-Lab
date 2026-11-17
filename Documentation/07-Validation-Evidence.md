# Validation Evidence

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
| PowerShell automation | Session 4 saved script tested with five service checks across DC01 and FS01; results displayed and exported to CSV |

### Screenshots

The screenshots below document policy configuration, client behaviour, file access, local auditing and central Group Policy verification.

| # | Evidence | Screenshot |
| --- | --- | --- |
| 01 | Workstation GPO link | [Workstation policy link](../01-GPO-Workstation-Link.png) |
| 02 | Account lockout settings in Group Policy | [GPO account lockout policy](../02-GPO-Account-Lockout-Policy.png) |
| 03 | Policy application on CLIENT01 | [CLIENT01 applied GPO](../03-CLIENT01-GPO-Applied.png) |
| 04 | Client account lockout verification | [CLIENT01 lockout verification](../04-CLIENT01-Account-Lockout-Verification.png) |
| 05 | File share permission testing | [CLIENT01 share permissions](../05-CLIENT01-File-Share-Permissions.png) |
| 06 | Finance drive mapping | [Finance mapped drive](../06-CLIENT01-Finance-Drive-Mapping.png) |
| 07 | IT drive mapping | [IT mapped drive](../07-CLIENT01-IT-Drive-Mapping.png) |
| 08 | Domain account lockout policy | [Domain lockout policy](../08-Domain-Account-Lockout-Policy.png) |
| 09 | Cross-department access testing | [Cross-department access](../09-Shared-Folder-Cross-Department-Access.png) |
| 10 | File-system auditing on FS01 | [FS01 local auditing evidence](../10-FS01-File-System-Auditing.png) |
| 11 | FS01 Group Policy Results: Audit File System, Success and Failure, winning auditing GPO | [FS01 GPO auditing verification](../11-FS0-GPO-Auditing-Verification.png) |

Screenshot 10 documents the original local auditing test. Screenshot 11 provides evidence that Windows identifies `GPO-File-Server-Auditing` as the winning GPO for Audit File System on FS01.

### 30 October 2026 — User onboarding and Finance share investigation

| Item | Evidence / status |
| --- | --- |
| Existing directory structure | Users, Groups, Servers and Workstations OUs observed on DC01 |
| Departmental groups | `SG-Finance-Staff` and `SG-IT-Staff` confirmed in Groups OU |
| Daniel Brooks | Account confirmed present after password-policy failure; initially disabled with no password set; subsequent password reset, enable, password-change-at-logon and group-add commands ran without reported errors |
| Batch onboarding | Interactive loop reported onboarding completed for Emily Carter, Olivia Bennett and Marcus Reed |
| Finance SMB share | FS01 `Finance` share at `C:\Shares\Finance`; `SG-Finance-Staff` shown with Allow/Change share access |
| Emily Carter group membership | Initially only `Domain Users` returned; the command to add her to `SG-Finance-Staff` was run without reported error |
| **Outstanding** | Verify Emily can open `\\FS01\Finance` from CLIENT01 after a fresh sign-in; confirm effective NTFS access if needed |

This is evidence from the interactive lab session, not an independent new test against the servers or a verified end-to-end user access test. No new screenshots or saved onboarding script were added during this documentation update.

### 3 November 2026 — Completed client access test and onboarding

| Item | Observed result |
| --- | --- |
| CLIENT01 DHCP | Lease renewal succeeded after restart of `DHCPServer` on DC01; underlying cause of prior timeout not confirmed |
| Emily Carter | Successful domain sign-in to CLIENT01 and successful access to `\\FS01\Finance` |
| CSV onboarding | `NewEmployees.csv` was imported on DC01; interactive onboarding routine reported success for Charlotte Evans and Thomas Hughes |
| Reusable script | [`New-ADUsersFromCsv.ps1`](../PowerShell/New-ADUsersFromCsv.ps1) committed to GitHub; saved-file duplicate handling verified on DC01 (both existing accounts skipped) |

The successful Emily access test resolves the earlier pending end-to-end validation. No screenshot evidence from the new test has been committed.

### 3 November 2026 — Controlled DNS fault: results and limits

| Check | Observed result |
| --- | --- |
| Domain service checks | DNS, Netlogon and NTDS on DC01 all Running |
| CLIENT01 sign-in reproduction | Completed within a few seconds; simulated slow sign-in not reproduced |
| CLIENT01 DNS override | Changed from DC01 `192.168.100.2` to FS01 `192.168.100.3` |
| CLIENT01 IP configuration | `192.168.100.100` remained assigned; `ipconfig /all` showed DNS `192.168.100.3` |
| Windows network status | User observed a disconnected status after the DNS change |
| Finance share access | Both `\\192.168.100.3\Finance` and `\\FS01\Finance` opened successfully |
| PowerShell DNS restoration | `-ResetServerAddresses` returned a CIM permission-denied error |
| Restored state | Reconfigured IPv4 DNS to automatic in Windows network properties; DNS reverted to `192.168.100.2` and Windows network status returned to connected |
| Conclusion | Intended file-share outage **not reproduced**; specific mechanism behind Windows network-status change not proven |

This is an honest record of an **inconclusive controlled test**, not evidence of a solved Finance-share incident. No new screenshot files were uploaded.

### 17 November 2026 — PowerShell Session 4 validation

| Test | User-observed result |
| --- | --- |
| Interactive service checks — DC01 | DNS, LanmanServer, WinRM: Running |
| Interactive service checks — FS01 | LanmanServer, WinRM: Running |
| Structured health report | Five rows with server, service and status |
| CSV export | `Infrastructure-HealthReport.csv` opened and all five records visible |
| Saved script execution | `C:\Scripts\Test-ServerHealth.ps1` executed successfully on DC01 with the expected five results and export message |
| GitHub script | Updated to the Session 4 version, matching the code tested on DC01 |

No new screenshots or CSV files were uploaded to the repository; results were confirmed during the live lab session. Error handling for a failed query had been practised previously in Session 2, but the Session 4 saved script's failure path was not separately exercised.

### 17 November 2026 — PowerShell Session 5 validation

| Check | Observed result |
| --- | --- |
| FS01 disk query | C: total 125.89 GB; free 107.31 GB |
| FS01 disk usage | Approximately 14.76% used |
| Simulated threshold tests | 14.76% = Healthy; 80% = Warning; 90% = Critical |
| Saved script — DC01 disk | C: 125.92 GB total, 108.01 GB free, 14.22% used, Healthy |
| Saved script — FS01 disk | C: 125.89 GB total, 107.31 GB free, 14.76% used, Healthy |
| Saved script — services | DC01 DNS/LanmanServer/WinRM and FS01 LanmanServer/WinRM all Running |
| CSV export | Both HealthReport and DiskReport export confirmation messages visible on DC01 |

Evidence comes from the user's PowerShell output screenshot during the lab session. The disk-report CSV content was not separately inspected after the saved-script run, and neither CSV nor screenshot has been committed as a separate file. Error-path behaviour for the saved disk-monitoring code remains untested.
