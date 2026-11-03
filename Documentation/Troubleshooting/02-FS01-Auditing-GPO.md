# Auditing Group Policy: Application and Winning Policy Verified (27 October 2026)

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

---

[Back to troubleshooting index](../05-Troubleshooting.md)
