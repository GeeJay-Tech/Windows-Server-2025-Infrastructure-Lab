# PowerShell Automation

### Session 1 — Basic Infrastructure Health Checks (27 October 2026)

**Objective**

Develop practical PowerShell automation skills by creating a reusable script to check the connectivity and service status of Windows servers in the lab environment.

The exercise simulates an infrastructure engineer performing routine operational checks across multiple servers rather than manually logging into each server.

**Environment**

- Windows Server 2025
- Windows PowerShell 5.1
- DC01 — Domain Controller
- FS01 — File Server
- Active Directory domain: `CTRL-TECH.net`

### Task 1 — Network Connectivity Testing

Used PowerShell to check whether FS01 responded to ICMP requests.

```powershell
Test-Connection -ComputerName FS01 -Count 2
```

The command successfully returned two ICMP responses.

Introduced the `-Quiet` parameter:

```powershell
Test-Connection -ComputerName FS01 -Count 2 -Quiet
```

Result:

```text
True
```

**Learning outcome:** Understood how ICMP connectivity testing works and how Boolean output can be used within automation.

ICMP responses confirm basic network reachability but do not guarantee that the server or its applications are functioning correctly.

### Task 2 — Variables and Arrays

Created an array containing the servers to check:

```powershell
$Servers = @("DC01", "FS01")
```

Used PowerShell to display the contents:

```powershell
$Servers
```

Output:

```text
DC01
FS01
```

**Learning outcome:** Understood how variables store information and how arrays allow multiple server names to be processed.

### Task 3 — Foreach Loops

Created a loop to process the servers individually:

```powershell
foreach ($Server in $Servers) {
    Write-Host "Checking server: $Server"
}
```

Output:

```text
Checking server: DC01
Checking server: FS01
```

Expanded the loop to perform connectivity checks:

```powershell
foreach ($Server in $Servers) {
    Test-Connection -ComputerName $Server -Count 2 -Quiet
}
```

Both servers returned `True`.

**Learning outcome:** Understood how a `foreach` loop executes a command for each item in an array, reducing repetitive manual work.

### Task 4 — Conditional Logic

Introduced `if` and `else` statements to interpret connectivity results.

```powershell
foreach ($Server in $Servers) {

    if (Test-Connection -ComputerName $Server -Count 2 -Quiet) {
        Write-Host "$Server is reachable"
    }
    else {
        Write-Host "$Server is NOT reachable"
    }

}
```

Successful checks displayed readable messages for both servers.

**Learning outcome:** Learned how to make a PowerShell script take different actions depending on the result of a condition.

### Task 5 — Windows Service Monitoring

Checked the Windows Server service on FS01.

Executed locally on FS01:

```powershell
Get-Service -Name LanmanServer
```

Result:

```text
Running
```

Executed remotely from DC01:

```powershell
Get-Service -ComputerName FS01 -Name LanmanServer
```

The remote service check also returned `Running`.

Stored the service information in a variable:

```powershell
$Service = Get-Service -ComputerName FS01 -Name LanmanServer
```

Inspected the service status:

```powershell
$Service.Status
```

Result:

```text
Running
```

Used conditional logic to evaluate the service state:

```powershell
if ($Service.Status -eq 'Running') {
    Write-Host "FS01 Server service is running"
}
else {
    Write-Host "FS01 Server service is NOT running"
}
```

**Learning outcome:** Learned how to retrieve Windows service information remotely, inspect object properties and evaluate service status programmatically.

### Task 6 — Creating Reusable Functions

Introduced PowerShell functions to group commands into reusable operations.

Created a basic function:

```powershell
function Show-ServerMessage {
    Write-Host "Infrastructure health check started"
}
```

Successfully executed the function.

Developed a more practical function named `Test-ServerHealth`.

The function accepts a server name, checks connectivity and inspects the Windows Server service.

```powershell
function Test-ServerHealth {
    param(
        [string]$Server
    )

    if (Test-Connection -ComputerName $Server -Count 2 -Quiet) {
        Write-Host "$Server is reachable"

        $Service = Get-Service -ComputerName $Server -Name LanmanServer

        if ($Service.Status -eq 'Running') {
            Write-Host "$Server Server service is running"
        }
        else {
            Write-Host "$Server Server service is NOT running"
        }
    }
    else {
        Write-Host "$Server is NOT reachable via ICMP"
    }
}
```

Executed the function against FS01:

```powershell
Test-ServerHealth -Server FS01
```

Output:

```text
FS01 is reachable
FS01 Server service is running
```

Executed the function against DC01:

```powershell
Test-ServerHealth -Server DC01
```

Output:

```text
DC01 is reachable
DC01 Server service is running
```

Both tests completed successfully.

**Learning outcome:** Understood how PowerShell functions, parameters, conditional statements and service queries can be combined to automate routine infrastructure checks.

### Task 7 — Saving and Reusing the Script

Prepared the health-check function as a reusable PowerShell script.

**Script filename:** `Test-ServerHealth.ps1`

**Lab location:** `C:\Scripts\Test-ServerHealth.ps1`

**GitHub location:** [PowerShell/Test-ServerHealth.ps1](../PowerShell/Test-ServerHealth.ps1)

The original Session 1 version included function calls for DC01 and FS01. The current saved script was replaced by the tested multi-server service-reporting version in Session 4 (17 November 2026).

To execute the saved script from PowerShell on DC01:

```powershell
& "C:\Scripts\Test-ServerHealth.ps1"
```

The script provides a starting point for developing more advanced infrastructure monitoring and operational automation.

### Session 1 — Results and Validation

| Test | Server | Result |
| --- | --- | --- |
| ICMP connectivity | DC01 | Successful |
| ICMP connectivity | FS01 | Successful |
| Windows Server service | DC01 | Running |
| Windows Server service | FS01 | Running |
| Reusable PowerShell function | DC01 | Successful |
| Reusable PowerShell function | FS01 | Successful |

These results were observed during the interactive PowerShell training session. The original Session 1 script has since been replaced by the tested Session 4 version. The results here describe the earlier interactive testing.

### Session 1 — Original version limitations (superseded in part by Session 4)

The original Session 1 script was an introductory automation exercise rather than a production monitoring solution. Some of the following limitations were addressed in Session 4; others remain.

- An ICMP failure prevents the script from proceeding to the service check.
- ICMP failure does not necessarily mean a server is offline.
- The script currently checks only the `LanmanServer` service.
- Remote service-query failures are not handled using structured error handling.
- Results are displayed using `Write-Host` rather than returned as structured PowerShell objects.
- No CSV, HTML or historical monitoring report is generated.

These limitations will be addressed progressively in future automation sessions.

### Session 1 — Skills Demonstrated

- Windows PowerShell scripting
- Variables and arrays
- `foreach` loops
- `if` and `else` conditional statements
- PowerShell functions and parameters
- ICMP connectivity testing
- Windows service administration
- Remote infrastructure checks
- Basic infrastructure automation
- Operational validation and troubleshooting

### Session 2 — Error Handling and Service Reporting (28 October 2026)

**Objective:** Extend the interactive PowerShell exercises from Session 1 with error handling, multi-service checks, structured results, filtering, and CSV reporting. These exercises were performed interactively on DC01; at that date the existing [Test-ServerHealth.ps1](../PowerShell/Test-ServerHealth.ps1) file had **not** yet been rewritten to include these improvements. It was updated and tested later in Session 4.

#### Task 1 — Handling service-query errors

Successfully queried the Server service on FS01 with `Get-Service -ComputerName FS01 -Name LanmanServer -ErrorAction Stop`. Then deliberately requested a nonexistent service to exercise `try/catch`:

```powershell
try {
    Get-Service -ComputerName FS01 -Name FakeService123 -ErrorAction Stop
}
catch {
    Write-Host "The service check failed: $($_.Exception.Message)"
}
```

Observed message: `The service check failed: Cannot find any service with service name 'FakeService123'.`

The error was intentional; no service was modified. `-ErrorAction Stop` makes non-terminating command errors catchable in this scenario.

#### Task 2 — Check multiple services remotely

Used an array and `foreach` loop with an independent `try/catch` per service:

```powershell
$Services = @("LanmanServer", "WinRM")

foreach ($ServiceName in $Services) {
    try {
        $Service = Get-Service -ComputerName FS01 -Name $ServiceName -ErrorAction Stop
        Write-Host "FS01 - $($Service.DisplayName): $($Service.Status)"
    }
    catch {
        Write-Host "FS01 - Unable to check ${ServiceName}: $($_.Exception.Message)"
    }
}
```

**Observed live results on FS01:**

| Service | Display name | Status |
| --- | --- | --- |
| `LanmanServer` | Server | Running |
| `WinRM` | Windows Remote Management (WS-Management) | Running |

A service reporting `Running` does not alone prove its dependent functionality works; access, networking, permissions, and application-level checks may still be required.

#### Task 3 — Custom objects and filtering

Created a `[PSCustomObject]` with `Server`, `Service`, and `Status` properties, retrieved `$Result.Status` (returned `Running`), and inspected the object with `$Result | Get-Member`. The live status property was a `ServiceControllerStatus` value.

Practised `Where-Object` filters with `-eq 'Running'` and `-ne 'Running'`. A separate **simulated** dataset contained DNS (Running), Server (Running), and WinRM (Stopped); filtering identified WinRM. **The simulated stopped state was not an actual change to FS01.**

**Windows PowerShell 5.1 observation:** With a single matching `PSCustomObject`, the expression `($HealthResults | Where-Object { $_.Status -ne 'Running' }).Count` produced no output in this lab. Wrapping the pipeline in an array expression worked reliably:

```powershell
@($HealthResults | Where-Object { $_.Status -ne 'Running' }).Count
```

Observed count: `1`. Using `@(...)` is a consistent way to count zero, one, or multiple filtered objects.

#### Task 4 — Collect real service results as objects

Built a report from live remote service queries:

```powershell
$Services = @("LanmanServer", "WinRM")

$HealthReport = foreach ($ServiceName in $Services) {
    try {
        $Service = Get-Service -ComputerName FS01 -Name $ServiceName -ErrorAction Stop

        [PSCustomObject]@{
            Server  = "FS01"
            Service = $Service.DisplayName
            Status  = $Service.Status
        }
    }
    catch {
        [PSCustomObject]@{
            Server  = "FS01"
            Service = $ServiceName
            Status  = "Check Failed"
        }
    }
}

$HealthReport
```

Observed both FS01 services as `Running`. The `catch` branch records a failed query as `Check Failed`; it does not determine the underlying cause or establish that the service itself is stopped.

#### Task 5 — Export, inspect, import, and filter CSV

Exported the report on DC01:

```powershell
$HealthReport | Export-Csv -Path "$env:USERPROFILE\Desktop\FS01-HealthReport.csv" -NoTypeInformation
```

Confirmed the CSV appeared on the desktop and opened it in Notepad (Microsoft 365 was not required). Imported the file back into PowerShell:

```powershell
$ImportedReport = Import-Csv -Path "$env:USERPROFILE\Desktop\FS01-HealthReport.csv"
$ImportedReport
$ImportedReport | Where-Object { $_.Status -ne 'Running' }
```

The imported report displayed both FS01 services as `Running`. Filtering for non-running services returned **no output**, as expected. CSV-imported property values are strings.

#### Session 2 — Results and next steps

- **Verified:** Error handling for a nonexistent service; live remote checks for two FS01 services; custom-object creation and property inspection; filtering and counting; live health-report collection; CSV export and import.
- **At the end of Session 2, not yet done:** Updating and testing the saved `PowerShell/Test-ServerHealth.ps1` script with Session 2 improvements; adding DC01 service checks to the new report; production-grade exception classification, connectivity handling, or scheduled reporting. The first two items were completed in Session 4.
- **Subsequent work:** The multi-server checks, structured results and CSV export were integrated into the reusable script, tested on DC01 and committed in Session 4.

### Session 4 — Multi-server Infrastructure Health Reporting (17 November 2026)

**Objective:** Extend the original `Test-ServerHealth.ps1` beyond single-service checks to collect structured multi-server service statuses and export the results to CSV.

**Environment:** PowerShell on DC01 queried DC01 and FS01 in the existing `CTRL-TECH.net` lab.

**Work completed:**

1. Ran an interactive `Get-Service -ComputerName DC01` loop with `try/catch` and `-ErrorAction Stop` against `LanmanServer`, `WinRM` and `DNS`. All three returned `Running`.
2. Created `[PSCustomObject]` results for service, server and status.
3. Introduced a `$ServerServices` hashtable with separate service lists for DC01 and FS01 and nested `foreach` loops for remote service queries.
4. Confirmed the five resulting service checks through the PowerShell table output.
5. Exported `$HealthReport` to `$env:USERPROFILE\Desktop\Infrastructure-HealthReport.csv` using `Export-Csv -NoTypeInformation` and inspected the CSV file successfully.
6. Replaced the saved `C:\Scripts\Test-ServerHealth.ps1` with the updated version and executed it on DC01 using:

```powershell
& "C:\Scripts\Test-ServerHealth.ps1"
```

**User-confirmed saved-script results:**

| Server | Service | Observed status |
| --- | --- | --- |
| DC01 | DNS | Running |
| DC01 | LanmanServer | Running |
| DC01 | WinRM | Running |
| FS01 | LanmanServer | Running |
| FS01 | WinRM | Running |

The user also confirmed that running the saved script produced the CSV export confirmation and that the CSV report contained all five results. These were lab-side observations reported during the exercise, not an independent GitHub-side execution test.

**Source:** [Updated Test-ServerHealth.ps1](../PowerShell/Test-ServerHealth.ps1).

**Current limitations and next improvements:**

- The Session 4 version checks Windows service statuses; it no longer includes the original ICMP connectivity test.
- A successful service-status query does not establish end-to-end application availability.
- A failed query is recorded as `Check Failed` without separating inaccessible hosts, missing services and permissions failures.
- The CSV is overwritten on each run; no timestamps, alerting, historical logs or scheduling have been implemented.
- Future enhancements: disk capacity, event-log review, clearer failure diagnostics and scheduled reporting, tested incrementally.

**Outcome:** Tested the saved script with five live service queries across two servers and successfully produced a reusable CSV health report.

### Session 5 — Remote Disk Capacity and Health Thresholds (17 November 2026)

**Objective:** Extend the existing, tested multi-server service monitoring script to capture disk capacity, calculate disk usage percentage, classify disk health and export a separate CSV report.

**Interactive tests on DC01:**

- Queried fixed disks on FS01 using `Get-WmiObject -Class Win32_LogicalDisk -ComputerName FS01 -Filter "DriveType=3"`. Confirmed C: capacity of **125.89 GB**, with **107.31 GB free**.
- Calculated FS01's used capacity at approximately **14.76%** with `[math]::Round((($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100, 2)`.
- Introduced thresholds with `if` / `elseif` / `else`: **Healthy below 80%**, **Warning from 80% to below 90%**, and **Critical from 90% upwards**.
- Validated each branch with simulated usage values: **14.76 → Healthy**, **80 → Warning**, **90 → Critical**. No disks were filled or altered to test warnings.
- Repeated remote disk checks for both DC01 and FS01 using a `foreach` loop and structured `[PSCustomObject]` output.
- Appended the disk monitoring section to the **existing** `C:\Scripts\Test-ServerHealth.ps1`, preserving all five service checks from Session 4.

**Actual results from the saved script, run on DC01:**

| Server | Drive | Total (GB) | Free (GB) | Used (%) | Status |
| --- | --- | ---: | ---: | ---: | --- |
| DC01 | C: | 125.92 | 108.01 | 14.22 | Healthy |
| FS01 | C: | 125.89 | 107.31 | 14.76 | Healthy |

The saved script also returned all five Windows services as `Running`:

| Server | Services | Result |
| --- | --- | --- |
| DC01 | DNS, LanmanServer, WinRM | All Running |
| FS01 | LanmanServer, WinRM | Both Running |

**Exported files on DC01:**

- `C:\Users\labadmin\Desktop\Infrastructure-HealthReport.csv`
- `C:\Users\labadmin\Desktop\Infrastructure-DiskReport.csv`

Both export confirmation messages were visible in the script's PowerShell output. The service report had been opened and inspected in Session 4; in Session 5 the output and export messages were observed, but the disk CSV was not independently opened and inspected after executing the saved script.

**Implementation details:** The new disk section uses `Get-WmiObject`, `-ErrorAction Stop`, server-level `try/catch`, a check for zero-sized disks, calculated percentage usage and a separate `Export-Csv -NoTypeInformation`. The script is [available here](../PowerShell/Test-ServerHealth.ps1).

**Limitations:** These are example percentage thresholds, not calibrated production alerting rules. No alert notification, historical records, scheduling or disk-growth trend analysis is present. WMI query failure handling is implemented but not deliberately tested in the saved script. CSV reports overwrite previous runs. A successful service-status or WMI query is not proof that the complete application or storage workload is healthy.

**Outcome:** Verified that the saved script still performs all five service checks and additionally reports two healthy disks, with both CSV export operations completing without reported errors.

### Session 6 — Remote Windows Event Log investigation (17 November 2026)

**Objective:** Use `Get-WinEvent` from DC01 to retrieve genuine FS01 System log errors from the previous seven days and interpret them using related event evidence.

**Actual incident during the lab:** The initial remote `Get-WinEvent` query failed with `The RPC server is unavailable`. Investigation confirmed TCP 135 reachable, the remote EventLog service Running and the Remote Event Log Management firewall group disabled on FS01.

**Action:** Enabled that firewall group on FS01. **Retest succeeded** using the original remote event query, returning DistributedCOM Event ID 10005 entries.

**Event analysis:** Six DCOM 10005 errors at 03:37:29 indicated failure to activate Windows Update (`wuauserv`) with error 1115. Related System events showed `MoUsoCoreWorker.exe` initiated a planned restart at 03:37:25, followed by Event Log stop events and another planned `TrustedInstaller.exe` restart. A subsequent remote service check returned `wuauserv = Stopped`, which is not abnormal by itself. This evidence is consistent with startup attempted during planned shutdown rather than a confirmed persistent Windows Update fault.

**Documentation:** [07 — FS01 remote Event Log RPC incident](Troubleshooting/07-FS01-Remote-Event-Log-RPC.md).

**Next automation step:** Only after developing and testing a reusable query routine should Event Log collection be integrated into `Test-ServerHealth.ps1`. **No change to that script was made in Session 6.**
