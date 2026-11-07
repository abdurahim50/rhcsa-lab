# Section 01: Understand and use essential tools

**Status:** Complete · **Objectives covered:** 11 · **Exam time budget:** 45 minutes for 15 tasks

The foundation section. Everything in sections 02 to 10 assumes you can navigate a shell, redirect output, read a man page, and fix a permission problem without thinking about it.

## Files

| File | Use it for |
|---|---|
| [`NOTES.md`](NOTES.md) | Learning. 12 parts, from "what is a shell" to reasoning through an unfamiliar task |
| [`LABS.md`](LABS.md) | Guided practice. Labs 1.1 to 1.10, with the output you should see |
| [`EXAM.md`](EXAM.md) | 15 timed tasks under exam conditions. 11 of 15 is a pass |
| [`grade.sh`](grade.sh) | Grades the 15 tasks and explains every pass and fail. Read-only |

## What the notes cover

| Part | Topic |
|---|---|
| 0 | The ground you are standing on: kernel and userspace, users and groups, the filesystem tree, processes |
| 1 | Talking to the shell: how the shell rewrites your command line before running it |
| 2 | Redirection and pipes: file descriptors, `>`, `2>&1`, heredocs, and `tee` in full |
| 3 | Searching and analyzing text: `grep`, regular expressions from zero, thinking in fields |
| 4 | Working with files and directories: `ls -l` anatomy, `cp`, `mv`, `rm`, `find` |
| 5 | Links and inodes: why a hard link is not a copy and a symlink is not a file |
| 6 | Permissions: ugo/rwx, first match wins, `umask`, SUID, SGID, sticky |
| 7 | Creating and editing text files: enough `vim` to survive the exam |
| 8 | Archiving and compression: `tar`, `gzip`, `bzip2`, and what the flags actually mean |
| 9 | Logging in and switching users: `su`, `su -`, `sudo`, login versus non-login shells |
| 10 | Remote access with SSH: host keys, key-based authentication, `scp` and `sftp` |
| 11 | Finding documentation: `man` sections, `apropos`, `info`, `/usr/share/doc`, `dnf provides` |
| 12 | Reasoning through an unfamiliar task: the method to use when you do not know the command |

Each part ends with a self-check. The answers are in Appendix B; a compact command reference is in Appendix A.

## Running the section

Read a part, type its `Try it` blocks, answer the self-check, then do the matching lab. The pairing table is in [`../../docs/study-plan.md`](../../docs/study-plan.md).

**node2 must be powered on for Lab 1.8** (SSH). Everything else runs on node1 alone.

**Revert node1 to a clean snapshot before the exam.** Lab 1.8 sets up the SSH key that exam task 13 asks for, so an un-reverted machine passes that task without you doing anything.

## Grading

```bash
# on node1, as root, AFTER a reboot
./grade.sh
```

The grader is read-only: it inspects, it never fixes. Rebooting first matters, because Red Hat grades after a reboot and a task that does not persist scores zero.

| Score | Meaning |
|---|---|
| 11 to 15 | Pass. Read the explanations for anything you missed, then move to section 02 |
| 8 to 10 | Close. Redo the failed tasks by hand, then re-sit the whole exam on a fresh snapshot |
| 0 to 7 | Go back to the notes for the parts those tasks came from |
