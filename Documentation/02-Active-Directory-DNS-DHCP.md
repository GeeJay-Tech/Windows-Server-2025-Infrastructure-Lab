# Active Directory, DNS and DHCP

## Domain and infrastructure services

On a fresh DC01, the core role installation and forest creation can be expressed as:

```powershell
Install-WindowsFeature AD-Domain-Services, DNS, DHCP -IncludeManagementTools

Install-ADDSForest -DomainName 'CTRL-TECH.net' -InstallDns
```

Forest creation prompts for the Directory Services Restore Mode password and requires a restart. DHCP authorisation, scope creation and scope options are separate configuration steps. The lab uses `.1` as the router and `.2` as the DNS server; the DHCP pool must exclude infrastructure addresses.

Inspect the configured services and directory structure on DC01:

```powershell
Get-ADDomain

Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName

Get-ADUser -Filter * |
    Select-Object Name, Enabled

Get-ADGroup -Filter * |
    Select-Object Name, GroupScope, GroupCategory

Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue
Get-ADDefaultDomainPasswordPolicy
```
