# Exam objectives map

Every published RHCSA (EX200) objective, mapped to the section of this course that covers it.

Red Hat revises the objectives without notice. Check the [official objectives page](https://www.redhat.com/en/services/training/ex200-red-hat-certified-system-administrator-rhcsa-exam/objectives) before you rely on this list.

**Status key:** Complete, In progress, Not started.

## Exam format

- Hands-on and performance-based. You perform real tasks on real systems; there are no multiple-choice questions.
- One section, **three hours**.
- **No internet access.** No notes, no books, no printed or electronic material of your own.
- The documentation that ships with the product is available: `man`, `info`, and `/usr/share/doc`.
- **Configurations must persist after a reboot without intervention.** A task that works until you reboot scores zero.

The lab in this repository reproduces all of these constraints except the clock, which is yours to impose.

---

## 1. Understand and use essential tools

**Section:** [`01-essential-tools`](../sections/01-essential-tools) · **Status:** Complete

| Objective | Covered in |
|---|---|
| Access a shell prompt and issue commands with correct syntax | Parts 0, 1 |
| Use input-output redirection (`>`, `>>`, `\|`, `2>`, etc.) | Part 2 |
| Use `grep` and regular expressions to analyze text | Part 3 |
| Access remote systems using SSH | Part 10 |
| Log in and switch users in multiuser targets | Part 9 |
| Archive, compress, unpack, and uncompress files using `tar`, `gzip`, and `bzip2` | Part 8 |
| Create and edit text files | Part 7 |
| Create, delete, copy, and move files and directories | Part 4 |
| Create hard and soft links | Part 5 |
| List, set, and change standard ugo/rwx permissions | Part 6 |
| Locate, read, and use system documentation including `man`, `info`, and files in `/usr/share/doc` | Part 11 |

## 2. Manage software

**Section:** [`02-manage-software`](../sections/02-manage-software) · **Status:** Not started

| Objective |
|---|
| Configure access to RPM repositories |
| Install and remove RPM software packages |
| Configure access to Flatpak repositories |
| Install and remove Flatpak software packages |

## 3. Create simple shell scripts

**Section:** [`03-shell-scripts`](../sections/03-shell-scripts) · **Status:** Not started

| Objective |
|---|
| Conditionally execute code (use of: `if`, `test`, `[]`, etc.) |
| Use looping constructs (`for`, etc.) to process file and command line input |
| Process script inputs (`$1`, `$2`, etc.) |
| Process output of shell commands within a script |

## 4. Operate running systems

**Section:** [`04-operate-running-systems`](../sections/04-operate-running-systems) · **Status:** Not started

| Objective |
|---|
| Boot, reboot, and shut down a system normally |
| Boot systems into different targets manually |
| Interrupt the boot process in order to gain access to a system |
| Identify CPU/memory intensive processes and kill processes |
| Adjust process scheduling |
| Manage tuning profiles |
| Locate and interpret system log files and journals |
| Preserve system journals |
| Start, stop, and check the status of network services |
| Securely transfer files between systems |

## 5. Configure local storage

**Section:** [`05-local-storage`](../sections/05-local-storage) · **Status:** Not started

| Objective |
|---|
| List, create, delete partitions on GPT disks |
| Create and remove physical volumes |
| Assign physical volumes to volume groups |
| Create and delete logical volumes |
| Configure systems to mount file systems at boot by universally unique ID (UUID) or label |
| Add new partitions and logical volumes, and swap, to a system non-destructively |

## 6. Create and configure file systems

**Section:** [`06-file-systems`](../sections/06-file-systems) · **Status:** Not started

| Objective |
|---|
| Create, mount, unmount, and use VFAT, ext4, and xfs file systems |
| Mount and unmount network file systems using NFS |
| Configure autofs |
| Extend existing logical volumes |
| Diagnose and correct file permission problems |

## 7. Deploy, configure, and maintain systems

**Section:** [`07-deploy-configure-maintain`](../sections/07-deploy-configure-maintain) · **Status:** Not started

| Objective |
|---|
| Schedule tasks using `at`, `cron`, and systemd timer units |
| Start and stop services and configure services to start automatically at boot |
| Configure systems to boot into a specific target automatically |
| Configure time service clients |
| Install and update software packages from Red Hat Content Delivery Network, a remote repository, or from the local file system |
| Modify the system bootloader |

## 8. Manage basic networking

**Section:** [`08-basic-networking`](../sections/08-basic-networking) · **Status:** Not started

| Objective |
|---|
| Configure IPv4 and IPv6 addresses |
| Configure hostname resolution |
| Configure network services to start automatically at boot |
| Restrict network access using `firewalld` and `firewall-cmd` |

## 9. Manage users and groups

**Section:** [`09-users-and-groups`](../sections/09-users-and-groups) · **Status:** Not started

| Objective |
|---|
| Create, delete, and modify local user accounts |
| Change passwords and adjust password aging for local user accounts |
| Create, delete, and modify local groups and group memberships |
| Configure privileged access |

## 10. Manage security

**Section:** [`10-manage-security`](../sections/10-manage-security) · **Status:** Not started

| Objective |
|---|
| Configure firewall settings using `firewall-cmd`/`firewalld` |
| Manage default file permissions |
| Configure key-based authentication for SSH |
| Set enforcing and permissive modes for SELinux |
| List and identify SELinux file and process context |
| Restore default file contexts |
| Manage SELinux port labels |
| Use boolean settings to modify system SELinux settings |

---

## Objectives that appear in more than one place

Red Hat groups the objectives by theme, but several skills are taught where they first become useful rather than where Red Hat files them. These are the overlaps worth knowing about:

| Skill | Red Hat files it under | First taught in | Finished in |
|---|---|---|---|
| Key-based SSH authentication | 10, Manage security | 01, Part 10 | 10 |
| Securely transferring files (`scp`, `sftp`, `rsync`) | 4, Operate running systems | 01, Part 10 | 04 |
| Default file permissions (`umask`) | 10, Manage security | 01, Part 6 | 10 |
| SELinux contexts on files | 10, Manage security | 01, Parts 4 and 6, as a preview only | 10 |
| `firewall-cmd` | 8 and 10, listed in both | 08 | 10 |
| Extending logical volumes | 6, Create and configure file systems | 05 | 06 |

## Counts

| Section | Objectives |
|---|---|
| 1. Understand and use essential tools | 11 |
| 2. Manage software | 4 |
| 3. Create simple shell scripts | 4 |
| 4. Operate running systems | 10 |
| 5. Configure local storage | 6 |
| 6. Create and configure file systems | 5 |
| 7. Deploy, configure, and maintain systems | 6 |
| 8. Manage basic networking | 4 |
| 9. Manage users and groups | 4 |
| 10. Manage security | 8 |
| **Total** | **62** |
