# Finance share: controlled missing-group-membership scenario (30 October 2026)

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

---

[Back to troubleshooting index](../05-Troubleshooting.md)
