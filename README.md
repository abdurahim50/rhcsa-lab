# RHCSA Lab

A self-contained, offline practice environment and study course for the **Red Hat Certified System Administrator (EX200)** exam on **RHEL 10**.

Two virtual machines on an isolated network, built to behave like the real exam: no internet, no DNS, no documentation except what ships with the product, and every configuration has to survive a reboot.

- **Build it:** [`docs/lab-build-guide.md`](docs/lab-build-guide.md)
- **Study it:** [`docs/study-plan.md`](docs/study-plan.md)
- **When it breaks:** [`docs/troubleshooting.md`](docs/troubleshooting.md)
- **Coverage against the official objectives:** [`docs/exam-objectives-map.md`](docs/exam-objectives-map.md)

## Why this exists

The RHCSA is performance-based. You are dropped onto a machine with no internet and three hours to make real changes that still work after a reboot. Reading about `lvextend` does not prepare you for that; doing it against a disk that fights back does.

This repository is the environment plus the course that runs on it:

- An **offline lab** that forces the exam's constraints on you. No internet means `man`, `dnf provides`, and `/usr/share/doc` are the only references, exactly as on exam day.
- A **four-layer course per objective**: notes that teach the concepts from first principles, labs that walk you through the commands, timed exam tasks, and a grading script that checks your work the way a grader would.
- **Reproducible builds.** Kickstart files build both nodes unattended; a remediation script brings a hand-installed node up to the same state.

## Lab topology

```
                 host-only network: 172.25.250.0/24, DHCP off, no gateway
                 (name resolution is /etc/hosts only, as on the exam)
  ┌───────────────────────────────┐        ┌───────────────────────────────┐
  │  node1.lab.example.com        │        │  node2.lab.example.com        │
  │  172.25.250.10                │◄──────►│  172.25.250.11                │
  │                               │        │                               │
  │  THE EXAM MACHINE             │        │  SERVICES HOST                │
  │  minimal install, no extras   │        │  httpd    DVD package repo    │
  │                               │        │  nfs-server  exports          │
  │  sda 20G  OS (LVM, ~6G free)  │        │  chronyd  time source         │
  │  sdb 10G  raw                 │        │                               │
  │  sdc  5G  raw                 │        │  sda 20G  OS                  │
  │  sdd  5G  raw                 │        │  sdb 10G  spare               │
  └───────────────────────────────┘        └───────────────────────────────┘
         VMware Paravirtual (PVSCSI) controller, UEFI, Secure Boot off
```

**node1 is deliberately under-equipped.** `nfs-utils`, `autofs`, and `policycoreutils-python-utils` are not installed. Installing a missing tool from an offline repository is itself a graded exam skill, so the lab makes you do it.

**~6 GB is left free in the root volume group** on purpose, so `lvextend -r` can be practised against a live root filesystem.

## Repository layout

```
.
├── docs/
│   ├── lab-build-guide.md        Build both VMs from scratch, start to finish
│   ├── study-plan.md             What to read and do, in what order
│   ├── exam-objectives-map.md    Every official objective, mapped to a section
│   └── troubleshooting.md        Problems hit during the build, and the fixes
├── lab/
│   ├── kickstart/                Unattended installs for node1 and node2
│   │   ├── ks-node1.cfg
│   │   └── ks-node2.cfg
│   └── scripts/
│       ├── lab-bringup.sh        Bring a hand-installed node to kickstart state
│       ├── node2-services.sh     Configure the repo, NFS exports, and chrony
│       └── lab-check.sh          Health and persistence check, run after reboot
├── sections/
│   ├── 01-essential-tools/       NOTES.md, LABS.md, EXAM.md, grade.sh
│   │   └── lib/checks.sh         Verification helpers the grader shares with the tests
│   ├── 02-manage-software/
│   ├── ...
│   └── 11-mock-exam/             Full three-hour mixed exam
└── tests/
    ├── test-checks.sh            Offline tests for the grader's logic
    └── check-links.sh            Every relative Markdown link resolves
```

`tests/` runs anywhere bash and tar exist, with no RHEL, no root, and no VMs. It is there
because a broken grader is invisible: a check that can never pass looks exactly like a
learner who got the task wrong. CI runs it, plus shellcheck, `ksvalidator` on the
kickstart files, and a scan for committed keys.

**Only section 01 is written.** It holds the four files below. Sections 02 to 11 are
scaffolds right now: each is a README listing that section's real objectives and the VMs
its labs will need, and each will grow the same four files as it is built.

| File | What it is |
|---|---|
| `NOTES.md` | Teaching. Concepts from first principles, with what goes wrong and how it is tested |
| `LABS.md` | Guided practice. Commands to type, with the output you should see |
| `EXAM.md` | Timed tasks under exam conditions. No hints |
| `grade.sh` | Read-only grader. Checks each task and explains why it passed or failed |

## Progress

| # | Section | Objectives | Status |
|---|---|---|---|
| 01 | Understand and use essential tools | 11 | Complete |
| 02 | Manage software | 4 | Not started |
| 03 | Create simple shell scripts | 4 | Not started |
| 04 | Operate running systems | 10 | Not started |
| 05 | Configure local storage | 6 | Not started |
| 06 | Create and configure file systems | 5 | Not started |
| 07 | Deploy, configure, and maintain systems | 6 | Not started |
| 08 | Manage basic networking | 4 | Not started |
| 09 | Manage users and groups | 4 | Not started |
| 10 | Manage security | 8 | Not started |
| 11 | Full mock exam | all | Not started |

## Quick start

You need VMware Workstation or Fusion, 60 GB of free disk (120 GB is comfortable once you keep snapshots), 8 GB of RAM, and a RHEL 10 ISO. A [Red Hat Developer Subscription](https://developers.redhat.com/products/rhel/download) provides the ISO at no cost for personal use. The [build guide](docs/lab-build-guide.md#host-requirements) breaks down where the disk space actually goes.

1. Follow [`docs/lab-build-guide.md`](docs/lab-build-guide.md) to create the host-only network and both VMs.
2. Install with the kickstart files for an unattended build, or install by hand and then run `lab-bringup.sh`:

   ```bash
   # on each node, as root
   ./lab-bringup.sh node1     # or: ./lab-bringup.sh node2
   ```

3. Configure the services host, once:

   ```bash
   # on node2 only, as root
   ./node2-services.sh
   ```

4. Reboot node1 and confirm everything came back:

   ```bash
   # on node1, as root
   ./lab-check.sh
   ```

5. **Snapshot both VMs** before you start studying. Every section's exam assumes a clean machine, and some tasks are easier to undo by reverting than by hand.

## How to study

Read one part of `NOTES.md`, then do the lab that matches it, while the concept is still fresh. Do the timed exam on a later day, after a snapshot revert.

| Day | What |
|---|---|
| 1 | Read notes, type the Try it blocks, work the matching labs |
| 2 or 3 | Revert node1 to the clean snapshot, then the timed exam, then `grade.sh` |
| then | Next section |

The full reasoning behind that rhythm, including which labs need node2 powered on, is in [`docs/study-plan.md`](docs/study-plan.md).

## A note on the credentials in this repository

The kickstart files contain **deliberately weak, publicly known passwords** (`root:redhat`, `student:student`). That is intentional and safe here: these build throwaway VMs on an isolated host-only network with no route to the internet, and the real exam uses similarly disposable credentials.

Do not reuse these files, or these passwords, for anything reachable from a real network. If you adapt this lab for any machine that is not disposable, replace `rootpw --plaintext` with a hashed password:

```bash
python3 -c 'import crypt; print(crypt.crypt("YOUR-PASSWORD", crypt.mksalt(crypt.METHOD_SHA512)))'
# then in the kickstart file:
#   rootpw --iscrypted $6$...
```

No real credentials, keys, or host-specific data belong in this repository.

## Scope

This covers the RHCSA (EX200) objectives as published by Red Hat, reproduced in [`docs/exam-objectives-map.md`](docs/exam-objectives-map.md). Red Hat can change the objectives at any time, so check the [official page](https://www.redhat.com/en/services/training/ex200-red-hat-certified-system-administrator-rhcsa-exam/objectives) before relying on this list.

Not affiliated with, endorsed by, or sponsored by Red Hat, Inc. Red Hat, RHEL, and RHCSA are trademarks of Red Hat, Inc. This repository contains no Red Hat course material and no exam content; everything here is written from the public objectives list.

## License

[MIT](LICENSE). Use it, fork it, adapt it for your own exam prep.
