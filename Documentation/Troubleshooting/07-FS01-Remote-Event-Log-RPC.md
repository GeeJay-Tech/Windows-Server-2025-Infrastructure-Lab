# FS01 remote Event Log access — RPC error and firewall resolution (17 November 2026)

## Symptom

During PowerShell Event Log monitoring training, a remote query from DC01 to FS01 failed:

```powershell
Get-WinEvent -ComputerName FS01 -FilterHashtable @{
    LogName = 'System'
    Level = 2
    StartTime = (Get-Date).AddDays(-7)
} -MaxEvents 10
```

**Observed error:** `Get-WinEvent : The RPC server is unavailable` (`EventLogException`). This was a real access failure in the lab, not a simulated error.

## Investigation and evidence

1. On DC01, `Test-NetConnection FS01 -Port 135` returned `TcpTestSucceeded : True`. This established TCP access to the RPC Endpoint Mapper, not the availability of all RPC dynamic ports.
2. On DC01, `Get-Service -ComputerName FS01 -Name EventLog` returned `Running`. The Event Log service itself was active.
3. On FS01, `Get-NetFirewallRule -DisplayGroup "Remote Event Log Management" | Select-Object DisplayName, Enabled, Direction, Action` showed that **all rules in the group were disabled**.

## Corrective action

In the isolated lab, enabled the Windows Firewall rule group on FS01:

```powershell
Get-NetFirewallRule -DisplayGroup "Remote Event Log Management" |
    Enable-NetFirewallRule
```

This enabled rules rather than disabling the firewall. In a production environment, management access would need to be restricted to authorised source hosts and appropriate network profiles.

## Validation

Re-ran the original `Get-WinEvent` query from DC01. **Remote retrieval succeeded** and returned events from FS01's System log. The before/after evidence strongly supports disabled remote Event Log firewall rules as the cause of the remote query failure.

## Follow-up: interpreting DCOM events

The successful query returned six repeated entries for **DistributedCOM, Event ID 10005**, all at **17 November 2026 03:37:29**. The message reported DCOM error **1115** while trying to start `wuauserv` (Windows Update). Error 1115 indicates a system shutdown was in progress.

A targeted remote System-log query for events 1074, 6006 and 6008 around 03:30–03:45 showed:

| Time (17 Nov 2026) | Event ID | Observed details |
| --- | --- | --- |
| 03:37:25 | 1074 | `MoUsoCoreWorker.exe` initiated a **planned** restart for Windows servicing |
| 03:37:29 | 10005 | Six DCOM errors while attempting to start `wuauserv` |
| 03:40:02 | 6006 | Windows Event Log service stopped |
| 03:41:48 | 1074 | `TrustedInstaller.exe` initiated another **planned** restart |
| 03:41:49 | 6006 | Windows Event Log service stopped |

A subsequent `Get-Service -ComputerName FS01 -Name wuauserv` returned `Stopped`. This is **not by itself abnormal**, as Windows Update can be stopped when idle.

**Assessment:** The timing and error code strongly suggest that DCOM attempts to activate Windows Update occurred while planned shutdown or restart activity was in progress. The recorded events do not establish that servicing failed or that Windows Update has an ongoing fault. No update-installation-history check was performed.

## Outcome and limitations

- **Verified fix:** DC01 was able to query FS01's System event log remotely after the remote Event Log firewall rules were enabled.
- **Likely cause:** Disabled Remote Event Log Management firewall rules on FS01, supported by direct inspection and successful retest after the change.
- **Separate event analysis:** DCOM errors were consistent with planned maintenance shutdowns; this was an interpretation, **not** a second fault proven and repaired.
- **Not tested:** Which individual firewall rule was essential, exact dynamic RPC-port behaviour, Windows Update installation success or ongoing update health.

**Skills demonstrated:** Remote Windows Event Log queries, RPC connectivity investigation, firewall rule inspection and remediation, service checks, Windows event correlation, and evidence-based incident documentation.

---

[Back to troubleshooting index](../05-Troubleshooting.md)
