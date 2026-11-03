# Controlled DNS misconfiguration: observed network status, not a reproduced share outage (3 November 2026)

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

---

[Back to troubleshooting index](../05-Troubleshooting.md)
