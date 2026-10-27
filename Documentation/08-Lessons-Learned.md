# Lessons Learned

- **DNS is a dependency to verify early.** An IP connection can work while access by hostname fails. Inspecting the record and testing directly against DC01 makes the fault easier to isolate.
- **Secure dynamic DNS updates depend on record permissions.** A manually created DNS record may resolve correctly while preventing the associated computer account from updating it. Event ID 8018, effective permission checks and DNS record ownership helped identify and resolve the issue.
- **Configured policy and effective policy are different evidence.** A setting visible in a GPO needs confirmation on the target computer and in the correct user or computer context.
- **The Winning GPO provides valuable troubleshooting evidence.** Group Policy Results can identify which GPO Windows reports as responsible for a configured setting, providing stronger evidence than simply checking that a GPO appears in the applied list.
- **File access involves several controls.** Domain group membership, share permissions and NTFS permissions all contribute to the final result. Testing as each user is essential.
- **Auditing requires both policy and an object auditing entry.** Audit policy configuration and SACL entries serve different purposes, and both are relevant when validating file access events.
- **Document workarounds and resolutions honestly.** Temporary fixes can restore functionality, but investigating their underlying causes provides stronger evidence of troubleshooting ability. Verification results should be recorded accurately without claiming tests that were not performed.
- **PowerShell can reduce repetitive administration.** Using functions, variables, loops and conditional logic allows routine checks to be reused across multiple servers.
- **Connectivity and service health are separate checks.** A server responding to ICMP does not necessarily mean its services are functioning correctly.
- **Automation should be developed incrementally.** Starting with simple checks and gradually introducing error handling, reporting and more comprehensive validation helps build reliable scripts.

## Next steps

- Capture additional before-and-after access tests and policy reports for repeatable validation.
- Record exact OU names, group memberships, permission entries and policy values alongside future build automation.
- Continue PowerShell Automation Session 2 with error handling, expanded service checks and structured reporting.
- Capture supporting screenshots of PowerShell automation execution.
- Expand infrastructure monitoring, troubleshooting and operational validation scenarios.
- Continue developing Windows Server and Microsoft Azure infrastructure engineering skills.
