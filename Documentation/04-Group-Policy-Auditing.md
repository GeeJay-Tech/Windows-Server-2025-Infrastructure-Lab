# Group Policy and File Access Auditing

## File access auditing

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
