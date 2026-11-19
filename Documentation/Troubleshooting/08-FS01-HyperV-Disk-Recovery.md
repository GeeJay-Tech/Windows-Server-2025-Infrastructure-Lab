# 08 — FS01 Hyper-V Disk Attachment and Recovery

**Incident date:** 19 November 2026  
**Environment:** Windows Server 2025 lab, Hyper-V Generation 2 VMs, `CTRL-TECH.net` domain  
**Outcome:** Original FS01 Windows installation booted in a replacement VM; core services and connectivity restored. Finance share authorisation and full recovery validation remain incomplete.

## Incident

During a backup exercise, a new virtual disk (`FS01-Backup.vhdx`) was selected in place of the existing FS01 boot disk rather than being attached as an additional disk. FS01 then presented Windows installation media instead of booting its installed operating system. The original disk `D:\Virtual Disk\FS01.vhdx` remained present on the Hyper-V host.

An attempt to change the old VM's disk attachment failed with a rollback error referencing a missing `FS01-Backup_...avhdx` attachment. Hyper-V showed a registered standard checkpoint dated 17 November 2026, 17:55. The user reported that this checkpoint appeared after the backup-disk work and was not an intentional earlier recovery point.

## Observations and investigation

- Original VM `FS01` was **Off** and Generation 2.
- Host disk listing showed:
  - `D:\Virtual Disk\FS01.vhdx` (~2.94 GB file length);
  - `D:\Virtual Disk\FS01_6DB94425-A863-4586-BF42-8DEADDACF432.avhdx` (~2.29 GB);
  - `D:\Virtual Disk\CLIENT01\Virtual Hard Disks\FS01-Backup.vhdx` (~4 MB);
  - `D:\Virtual Disk\CLIENT01\Virtual Hard Disks\FS01-Backup_8FE9E4AE-5506-40AB-9381-1FB60C78A289.avhdx` (~4 MB).
- A `Convert-VHD` attempt against the FS01-named AVHDX failed with **0xC03A000E**, reporting a parent/differencing-disk identifier mismatch. This did **not** establish that the standalone original `FS01.vhdx` was corrupt.
- Because the checkpoint chain was inconsistent and the user's immediate priority was restoring the server, no checkpoint merge or forced identifier override was attempted.

## Recovery performed

1. Preserved the original FS01 VM and disk files.
2. Copied `D:\Virtual Disk\FS01.vhdx` to `D:\Virtual Disk\FS01-Recovered.vhdx`.
3. Created a new **Generation 2** Hyper-V VM (`FS01-Recovery`) using the copied existing virtual disk, without reinstalling Windows Server.
4. Booted the recovered installation and confirmed that its guest hostname was `FS01`.
5. Restored or checked the intended static networking: FS01 `192.168.100.3/24`, gateway `192.168.100.1`, DNS/DC01 `192.168.100.2`.
6. Continued with a host-level Hyper-V export of the recovered VM; the user confirmed **export completed**. The exported files and VM compatibility have since been checked successfully; a booted restore test remains outstanding.

## Validation and limitations

| Test | Reported outcome |
| --- | --- |
| Recovered Windows Server installation starts | **Pass** — guest boots without reinstall |
| Guest hostname | **Pass** — `FS01` |
| FS01 `LanmanServer` service | **Pass** — Running |
| FS01 `WinRM` service | **Pass** — Running |
| FS01 → DC01 network connectivity | **Pass** — user confirmed communication |
| DC01 access to `\\FS01\Finance` | **Permission denied** — network/share path responded, but the test account could not access the folder |
| Finance share ACL | An inspected NTFS access entry showed `Allow`, but the account/group and effective permissions were not fully validated |
| Authorised Finance user access | **Not retested** after recovery; password unavailable, CLIENT01 kept off to conserve laptop RAM |
| Domain secure channel (`Test-ComputerSecureChannel`) | **Not confirmed** |
| Hyper-V export | **Completed**, per user | 
| Export file inspection | **Pass** — user ran recursive file listing without errors and confirmed completion; individual file details were not supplied |
| Export compatibility (`Compare-VM`) | **Pass (command completed without errors)** — user confirmed; detailed compatibility output not supplied |
| Booted restore test | **Not performed** — avoided running a duplicate FS01 on the same lab network |

**Do not interpret an unauthorised account's `Test-Path` result of `False` with `Access is denied` as proof that the SMB share is missing.** It shows the attempted access was refused. An authorised user/NTFS/share-permission test remains outstanding.

## Lessons learned

- Before adding a backup disk, confirm the existing OS disk remains attached and use an unused controller location for any additional disk.
- Hyper-V checkpoints/differencing disks require their correct parent identity; do not merge or override identifiers without validating the chain.
- An intact original VHDX can sometimes be booted through a fresh VM configuration, avoiding OS reinstallation.
- Prefer a non-destructive copy of the source VHDX and preserve all original disks until recovery is fully verified.
- For subsequent backup training, use Hyper-V **Export-VM** rather than altering the running server's boot-disk attachment.
- A completed export must still be checked for its configuration/disk files, and restore testing is needed to establish recoverability.

## Remaining follow-up

- Export file listing and `Compare-VM` were completed without reported errors on 19 November 2026. Inspect exact file details if needed before relying on this as a disaster-recovery backup.
- When resources allow, test an isolated restore/import **without connecting a duplicate FS01 to the production lab network**.
- Confirm `Test-ComputerSecureChannel` and test `\\FS01\Finance` using an authorised domain user.
- Retain original VHDX/AVHDX files until recovery and backup are validated; only then consider cleanup of old VM registration and stale files.
