# Hyper-V Networking

## Implementation notes and commands

Much of the lab was configured through Windows management consoles. The commands below are representative implementation and inspection examples for this topology; they are not a transcript or an unattended rebuild script. Switch names, interface aliases, share paths and policy values must match the actual lab.

## Hyper-V networking

On the Hyper-V host, the following illustrates creating an internal switch, assigning the gateway address and adding NAT. Use only when equivalent objects do not already exist.

```powershell
# Run in elevated PowerShell on the Hyper-V host.
# LabNAT is an example switch/NAT name.

New-VMSwitch -Name 'LabNAT' -SwitchType Internal

New-NetIPAddress -InterfaceAlias 'vEthernet (LabNAT)' `
    -IPAddress 192.168.100.1 -PrefixLength 24

New-NetNat -Name 'LabNAT' `
    -InternalIPInterfaceAddressPrefix '192.168.100.0/24'

Get-VMSwitch
Get-NetNat
```

Connect the three virtual machines to the lab switch. DC01 and FS01 use their static addresses; CLIENT01 obtains its configuration from DHCP. Domain members use DC01 for internal DNS resolution.
