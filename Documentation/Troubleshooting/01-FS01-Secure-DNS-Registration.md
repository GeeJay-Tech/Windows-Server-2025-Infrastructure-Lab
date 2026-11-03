# FS01 DNS Registration: Secure Dynamic Update Issue Resolved (27 October 2026)

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

---

[Back to troubleshooting index](../05-Troubleshooting.md)
