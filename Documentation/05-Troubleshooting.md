# Troubleshooting

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

### Active Directory onboarding: password-policy failure and partial account creation (30 October 2026)

**Issue:** The first attempt to create Daniel Brooks (`dbrooks`) using `New-ADUser` failed with an `ADPasswordComplexityException` because the temporary password did not meet the domain password policy. A second attempt returned `ADIdentityAlreadyExistsException`.

**Investigation:** `Get-ADUser -Identity "dbrooks" -Properties Enabled,PasswordLastSet,Department` confirmed that the object existed with `Enabled = False`, a blank `PasswordLastSet`, and `Department = Finance`.

**Resolution:** Set a compliant temporary password using `Set-ADAccountPassword -Identity "dbrooks" -Reset -NewPassword $Password -ErrorAction Stop`; enabled the existing account with `Enable-ADAccount`; set `ChangePasswordAtLogon` to `$true`; and added the account to `SG-Finance-Staff` using `Add-ADGroupMember`. These commands completed without reported errors.

**Lesson:** A failed `New-ADUser` attempt can still leave an AD object behind. Check the existing object and repair its state rather than blindly retrying creation. A separate end-to-end sign-in test was not performed.

### Finance share: controlled missing-group-membership scenario (30 October 2026)

**Scenario:** Investigated a simulated report that one Finance employee could not access the Finance share while other authorised employees could. No actual access-denied sign-in was generated during this session.

**Evidence gathered:**

- FS01 was running and accessible for administration.
- `Get-SmbShare` confirmed the `Finance` SMB share at `C:\Shares\Finance`.
- `Get-SmbShareAccess -Name Finance` showed `CTRL-TECH\SG-Finance-Staff` with `Allow / Change` share permissions; no explicit Deny was shown in that output.
- Emily Carter (`ecarter`) was deliberately left out of the Finance security group at onboarding. `Get-ADPrincipalGroupMembership -Identity "ecarter" | Select-Object Name` returned only `Domain Users`.

**Likely cause and corrective action:** Emily did not belong to the security group granted access at the SMB-share layer. Ran:

```powershell
Add-ADGroupMember -Identity "SG-Finance-Staff" -Members "ecarter" -ErrorAction Stop
```

The user reported running this command without a reported error. **At the time of this exercise, actual folder access remained unverified.** A later CLIENT01 sign-in and Finance-share access test succeeded on 3 November 2026, documented below.

**Skills practised:** Scoping an incident to one user, inspecting SMB share permissions, checking AD group membership, selecting a targeted change, and distinguishing a probable cause from verified resolution.

### CLIENT01 DHCP lease recovery and Finance share access — Follow-up (3 November 2026)

**Symptom:** CLIENT01, unused for some time, received APIPA address `169.254.55.31` and could not authenticate a newly created domain user. Its Ethernet adapter was Up and DHCP enabled; all lab VMs were connected to the existing NAT-Switch.

**Findings:** DC01's DHCP Server service was Running, DHCP scope `192.168.100.100–192.168.100.200` was Active with 101 free addresses, and DHCP binding showed `True`. CLIENT01 could ping DC01 at `192.168.100.2` after temporarily assigning `192.168.100.50/24`, confirming basic IP connectivity on the lab network. The temporary address was removed and DHCP re-enabled; DHCP renewal had still timed out.

**Recovery:** Restarted the DHCP Server service on DC01 and ran `ipconfig /renew` on CLIENT01. The user confirmed that DHCP address allocation resumed successfully. **The precise underlying reason DHCP stopped responding was not established**; service restart restored the observed functionality.

**End-to-end access test:** Signed in to CLIENT01 successfully as Emily Carter (`ecarter`) and confirmed access to `\\FS01\Finance`. This completes the client-side validation previously pending after adding Emily to `SG-Finance-Staff`.

**Lessons:** Target troubleshooting at the actual service failure, use confirmed findings to avoid repeated checks, and distinguish service recovery from a proven root cause. Restarting DHCP can interrupt clients requesting leases and should be assessed more cautiously outside an isolated lab.

### Controlled DNS misconfiguration: observed network status, not a reproduced share outage (3 November 2026)

**Exercise design:** After a simulated report of slow domain sign-ins and intermittent share access, investigated whether the issue was reproducible. Questions asked included whether users could sign in at all, how many were affected, and whether internal shares were slow. DC01's DNS, Netlogon and NTDS services were confirmed Running. A test sign-in on CLIENT01 completed in a few seconds, so the reported slow sign-in **was not reproduced**.

**Controlled change:** On CLIENT01, deliberately pointed the Ethernet adapter's DNS server at `192.168.100.3` (FS01) instead of the actual domain DNS server `192.168.100.2` (DC01):

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.100.3
```

**Direct observations:**

- `ipconfig /all` showed a valid IPv4 address `192.168.100.100` and DNS server `192.168.100.3`.
- Windows on CLIENT01 **reported that the network was disconnected** after the DNS change. This was the operator's observed Windows status, not proof that IP-level connectivity had been lost.
- Emily could still open the Finance SMB share using both `\\192.168.100.3\Finance` and `\\FS01\Finance`. Therefore **the intended Finance share access failure was not reproduced**.
- The mechanism by which the short hostname continued resolving was not determined; cached or alternative name resolution was possible but not established.

**Restoration:** Attempted `Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ResetServerAddresses`. It returned a CIM `PermissionDenied` error, including after trying a different sign-in context. The precise cause of that error was not identified. The DNS configuration was ultimately restored through the Windows Ethernet IPv4 properties, choosing to obtain the DNS server address automatically. Afterwards, CLIENT01 showed DNS server `192.168.100.2` and Windows reported normal network connectivity.

**Outcome and limitation:** The controlled DNS change affected Windows' reported connectivity state but **did not prevent Finance share access and did not recreate the original simulated user incident**. It is recorded as an inconclusive fault-injection exercise, **not** as a successfully diagnosed or resolved Finance outage. The effect on domain services and the cause of the CIM permission errors were not proven.

**Learning:** Reproduce the reported symptom before claiming a root cause; distinguish Windows' network-status indicator from observed IP/SMB reachability; document unsuccessful tests transparently. A future controlled scenario should use a fault verified to produce the intended symptom while remaining reversible.
