# CLIENT01 DHCP lease recovery and Finance share access — Follow-up (3 November 2026)

**Symptom:** CLIENT01, unused for some time, received APIPA address `169.254.55.31` and could not authenticate a newly created domain user. Its Ethernet adapter was Up and DHCP enabled; all lab VMs were connected to the existing NAT-Switch.

**Findings:** DC01's DHCP Server service was Running, DHCP scope `192.168.100.100–192.168.100.200` was Active with 101 free addresses, and DHCP binding showed `True`. CLIENT01 could ping DC01 at `192.168.100.2` after temporarily assigning `192.168.100.50/24`, confirming basic IP connectivity on the lab network. The temporary address was removed and DHCP re-enabled; DHCP renewal had still timed out.

**Recovery:** Restarted the DHCP Server service on DC01 and ran `ipconfig /renew` on CLIENT01. The user confirmed that DHCP address allocation resumed successfully. **The precise underlying reason DHCP stopped responding was not established**; service restart restored the observed functionality.

**End-to-end access test:** Signed in to CLIENT01 successfully as Emily Carter (`ecarter`) and confirmed access to `\\FS01\Finance`. This completes the client-side validation previously pending after adding Emily to `SG-Finance-Staff`.

**Lessons:** Target troubleshooting at the actual service failure, use confirmed findings to avoid repeated checks, and distinguish service recovery from a proven root cause. Restarting DHCP can interrupt clients requesting leases and should be assessed more cautiously outside an isolated lab.

---

[Back to troubleshooting index](../05-Troubleshooting.md)
