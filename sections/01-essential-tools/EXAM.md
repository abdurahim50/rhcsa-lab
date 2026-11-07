# RHCSA · Section 1 — Exam-Style Practice Tasks

**Time limit: 45 minutes. Start a timer.**

## Exam conditions — enforce these on yourself

- No internet. No notes. No AI. No previous chats.
- `man`, `info`, `--help`, and `/usr/share/doc` only.
- Work on **node1** as `root`, at the VMware console or over SSH.
- Reboot when you finish and *before* grading. Anything that doesn't survive a reboot
  scores zero, exactly as on the real exam.
- Grade with `./grade.sh`, copied onto node1 as a folder (it needs `lib/checks.sh` beside it). Do not read the grading script first; it gives answers away.

If you finish early, verify everything again. Nobody ever lost points for checking twice.

---

### Task 1
Create the directory `/opt/reports`. It must be owned by user `root` and group `wheel`,
and be configured so that any file created inside it automatically belongs to the group
`wheel`. Group members must be able to create and delete files in it. Others may read
and traverse but not write.

### Task 2
Create the directory `/opt/reports/etc-copies` and copy `/etc/passwd`, `/etc/group`,
and `/etc/shadow` into it. The copies must retain their original ownership, permissions,
and timestamps.

### Task 3
Create the file `/opt/reports/nologin.txt` containing every line of `/etc/passwd`
belonging to an account whose login shell is exactly `/sbin/nologin`. Full lines, no
other content.

### Task 4
Create the file `/opt/reports/usercount.txt` containing a single line holding only the
number of accounts in `/etc/passwd` with a UID of 1000 or greater. No label, no
whitespace beyond a trailing newline.

### Task 5
Create the file `/opt/reports/bashusers.txt` containing only the **usernames** of
accounts whose login shell is `/bin/bash`, one per line, sorted alphabetically.

### Task 6
Create a gzip-compressed tar archive at `/root/sysconfig.tar.gz` containing the
directory `/etc/sysconfig` and everything below it.

### Task 7
Create a bzip2-compressed tar archive at `/root/sshconf.tar.bz2` containing `/etc/ssh`,
preserving SELinux contexts and extended attributes.

### Task 8
In `/opt/reports`, create a **hard link** named `hosts.hard` and a **symbolic link**
named `hosts.soft`, both referring to `/etc/hosts`.

### Task 9
Create the file `/opt/reports/secret.txt` containing exactly the single line
`classified`. It must be owned by `root:root` and readable and writable only by its
owner.

### Task 10
Run a command that lists both `/etc` and `/nosuchdir`, sending normal output to
`/opt/reports/out.txt` and error output to `/opt/reports/err.txt`, as two separate
files.

### Task 11
Run the same listing again, this time capturing **both** normal and error output
together into `/opt/reports/both.txt`.

### Task 12
Determine which manual page section documents the **format of the `/etc/passwd` file**
(as opposed to the `passwd` command). Write only that section number into
`/opt/reports/mansection.txt`.

### Task 13
Configure key-based SSH authentication so that `root` on node1 can log in to
`root@node2` without being prompted for a password or a passphrase.

### Task 14
Securely copy `/root/sysconfig.tar.gz` from node1 to `/tmp/` on node2.

### Task 15
Create the directory `/opt/reports/archive` and, using a single `tar` command, extract
the contents of `/root/sysconfig.tar.gz` into it.

---

## When the timer stops

```bash
reboot
```

Then log back in and run:

```bash
cd /root/01-essential-tools && ./grade.sh
```

## Scoring

The real exam needs **210 of 300** to pass — 70%. Here that's **11 of 15**.

| Score | Read this as |
|---|---|
| 14–15 | Section 1 is solid. Move on. |
| 11–13 | Passing, but review what you missed and re-run in three days. |
| 8–10 | Redo the guided labs for the failed areas, then retake. |
| 0–7 | Reread the notes end to end and work every lab before retaking. |

Whatever you score, **read the grader's explanation for each failure**. A task you got
right by accident is a task you'll get wrong under pressure.
