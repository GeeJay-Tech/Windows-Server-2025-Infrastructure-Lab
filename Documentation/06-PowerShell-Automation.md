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

The saved version includes function calls for DC01 and FS01 so both servers can be checked when the script executes.

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

These results were observed during the interactive PowerShell training session. The saved script is available for future execution and validation.

### Session 1 — Limitations

The current script is an introductory automation exercise rather than a complete production monitoring solution.

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

### Session 2 — Planned Improvements

- Introduce `try` and `catch` error handling.
- Improve handling of unreachable servers and remote service failures.
- Check additional Windows services.
- Develop structured output using PowerShell objects.
- Generate reusable reports.
- Continue developing automation relevant to infrastructure engineering and systems administration.
