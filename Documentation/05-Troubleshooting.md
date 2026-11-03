# Troubleshooting and Incident Investigations

This index links to individual, evidence-based troubleshooting write-ups from the Windows Server 2025 Hyper-V lab. Each case documents the issue or scenario, investigation, actions taken, observed outcomes and limitations. Cases are kept separate so this page remains easy to navigate as the portfolio grows.

## Case studies

| Date | Incident / exercise | Outcome |
| --- | --- | --- |
| 27 October 2026 | [01 — FS01 secure dynamic DNS registration](Troubleshooting/01-FS01-Secure-DNS-Registration.md) | Resolved; automatic DNS registration restored |
| 27 October 2026 | [02 — FS01 file auditing GPO not applying](Troubleshooting/02-FS01-Auditing-GPO.md) | Resolved; correct OU scope and winning GPO verified |
| 30 October 2026 | [03 — AD onboarding password-policy failure](Troubleshooting/03-AD-User-Password-Policy.md) | Account state repaired; user sign-in not separately tested |
| 30 October–3 November 2026 | [04 — Finance share group membership](Troubleshooting/04-Finance-Share-Group-Membership.md) | Group membership corrected; Emily's share access verified on CLIENT01 later |
| 3 November 2026 | [05 — CLIENT01 DHCP lease recovery](Troubleshooting/05-CLIENT01-DHCP-Recovery.md) | DHCP functionality restored; underlying cause not established |
| 3 November 2026 | [06 — CLIENT01 DNS controlled exercise](Troubleshooting/06-CLIENT01-DNS-Controlled-Exercise.md) | Inconclusive: network status changed, but the intended share failure did not occur |

## How future cases are documented

New incidents go into separate numbered Markdown files in [the Troubleshooting folder](Troubleshooting), then receive a single entry in the index above. Reports distinguish **simulated incidents** from genuine observed failures and do not claim resolution without supporting validation.

See [Validation Evidence](07-Validation-Evidence.md) for related tests and screenshots.
