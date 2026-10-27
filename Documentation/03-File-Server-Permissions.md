# Domain Membership and File Server Permissions

## Domain membership, file access and policy

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
