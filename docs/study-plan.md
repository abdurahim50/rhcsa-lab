# Study plan

How to use this repository, in what order, and why.

## The shape of a section

Every section has four files, and they are meant to be used in this order:

1. **`NOTES.md`** teaches the concept. Read it with a terminal open and type the `Try it` blocks as you go. They are written to be safe to run on node1 as root.
2. **`LABS.md`** walks you through the commands with the output you should expect. Guided, with the answer on the page.
3. **`EXAM.md`** gives you the same skills as timed tasks with no hints. This is the one that tells you whether you actually know it.
4. **`grade.sh`** checks your work and explains each pass and fail. Read-only; it never changes your system.

## Read a part, then do its lab

Do not read all of `NOTES.md` and then do all of `LABS.md`. The notes for one section run to a few hundred pages of terminal work, and the early parts will have gone cold by the time you reach the lab that uses them.

Read one part, type its `Try it` blocks, answer its self-check, then do the lab that matches it. Then the next part.

### Section 01 pairing

| Read | Then do |
|---|---|
| Part 0, The ground you are standing on | (no lab, this is background) |
| Part 1, Talking to the shell | Lab 1.1 |
| Part 2, Redirection and pipes | Lab 1.2 |
| Part 3, Searching and analyzing text | Lab 1.3 |
| Part 4, Working with files and directories | Lab 1.4 |
| Part 5, Links and inodes | Lab 1.5 |
| Part 6, Permissions | Lab 1.6 |
| Part 7, Creating and editing text files | `vimtutor` (there is no lab for vim) |
| Part 8, Archiving and compression | Lab 1.7 |
| Part 10, Remote access with SSH | Lab 1.8 |
| Part 9, Logging in and switching users | Lab 1.9 |
| Part 11, Finding documentation | Lab 1.10, then the Cleanup section at the end of the labs |
| Part 12, Reasoning through an unfamiliar task | Read this on exam day, before you start |

**Parts 9 and 10 are swapped on purpose.** Lab 1.8 uses the archive you create in Lab 1.7, so the labs have to run in their own numerical order even though the notes introduce SSH after switching users.

## Before you start a session

- **Power on node2 for Lab 1.8 and anything involving SSH, NFS, the package repository, or time sync.** Everything else in section 01 runs on node1 alone.
- **Run each part's cleanup block before its lab.** Parts 6 and 9 create users named `alice`, `bob`, and `carol`, and the labs reuse those names. Leftovers from the notes will make a lab behave differently from what the page says.
- **Type the commands. Do not paste them.** The exam is three hours of typing under pressure; the muscle memory is part of what you are building.

## The weekly rhythm

| Day | What |
|---|---|
| 1 | Read the notes part by part, type the `Try it` blocks, work the matching labs |
| 2 or 3 | Revert node1 to the clean snapshot, then the timed exam, then `grade.sh` |
| Then | Next section |

A gap of a day or two between the labs and the exam is deliberate. If you sit the exam immediately after the labs, you are testing your short-term memory rather than whether the skill stuck.

## Revert to a snapshot before every exam

Take a snapshot of both VMs as soon as the lab build verifies, and name it something like `clean-build`.

Before each section's `EXAM.md`, revert node1 to that snapshot. Two reasons:

- **The labs leave the answers lying around.** Section 01's exam has a key-based SSH task; if Lab 1.8 already set that key up, the task passes without you doing anything, and you learn nothing.
- **Exam machines are clean.** Starting from a half-configured system is not the test you are preparing for.

## Sitting the exam sections

- Set a timer. The time budget is at the top of each `EXAM.md`.
- No internet, no notes, no `NOTES.md` open in another window. `man`, `info`, and `/usr/share/doc` only. That is exactly what you get on exam day.
- **Reboot before you grade.** Red Hat grades after a reboot, so a task that only works until you reboot scores zero. Reboot node1, then run `grade.sh`.
- Read the grader's explanations for everything you got wrong, then redo those tasks by hand before moving on.

## When you finish all ten sections

Section 11 is a full three-hour mock exam that mixes tasks from every objective area, graded after a reboot. Sit it on a clean snapshot. The real exam does not tell you which objective a task belongs to, and mixed practice is the only way to rehearse that.

## If something does not behave the way a file says it should

Check [`troubleshooting.md`](troubleshooting.md) first. The problems in there cost real hours during the build, and a few of them look like a broken command when they are actually an environment quirk.
