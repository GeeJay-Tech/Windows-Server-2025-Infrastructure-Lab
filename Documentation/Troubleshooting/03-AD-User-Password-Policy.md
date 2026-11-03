# Active Directory onboarding: password-policy failure and partial account creation (30 October 2026)

**Issue:** The first attempt to create Daniel Brooks (`dbrooks`) using `New-ADUser` failed with an `ADPasswordComplexityException` because the temporary password did not meet the domain password policy. A second attempt returned `ADIdentityAlreadyExistsException`.

**Investigation:** `Get-ADUser -Identity "dbrooks" -Properties Enabled,PasswordLastSet,Department` confirmed that the object existed with `Enabled = False`, a blank `PasswordLastSet`, and `Department = Finance`.

**Resolution:** Set a compliant temporary password using `Set-ADAccountPassword -Identity "dbrooks" -Reset -NewPassword $Password -ErrorAction Stop`; enabled the existing account with `Enable-ADAccount`; set `ChangePasswordAtLogon` to `$true`; and added the account to `SG-Finance-Staff` using `Add-ADGroupMember`. These commands completed without reported errors.

**Lesson:** A failed `New-ADUser` attempt can still leave an AD object behind. Check the existing object and repair its state rather than blindly retrying creation. A separate end-to-end sign-in test was not performed.

---

[Back to troubleshooting index](../05-Troubleshooting.md)
