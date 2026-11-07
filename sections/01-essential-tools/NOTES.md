# RHCSA Section 1: Understand and Use Essential Tools

### Teaching notes, beginner-first edition, for RHEL 10

---

## How to use these notes

These notes teach. They are not a cheat sheet. The goal is that when you meet an RHCSA task you have never seen before, you can work out what it is asking and which command solves it, instead of trying to recall a memorized line.

- **Read in order.** Every part builds on the parts before it. Nothing is used before it is explained.
- **Keep node1 open beside these notes.** Every *Try it* block is safe to run on node1 as `root` unless it says otherwise. Type the commands. Reading about Linux without typing teaches very little.
- **Do the self-check at the end of each part** before moving on. Answers are in Appendix B.
- **Appendix A is a compact reference.** Use it for quick lookup once you understand a topic, not as a replacement for the explanations.

### Contents

| Part | Topic | Exam objective |
|---|---|---|
| 0 | The ground you are standing on | foundation for everything |
| 1 | Talking to the shell | Access a shell prompt and issue commands with correct syntax |
| 2 | Redirection and pipes | Use input-output redirection |
| 3 | Searching and analyzing text | Use grep and regular expressions to analyze text |
| 4 | Working with files and directories | Create, delete, copy, and move files and directories |
| 5 | Links and inodes | Create hard and soft links |
| 6 | Permissions | List, set, and change standard ugo/rwx permissions |
| 7 | Creating and editing text files | Create and edit text files |
| 8 | Archiving and compression | Archive, compress, unpack, and uncompress files |
| 9 | Logging in and switching users | Log in and switch users in multiuser targets |
| 10 | Remote access with SSH | Access remote systems using SSH; securely transfer files |
| 11 | Finding documentation | Locate, read, and use system documentation |
| 12 | Reasoning through an unfamiliar task | how to turn any task into commands |
| A | Compact reference | lookup tables |
| B | Self-check answers | |

### The questions every topic answers

| Heading | What it gives you |
|---|---|
| What it is | a plain-language definition |
| Why it exists | the problem it solves |
| How it works | the mental model to reason with |
| Anatomy | what every part of the command means |
| Try it | commands to run and what you should see |
| Verify | how to prove it worked |
| What goes wrong | the mistakes people actually make |
| How RHCSA tests it | how the exam phrases tasks on this topic |

Smaller topics fold some of these together, but the questions are always answered.

### Conventions

- Commands in code blocks are shown **without** a prompt, so you can type them exactly as written.
- Text after `#` in a code block is a **comment**. The shell ignores everything after `#`, so typing it does no harm.
- `<something>` means "put your own value here". Do not type the angle brackets.
- Output described as "something like" will differ in details such as dates, sizes, and counts.

Before starting, create a scratch area. The Try it blocks use it:

```bash
mkdir -p /root/practice
cd /root/practice
```

When you finish all the parts, remove it with `rm -rf /root/practice`.

---

# Part 0: The ground you are standing on

Before commands make sense, you need a picture of what you are talking to. This part has no exam objective of its own, but every objective depends on it.

## 0.1 What Linux actually is

**What it is.** Strictly speaking, *Linux* is the **kernel**: the core program that loads when the machine boots and runs until it shuts down. The kernel controls the hardware (CPU, memory, disks, network cards) and decides which programs run and what each one is allowed to touch.

Everything else you use (the shell, `ls`, `vim`, the SSH server) is an ordinary program running *on top of* the kernel. Together those programs are called **userspace**. A **distribution** such as Red Hat Enterprise Linux (RHEL) packages the kernel with thousands of userspace programs that have been tested together, plus a package manager for installing more.

**Why it matters to you.** When a command fails with `Permission denied`, it is usually the kernel refusing a request because a security rule says no. Knowing *who* is refusing tells you *where* to look.

**How it works.** A useful picture of the layers:

```
you
 |   keystrokes
terminal        the window or screen that shows text
 |
shell           reads your command line and starts programs
 |
programs        ls, cp, tar, ssh ... (userspace)
 |   requests: "open this file", "send this packet"
kernel          checks permissions, talks to hardware
 |
hardware
```

## 0.2 Terminal, shell, and prompt

**What they are.**

- The **terminal** is whatever displays text and sends your keystrokes: the VMware console window, or an SSH session.
- The **shell** is the program that reads the line you type, interprets it, and runs programs for you. On RHEL the default shell is **bash** (the "Bourne Again SHell").
- The **prompt** is the text the shell prints when it is ready for your next command.

**Reading the prompt.** On your lab machines it looks like this:

```
root@node1:~#
```

| Piece | Meaning |
|---|---|
| `root` | the user you are logged in as |
| `node1` | the short hostname of the machine |
| `~` | your current directory (`~` is shorthand for your home directory) |
| `#` | you are **root**, the all-powerful administrator |
| `$` | (instead of `#`) you are a regular user |

Many RHEL systems show the same information as `[root@node1 ~]#`. The layout is cosmetic; the pieces are the same.

**Why `#` versus `$` matters.** Root can do anything, including destroy the system with one typo. Glance at the last character of the prompt before running anything destructive. It is the cheapest safety check there is.

**Try it.**

```bash
whoami        # which user am I?
hostname      # which machine am I on?
pwd           # which directory am I in? ("print working directory")
echo $SHELL   # which shell is my default?
```

## 0.3 Users, groups, and root

**What they are.** Linux is a multi-user system. Every running program acts on behalf of some **user**, and every file belongs to a user and a **group**.

- The kernel identifies a user by a number called the **UID** (user ID). Names like `student` exist for humans; the kernel only cares about the number.
- A **group** is a named set of users, identified by a **GID** (group ID). Groups let you grant access to several people at once.
- Every user has exactly one **primary group** and can belong to any number of **supplementary groups**.

| Kind of account | UID | Purpose |
|---|---|---|
| `root` | 0 | the superuser; the kernel skips most permission checks for UID 0 |
| system accounts | 1 to 999 | run services (for example `apache` runs the web server) |
| regular users | 1000 and up | people |

**Where this information lives.** Accounts are listed in the text file `/etc/passwd`, one per line, with seven fields separated by colons:

```
student:x:1000:1000:Student User:/home/student:/bin/bash
```

| Field | Example | Meaning |
|---|---|---|
| 1 | `student` | username |
| 2 | `x` | placeholder; the real password hash is kept in `/etc/shadow` |
| 3 | `1000` | UID |
| 4 | `1000` | GID of the primary group |
| 5 | `Student User` | comment, usually the full name |
| 6 | `/home/student` | home directory |
| 7 | `/bin/bash` | login shell; `/sbin/nologin` means "cannot log in interactively" |

Groups are listed in `/etc/group` in a similar colon-separated format.

**Why this matters now.** Permissions (Part 6) are decisions about *which user and group* may do *what*. And `/etc/passwd` is the most common practice file for text processing (Part 3): many exam-style tasks ask you to pull particular fields out of it.

**Try it.**

```bash
id                     # your UID, GID, and groups
id student             # the same for another user
grep student /etc/passwd
head -3 /etc/group
```

## 0.4 The filesystem tree

**What it is.** Linux organizes all files into a single tree that begins at `/`, called the **root directory**. There are no drive letters like `C:`. Extra disks are attached into the tree at a directory (this is called *mounting*, covered in the storage sections).

The word "root" means three different things. Keep them apart:

| Term | Meaning |
|---|---|
| `/` | the root **directory**, top of the tree |
| `root` | the superuser **account** |
| `/root` | the root user's **home directory** |

**Directories you will use constantly.**

| Directory | Contains |
|---|---|
| `/etc` | system configuration, almost all plain text; administrators live here |
| `/home` | regular users' home directories |
| `/root` | root's home directory |
| `/var` | data that changes: logs in `/var/log`, web content in `/var/www` |
| `/tmp` | temporary files; any user may write here |
| `/usr` | installed software: programs in `/usr/bin` and `/usr/sbin`, documentation in `/usr/share/doc` and `/usr/share/man` |
| `/bin`, `/sbin` | on RHEL these are shortcuts (symbolic links, Part 5) to `/usr/bin` and `/usr/sbin` |
| `/boot` | the kernel and bootloader files |
| `/dev` | device files that represent hardware, such as `/dev/sda` for the first disk |
| `/proc`, `/sys` | not stored on disk; the kernel presents live system information here |
| `/mnt`, `/media` | places to attach extra filesystems |
| `/opt` | optional, third-party software |
| `/run` | runtime data created since the last boot |

**Paths.** A **path** is the address of a file in the tree.

- An **absolute path** starts with `/` and means the same thing no matter where you are: `/etc/hosts`.
- A **relative path** does not start with `/`. It is interpreted starting from your **current directory**. If you are in `/etc`, then `hosts` means `/etc/hosts`.

| Shortcut | Meaning |
|---|---|
| `.` | the current directory |
| `..` | the parent directory (one level up) |
| `~` | your home directory |
| `~student` | the home directory of `student` |
| `cd -` | go back to the previous directory |

**Why it matters.** Exam tasks always give absolute paths. Use them exactly. Relative paths depend on where you happen to be standing, which is how files end up created in the wrong place.

**Try it.**

```bash
cd /etc
pwd
ls hosts           # relative path: means /etc/hosts
cd ..
pwd                # now /
cd ~
pwd                # your home
cd -
pwd                # back to /
cd /root/practice
```

## 0.5 Everything is a file

**What it is.** Linux represents many kinds of things as files, so the same tools and permission rules work on all of them. The first character of a long listing (`ls -l`) tells you the type:

| Character | Type | Example |
|---|---|---|
| `-` | regular file | `/etc/hosts` |
| `d` | directory | `/etc` |
| `l` | symbolic link (a pointer to another path) | `/bin` |
| `b` | block device (disks) | `/dev/sda` |
| `c` | character device (terminals, `/dev/null`) | `/dev/null` |
| `p` | named pipe | rare |
| `s` | socket | rare |

**Why it exists.** One consistent interface. For example, `cat /proc/cpuinfo` reads CPU details from the kernel as if they were a text file, and anything written to `/dev/null` is thrown away.

**Why it matters for this section.** Nearly all Linux configuration is plain text in `/etc`. Reading, searching, and editing text is therefore how you *read and change the system*. That is why this whole section is about text, files, and permissions.

**Try it.**

```bash
ls -ld /etc/hosts /etc /bin /dev/sda /dev/null
file /etc/hosts /usr/bin/ls /bin
```

`file` inspects a file's content (not its name) and tells you what it is.

## 0.6 Processes

**What it is.** A **process** is a running instance of a program. Every command you run becomes at least one process. Each process has:

- a **PID** (process ID number)
- a **user** it runs as, which decides what it is allowed to do
- a **parent**, usually the shell that started it
- **open files**, including three standard channels for input and output (Part 2)
- an **exit status** when it finishes: a number reporting success or failure (1.9)

**Why this matters now.** Pipes (Part 2) connect processes. `su` and `sudo` (Part 9) start processes as a different user. Permissions (Part 6) are checked against the user *the process* runs as.

**Try it.**

```bash
echo $$       # the PID of your current shell
ps -f         # processes on this terminal, with their parent PIDs (PPID column)
```

In the `ps -f` output, the `ps` process has a PPID equal to your shell's PID. Your shell started it.

### Part 0 self-check

1. What is the difference between `/`, `/root`, and the `root` user?
2. You are in `/var`. What absolute path does the relative path `log/messages` refer to?
3. In `apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin`, what is the UID, and what does the last field tell you?
4. What does the first character of `lrwxrwxrwx` tell you?

---

# Part 1: Talking to the shell

> **Objective:** Access a shell prompt and issue commands with correct syntax.

## 1.1 Anatomy of a command line

**What it is.** When you press Enter, the shell splits your line into **words** separated by spaces. The first word is the **command**. The remaining words are **arguments** handed to that command. By convention, arguments beginning with `-` are **options**, which change how the command behaves. The others are **operands**: the things the command acts on, usually files.

```
ls   -l -h   /etc /var
|    |       |
|    |       +-- operands: what to list
|    +---------- options: how to list it (long format, human-readable sizes)
+--------------- the command
```

**Why spacing matters.** The shell splits on spaces, so spacing *is* syntax.

- `ls-l` is one word, so the shell looks for a command named `ls-l` and fails with `command not found`.
- `ls - l` passes two operands, `-` and `l`.

**Short and long options.**

| Style | Looks like | Notes |
|---|---|---|
| Short | `-l`, `-h` | one dash, one letter; can be **bundled**: `-lh` means `-l -h` |
| Long | `--human-readable` | two dashes, a word; cannot be bundled; easier to read |

**Options that take a value.** Some options need a value straight after them:

```bash
head -n 3 /etc/passwd          # -n takes the value 3
head -n3 /etc/passwd           # same, value attached
head --lines=3 /etc/passwd     # long form
```

When you bundle short options, **an option that takes a value must come last in the bundle**, because it consumes the next word. This is the most common `tar` mistake:

```bash
tar -czf backup.tar.gz /etc    # correct: f is last, so backup.tar.gz is the file name
tar -cfz backup.tar.gz /etc    # WRONG: f takes "z" as the file name
```

**Ending option processing with `--`.** A lone `--` means "no more options after this point". It lets you handle a file whose name starts with a dash:

```bash
touch -- -oops     # create a file literally named "-oops"
ls -l -- -oops
rm -- -oops
```

Without `--`, `rm -oops` would try to read `-o`, `-o`, `-p`, `-s` as options.

**Subcommands.** Some tools take an action word right after their name: `systemctl start sshd`, `nmcli con show`, `dnf install httpd`. That second word selects what the tool does. You will meet many of these later.

**Case sensitivity.** Linux is case-sensitive everywhere. `ls -r` (reverse order) and `ls -R` (recurse into subdirectories) are different options, and `File.txt` and `file.txt` are different files.

**Finding out what a command accepts:** `command --help` for a quick summary, `man command` for the full manual (Part 11).

**Try it.**

```bash
ls -l -h /etc/hosts
ls -lh /etc/hosts
ls -l --human-readable /etc/hosts
head -n 2 /etc/passwd
```

**What goes wrong.** Missing spaces; a value-taking option not last in a bundle; wrong letter case; a slightly misspelled path. Tab completion (1.10) prevents most of these.

## 1.2 The shell rewrites your command before running it

This is the most important idea in Part 1, and most beginners are never told it.

**What it is.** Between you pressing Enter and the command starting, the shell **transforms** your line. It expands shortcuts, substitutes values, and matches filename patterns. The command only ever sees the *result*.

**How it works.** Bash processes a command line roughly in this order:

1. Split the line into words, respecting quotes.
2. **Brace expansion:** `{a,b}` becomes `a b` (1.6).
3. **Tilde expansion:** `~` becomes your home directory's path.
4. **Variable expansion** (`$HOME`) and **command substitution** (`$(date)`) (1.3, 1.7).
5. **Word splitting:** results of unquoted expansions that contain spaces are split into separate words.
6. **Filename expansion (globbing):** `*.conf` becomes the list of matching filenames (1.5).
7. **Quote removal:** the quote characters themselves disappear.
8. **Redirections** are set up (Part 2).
9. The command runs with the final list of words.

**Why this matters.** When you type `ls *.conf`, the `ls` program never sees an asterisk. The shell has already replaced `*.conf` with `a.conf b.conf c.conf`. This explains a large share of confusing behavior, and it is why quoting (1.8) matters so much.

**The debugging trick: put `echo` in front.** `echo` prints its arguments, so it shows you exactly what a command *would* receive after the shell has finished rewriting.

**Try it.**

```bash
echo /etc/*.conf
echo ~
echo "I am $USER on $(hostname)"
echo {1..5}
```

Before running something dangerous such as `rm /tmp/test*`, run `echo rm /tmp/test*` and read what it would actually do.

## 1.3 Variables and the environment

**What it is.** A **variable** is a named value stored by the shell.

**Anatomy.**

```bash
COLOR=blue          # create or change: NAME=value, with NO spaces around =
echo $COLOR         # read: put $ in front of the name
echo ${COLOR}ish    # braces mark where the name ends: prints "blueish"
unset COLOR         # delete it
```

Why no spaces? Because of 1.1: `COLOR = blue` is three words, so the shell tries to run a command named `COLOR` with the arguments `=` and `blue`.

**Shell variables versus environment variables.** A plain variable exists only in the current shell. When the shell starts another program, that program does **not** receive the variable unless it has been **exported**. Exported variables make up the **environment**, and every child process inherits a copy of it.

```bash
FRUIT=apple
bash -c 'echo "child sees: $FRUIT"'    # child sees:        (nothing)
export FRUIT
bash -c 'echo "child sees: $FRUIT"'    # child sees: apple
```

`bash -c '...'` starts a new child shell that runs the quoted text. The single quotes stop *your* shell from expanding `$FRUIT` first, so the *child* does the expansion (quoting is covered fully in 1.8).

**Variables that already exist.**

| Variable | Holds |
|---|---|
| `HOME` | your home directory |
| `USER` | your username |
| `PWD` | the current directory |
| `PATH` | where the shell searches for commands (1.4) |
| `SHELL` | your default shell |
| `HOSTNAME` | the machine name |
| `PS1` | the format of your prompt |
| `?` | exit status of the last command (1.9); read it as `$?` |

**Listing variables.** `env` or `printenv` shows the environment (exported variables). `set` shows everything, including shell-only variables and functions.

**Persistence.** Variables vanish when the shell exits. To keep one permanently, put the assignment in a startup file: `~/.bashrc` for one user, or a file ending in `.sh` inside `/etc/profile.d/` for all users (Part 9 explains when these files are read).

**What goes wrong.** Spaces around `=`; forgetting `export`, so a child program cannot see the variable; expecting a variable set in one terminal to exist in another.

## 1.4 How the shell finds a command

**What it is.** When the first word of your line is not a path, bash looks for it in this order:

1. **Aliases:** your own shortcut names.
2. **Functions:** small named scripts defined inside the shell.
3. **Builtins:** commands built into bash itself, such as `cd`, `echo`, `export`, and `umask`.
4. **Programs in the `PATH`:** a colon-separated list of directories, searched from left to right. The first match wins.

```bash
echo $PATH
```

You should see something like:

```
/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
```

If a program exists but its directory is not in `PATH`, you must run it by path: `/opt/tool/bin/tool`, or `./script.sh` for a file in the current directory. The current directory is deliberately *not* searched, for security.

**Why builtins exist.** Some commands must change the shell itself. `cd` changes the shell's current directory. A separate program could only change *its own* directory and then exit, which would accomplish nothing. So `cd` has to be part of the shell.

**Seeing what a name resolves to.**

```bash
type ls        # e.g. "ls is aliased to `ls --color=auto'"
type cd        # "cd is a shell builtin"
type -a echo   # a builtin AND /usr/bin/echo both exist
which tar      # the program's path
```

**Aliases.**

```bash
alias                    # list current aliases
alias ll='ls -lh'        # create one, for this shell only
unalias ll               # remove it
\ls                      # a leading backslash skips the alias this one time
```

Run `alias` as root on RHEL and you will most likely see `rm='rm -i'`, `cp='cp -i'`, and `mv='mv -i'`, defined in `/root/.bashrc`. The `-i` means "interactive: ask before overwriting or deleting". That is why `rm` asks for confirmation when you are root. Put your own permanent aliases in `~/.bashrc`.

**What goes wrong.** `command not found` usually means a typo, a package that is not installed (Part 11 shows how to find the right package), or a directory missing from `PATH`.

## 1.5 Globbing: filename patterns

**What it is.** **Globbing** is the shell expanding a pattern into the list of existing filenames that match it.

**Why it exists.** To act on many files without typing every name.

**How it works.** The shell compares the pattern with the names in the directory. Matching names replace the pattern, sorted. **If nothing matches, bash leaves the pattern unchanged** and passes it through literally, so the command receives a real asterisk and usually complains.

| Pattern | Matches |
|---|---|
| `*` | any number of characters, including none |
| `?` | exactly one character |
| `[abc]` | exactly one of `a`, `b`, or `c` |
| `[a-z]` | exactly one character in the range |
| `[!abc]` or `[^abc]` | exactly one character that is **not** listed |

Three rules to remember:

- `*` does **not** match names beginning with a dot (hidden files such as `.bashrc`). Use `.*` or `ls -a` to see those.
- **A glob never crosses a `/`.** `/etc/*.conf` matches `.conf` files directly inside `/etc` only. It does not reach `/etc/ssh/ssh_config.d/*.conf` or anything else in a subdirectory. When you need "everywhere below this directory", that is a job for `find` (4.6), not a glob.
- Glob characters look like regular-expression characters (Part 3) but **mean different things**. In a glob, `*` means "anything". In a regular expression, `*` means "repeat the previous item". Globs describe filenames at the shell; regular expressions describe text inside tools such as `grep` and `sed`.

**Try it.**

```bash
cd /root/practice
mkdir glob && cd glob
touch file1.txt file2.txt file3.txt file10.txt notes.log .hidden
ls *.txt             # four files
ls file?.txt         # exactly one character after "file": 1, 2, 3 (not 10)
ls file[13].txt      # file1.txt and file3.txt
ls file[!1].txt      # file2.txt and file3.txt
echo *               # .hidden is not included
ls -a                # now it is
ls *.xyz             # no match: ls receives the literal text *.xyz
cd /root/practice
```

Prove the "never crosses `/`" rule:

```bash
cd /root/practice/glob
mkdir -p sub
touch top.conf sub/deep.conf
echo *.conf          # top.conf only; sub/deep.conf is not reached
echo */*.conf        # sub/deep.conf: you must spell out each level yourself
cd /root/practice
```

**What goes wrong.**

- **One stray space turns a glob into a disaster.** You mean `rm *.bak`, but you type `rm * .bak`. The shell sees two separate words: `*` (which expands to **every** file in the directory) and `.bak`. Use `echo` to see exactly what would happen, without deleting anything:

  ```bash
  cd /root/practice
  mkdir -p danger && cd danger
  touch keep1 keep2 old.bak
  echo rm * .bak       # prints: rm keep1 keep2 old.bak .bak
  cd /root/practice
  ```

  That `rm` would have deleted `keep1` and `keep2`. The habit that prevents this: before any `rm` with a pattern, run it once with `echo` in front and read the result.

- **Copying "everything" misses hidden files.** `cp -a /home/alice/* /backup/` skips `.bashrc`, `.ssh`, and every other name starting with a dot. Section 4.3 shows the correct way to copy a directory's full contents.
- Forgetting that "no match" passes the literal pattern on.
- Mixing up glob and regex meanings.

## 1.6 Brace expansion

**What it is.** Brace expansion **generates text**. Unlike globbing, it does not look at existing files at all.

**Anatomy.**

```bash
echo {red,green,blue}      # red green blue
echo file{1..4}.txt        # file1.txt file2.txt file3.txt file4.txt
echo {01..03}              # 01 02 03  (leading zeros kept)
echo pre-{a,b}-post        # pre-a-post pre-b-post
```

**Why it is useful.** Building structures and making quick backups:

```bash
mkdir -p /root/practice/site/{dev,test,prod}/{bin,etc,log}
ls -R /root/practice/site
cp /etc/hosts /root/practice/hosts
cp /root/practice/hosts{,.bak}
ls /root/practice
```

That last `cp` looks odd, so apply the rules: `hosts{,.bak}` expands into two words, `hosts` (the empty choice) and `hosts.bak`. The command becomes `cp /root/practice/hosts /root/practice/hosts.bak`.

**What goes wrong.** A space inside the braces stops expansion: `{a, b}` is not expanded. There must be a comma or a `..` range.

## 1.7 Command substitution

**What it is.** `$(command)` runs a command and **is replaced by that command's output** (with trailing newlines removed).

**Anatomy and use.**

```bash
echo "Kernel version: $(uname -r)"
mkdir /root/practice/backup-$(date +%F)       # e.g. backup-2026-09-21
ls /root/practice
echo "There are $(wc -l < /etc/passwd) accounts"
```

You will also see the older backtick form, `` `command` ``. It works the same way but is harder to read and to nest. Prefer `$( )`.

**Why it matters.** It lets you use one command's result inside another, and it is central to shell scripts (Section 3).

## 1.8 Quoting: controlling what the shell rewrites

**What it is.** Quotes tell the shell which rewriting steps from 1.2 to perform, and whether spaces should split words.

| Form | Variables and `$( )` | Globs (`*`) | Spaces split words? |
|---|---|---|---|
| no quotes | expanded | expanded | yes |
| `"double quotes"` | **expanded** | not expanded | no |
| `'single quotes'` | not expanded | not expanded | no |
| `\` before one character | that single character is taken literally | | |

**Try it.**

```bash
echo $HOME "$HOME" '$HOME'
echo *.none "*.none" '*.none'
echo "Cost: \$5"
```

**The problem quoting solves: word splitting.**

```bash
cd /root/practice
touch "two words.txt"
F="two words.txt"
ls $F            # FAILS: the shell splits it into "two" and "words.txt"
ls "$F"          # works: one argument
```

**Rules of thumb.**

- **Always put variables in double quotes:** `"$file"`, not `$file`.
- Use **single quotes** when the text must reach the program untouched: regular expressions for `grep`, programs for `awk`, and anything containing `$` that the *receiving* program should interpret.
- Use **double quotes** when you want variables expanded but spaces kept intact.

**What goes wrong.** Unquoted variables break on filenames with spaces; double-quoting an `awk` program lets the shell replace `$1` before `awk` sees it; unquoted patterns get globbed by the shell.

## 1.9 Exit status and chaining commands

**What it is.** Every process finishes with an **exit status**, a number from 0 to 255. **0 means success. Anything else means failure.** Some commands give different non-zero values different meanings: `grep` returns 0 if it found a match, 1 if it found nothing, and 2 if something went wrong.

The shell stores the last exit status in the special variable `?`:

```bash
ls /etc > /dev/null ; echo $?              # 0
ls /nonexistent 2> /dev/null ; echo $?     # 2 (non-zero: failure)
```

(`> /dev/null` and `2> /dev/null` discard output. Part 2 explains them.)

**Why it exists.** It lets commands and scripts make decisions based on whether something worked.

**Chaining operators.**

| Operator | Meaning | Example |
|---|---|---|
| `a ; b` | run `a`, then run `b` no matter what | `cd /tmp ; ls` |
| `a && b` | run `b` **only if `a` succeeded** | `mkdir /srv/data && cd /srv/data` |
| `a \|\| b` | run `b` **only if `a` failed** | `grep -q alice /etc/passwd \|\| echo "no alice"` |
| `a \| b` | pipe: `a`'s output feeds `b` (Part 2) | `ls /etc \| wc -l` |
| `a &` | run `a` in the background | `sleep 60 &` |

**Try it.**

```bash
mkdir -p /root/practice/chain && cd /root/practice/chain && pwd
grep -q root /etc/passwd && echo "root exists"
grep -q nobodyhere /etc/passwd || echo "no such user"
cd /root/practice
```

**What goes wrong.** Using `;` where the second command is only safe if the first succeeded. Compare `cd /wrongdir ; rm -rf *` (a disaster: when `cd` fails, `rm` runs in whatever directory you were already in) with `cd /wrongdir && rm -rf *` (safe: `rm` never runs).

**A subtle trap: `a && b || c` is not "if a then b, else c".** It looks like an if/else, and people use it that way. But read it with the rules above: `c` runs whenever the thing to its left **failed**, and the thing to its left is `a && b`. So `c` runs if `a` fails, **and also** if `a` succeeds but `b` fails.

```bash
true && false || echo "c ran"      # prints "c ran", although a (true) succeeded
```

(`true` and `false` are tiny commands that do nothing except exit with status 0 and 1.) This is fine for simple messages such as `grep -q x f && echo yes || echo no`, where the middle command cannot fail. When the middle command *can* fail, a real `if` statement is the correct tool; you will write those in Section 3.

## 1.10 Working efficiently

Speed and accuracy at the keyboard are real exam skills. Three hours pass quickly.

**Tab completion.** Press `Tab` to complete a command, path, or filename. Press it twice to list the possibilities when there is more than one. With the `bash-completion` package installed, `Tab` also completes options and subcommands for tools such as `systemctl`, `nmcli`, and `firewall-cmd`. Tab completion is also a *correctness* check: if a path completes, it exists.

**History.**

| Keys or syntax | Does |
|---|---|
| Up / Down arrows | step through previous commands |
| `Ctrl-R`, then type | search backward through history; press `Ctrl-R` again for older matches |
| `history` | list numbered history |
| `!42` | rerun history entry 42 |
| `!!` | the whole previous command (`sudo !!` reruns it with sudo) |
| `!$` or `Alt-.` | the last argument of the previous command |

**Editing the line.**

| Keys | Does |
|---|---|
| `Ctrl-A` / `Ctrl-E` | jump to the start / end of the line |
| `Ctrl-U` / `Ctrl-K` | delete to the start / end of the line |
| `Ctrl-W` | delete the previous word |
| `Ctrl-L` | clear the screen |

**Controlling programs.**

| Keys | Does |
|---|---|
| `Ctrl-C` | interrupt (stop) the running command. Use it whenever something hangs. |
| `Ctrl-D` | "end of input"; at an empty prompt it logs you out |
| `Ctrl-Z` | suspend the running command; `fg` brings it back |

### How RHCSA tests Part 1

No task says "demonstrate shell syntax". The shell is simply the tool for every other task, so syntax errors cost time or silently produce wrong results. Typical point-losers: a value-taking option not last in a bundle (`tar -cfz`), unquoted patterns, typos in paths, and commands run in the wrong directory because of relative paths.

### Part 1 self-check

1. Why does `NAME = value` fail?
2. What does `ls` actually receive when you type `ls /etc/*.conf`?
3. What is the difference between `echo "$HOME"` and `echo '$HOME'`?
4. You type `ls *.bak` and no `.bak` files exist. What argument does `ls` receive?
5. Why is `cd /data && rm -rf *` safer than `cd /data ; rm -rf *`?
6. Why must `cd` be a shell builtin rather than a separate program?
7. `true && false || echo c` prints `c`. Why, when the first command succeeded?

---

# Part 2: Redirection and pipes

> **Objective:** Use input-output redirection (`>`, `>>`, `|`, `2>`, etc.).

## 2.1 The three standard streams

**What it is.** When a process starts, it is handed three already-open communication channels, identified by small numbers called **file descriptors** (often shortened to *fd*). A file descriptor is simply the number a process uses to refer to something it has open.

| fd | Name | Short name | Used for | Normally connected to |
|---|---|---|---|---|
| 0 | standard input | stdin | reading input | your keyboard |
| 1 | standard output | stdout | normal results | your screen |
| 2 | standard error | stderr | error messages and diagnostics | your screen |

Picture every process as a box with three numbered sockets. By default the shell plugs your keyboard into socket 0 and your screen into sockets 1 and 2:

```
              +-----------------+
 keyboard --->| 0     process 1 |---> screen   (normal output)
              |               2 |---> screen   (errors)
              +-----------------+
```

**Why errors get their own stream.** Results and errors usually belong in different places. When you save a list of files, you want the list in the file and the errors on your screen, where you will notice them. When output feeds another program, error text mixed into the data would corrupt it. Two separate streams let you route each one independently.

**How it works.** A program writes to fd 1 or fd 2 without knowing or caring where they lead. **Redirection** is the shell reconnecting those sockets to somewhere else (a file, another program, or nowhere) *before* the program starts.

**Try it.** Both streams normally appear on the screen together, so you cannot tell them apart by looking:

```bash
ls /etc/hosts /nonexistent
```

One line is stdout (`/etc/hosts`) and one is stderr (the error). The next sections separate them.

Many programs read stdin when you give them no filename. `wc -l` counts lines:

```bash
wc -l
```

Type three lines, pressing Enter after each, then press `Ctrl-D` on an empty line. `Ctrl-D` signals "end of input", and `wc` prints `3`. That is what "reading from stdin" means: input arriving through fd 0 instead of from a named file.

## 2.2 Sending output to a file: `>` and `>>`

**What it is.**

- `> file` connects **fd 1 (stdout)** to `file`, **replacing** whatever the file contained.
- `>> file` connects fd 1 to `file`, **appending** to its end.

**How it works: the shell does it, not the command.** Redirection is set up by the shell *before* the command starts. The command just writes to fd 1 as usual and never knows a file is involved. Three consequences follow:

1. **With `>`, the shell creates the file if it does not exist, and empties it if it does, before the command runs.** The emptying happens even if the command then fails or prints nothing.
2. **You cannot read and overwrite the same file in one command.** `sort names.txt > names.txt` leaves `names.txt` **empty**: the shell empties the file first, then `sort` opens it, finds nothing, and sorts nothing. Use `sort -o names.txt names.txt` (it reads everything before writing) or write to a temporary file and rename it.
3. **The file is opened with your shell's permissions.** This matters for `sudo`, as 2.7 shows.

**Anatomy.**

```bash
command > file      # stdout to file, overwrite (identical to: command 1> file)
command >> file     # stdout to file, append
> file              # no command at all: simply empties file (handy for clearing a log)
```

Spaces around `>` are optional: `command >file` works the same.

**Try it.**

```bash
cd /root/practice
echo one > f.txt
cat f.txt            # one
echo two > f.txt
cat f.txt            # two   (one was overwritten)
echo three >> f.txt
cat f.txt            # two, three
> f.txt
wc -c f.txt          # 0 bytes
```

Prove consequence 2 for yourself:

```bash
printf 'cherry\napple\nbanana\n' > fruit.txt
sort fruit.txt > fruit.txt
cat fruit.txt        # empty!
printf 'cherry\napple\nbanana\n' > fruit.txt
sort -o fruit.txt fruit.txt
cat fruit.txt        # apple, banana, cherry
```

**A safety net: `noclobber`.** `set -o noclobber` makes `>` refuse to overwrite an existing file. You can still force it with `>|`. Turn the option off again with `set +o noclobber`.

**Verify.** `cat file` to see the content, `wc -l file` to count lines, `ls -l file` to confirm it exists and has a sensible size.

**What goes wrong.** Typing `>` when you meant `>>` on a system file such as `/etc/hosts` wipes it and leaves one line. **Before appending to any file in `/etc`, back it up:** `cp /etc/hosts /etc/hosts.bak`.

## 2.3 Sending errors to a file: `2>`, `2>>`, and `/dev/null`

**What it is.** The same idea as `>`, applied to **fd 2**.

```bash
command 2> errors.txt      # stderr to a file, overwrite
command 2>> errors.txt     # stderr to a file, append
command 2> /dev/null       # stderr thrown away
```

There must be **no space between `2` and `>`**. Written as `2 > file`, the `2` becomes an ordinary argument to the command, and only stdout is redirected.

**What `/dev/null` is.** A special device file. Anything written to it is discarded. Anything reading from it gets "end of input" immediately. Think of it as a black hole.

**Why you would use it.** To hide error messages you already understand, such as the permission errors produced when searching the whole disk:

```bash
find / -name hosts 2> /dev/null
```

**Try it: separate the two streams.**

```bash
cd /root/practice
ls /etc/hosts /nonexistent > out.txt 2> err.txt
cat out.txt          # /etc/hosts
cat err.txt          # the error message
```

**What goes wrong.** Discarding errors hides real problems. Only send errors to `/dev/null` when you know exactly which errors you are hiding.

## 2.4 Both streams to one place: `2>&1` and `&>`

**What it is.** `2>&1` means "connect fd 2 to wherever fd 1 is connected **right now**".

**Anatomy.**

- `2>` redirects stderr, as before.
- `&1` means "file descriptor 1". The `&` is essential. Without it, `2>1` sends errors to a **file named `1`**.

**How it works: redirections are processed left to right, like instructions.** Think of each fd as holding a destination. Each redirection updates one of them. `2>&1` **copies** fd 1's destination at that moment. It is a copy, not a permanent link.

The correct form, `command > file 2>&1`:

| Step | fd 1 | fd 2 |
|---|---|---|
| start | screen | screen |
| `> file` | **file** | screen |
| `2>&1` (copy fd 1's current destination) | file | **file** |
| **result** | file | file |

Both streams end up in the file.

The reversed form, `command 2>&1 > file`:

| Step | fd 1 | fd 2 |
|---|---|---|
| start | screen | screen |
| `2>&1` (copy fd 1's current destination) | screen | **screen** (no change) |
| `> file` | **file** | screen |
| **result** | file | screen |

Errors still reach the screen. The order is not cosmetic.

**The shorthand.** Bash also accepts `&> file` (both streams, overwrite) and `&>> file` (both, append). They are equivalent to `> file 2>&1` and `>> file 2>&1`. Know both: the long form works in every shell and appears throughout documentation.

**Try it.**

```bash
cd /root/practice
ls /etc/hosts /nonexistent > both.txt 2>&1
cat both.txt                          # both lines

ls /etc/hosts /nonexistent 2>&1 > wrong.txt
# the error appeared on your screen
cat wrong.txt                         # only /etc/hosts

ls /etc/hosts /nonexistent &> short.txt
cat short.txt                         # both lines
```

**How RHCSA tests it.** Tasks phrased like "save the output *and any errors* of command X to file Y". The file must contain both.

## 2.5 Feeding input: `<`, here documents, here strings

### `<`: a file as standard input

**What it is.** `command < file` connects **fd 0** to `file`, so the command reads the file as if you had typed it.

**Why the difference is visible.** Compare:

```bash
wc -l /etc/passwd        # e.g. "35 /etc/passwd": wc opened the file, so it knows the name
wc -l < /etc/passwd      # e.g. "35": the shell opened it; wc only sees a stream
```

The second form is exactly what you need when a task wants **only a number** in a file:

```bash
wc -l < /etc/passwd > /root/practice/count.txt
cat /root/practice/count.txt
```

Some commands *only* read stdin and never accept a filename. `tr` (translate characters) is one:

```bash
tr 'a-z' 'A-Z' < /etc/hostname
```

### Here documents: `<<`

**What it is.** A **here document** supplies several lines of input written directly on the command line. The input ends at a line containing only a chosen **delimiter** word, conventionally `EOF`.

**Why administrators use it constantly.** To write a whole configuration file in one step, without opening an editor:

```bash
cat > /root/practice/app.conf <<'EOF'
# application settings
port=8080
home=$HOME
EOF
cat /root/practice/app.conf
```

Read that command piece by piece:

| Piece | Role |
|---|---|
| `cat` | copies its stdin to its stdout, unchanged |
| `> /root/practice/app.conf` | stdout goes into the file |
| `<<'EOF'` | stdin is the lines that follow, up to a line containing only `EOF` |

So `cat` is simply the pipe that carries your text into the file.

**Quoted versus unquoted delimiter.**

- `<<'EOF'` (quoted): the text is taken **literally**. `$HOME` stays as the characters `$HOME`.
- `<<EOF` (unquoted): variables and `$( )` inside the text are **expanded** first.

```bash
cat <<EOF
Expanded: $HOME
EOF
cat <<'EOF'
Literal: $HOME
EOF
```

For configuration files, prefer the quoted form unless you deliberately want expansion. Unexpected expansion silently writes the wrong configuration.

**The closing delimiter must be alone on its line**, with no spaces before or after it. If it is missing, the shell keeps showing a `>` prompt, waiting for more input. That `>` is the *continuation prompt*, not a redirection. Type `EOF` on its own line, or press `Ctrl-C` to abandon the command.

### Here strings: `<<<`

**What it is.** A single string supplied as stdin:

```bash
tr 'a-z' 'A-Z' <<< "hello"
grep -c o <<< "foo boo"
```

## 2.6 Pipes

**What it is.** `a | b` connects the **stdout of `a`** directly to the **stdin of `b`**. No file is created; the kernel holds the data in a small memory buffer between the two processes.

```
+------+   stdout             stdin   +------+
|  a   |------------- pipe ------------>|  b   |---> screen
+------+                              +------+
   |
   +--- stderr ---> screen   (errors do NOT enter the pipe)
```

**Why it exists.** Linux tools are small, and each does one job well: one selects lines, one sorts, one counts. Pipes let you combine them into a custom tool on the spot.

**How it works.**

- The shell starts **all** commands in a pipeline at the same time. Data flows as it is produced. If the buffer fills, the writer pauses; when the writer finishes, the reader sees end of input.
- **Only stdout flows through the pipe.** stderr still goes to the screen unless you redirect it (`2>&1 |`, or the shorthand `|&`).
- The pipeline's exit status is that of the **last** command.

**The key skill: build a pipeline one step at a time.** Run the first command, look at the output, add the next stage, look again. Never type a long pipeline in one go.

**Worked example.** Question: *which login shells are used on this system, and how many accounts use each?*

```bash
cut -d: -f7 /etc/passwd
```

Field 7 of each `/etc/passwd` line is the login shell (`cut` is explained in Part 3). You see one shell per line, many repeated.

```bash
cut -d: -f7 /etc/passwd | sort
```

Identical lines are now next to each other.

```bash
cut -d: -f7 /etc/passwd | sort | uniq -c
```

`uniq -c` merges **adjacent** identical lines into one and puts a count in front. That is why `sort` had to come first.

```bash
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn
```

`sort -rn` sorts numerically (`-n`), largest first (`-r`). Four simple tools, one precise answer.

**Commands that do not read stdin.** Tools like `ls`, `cp`, `rm`, and `mkdir` take their targets as **arguments**, not from stdin, so piping names into them does nothing. `xargs` turns lines on stdin into arguments:

```bash
printf '/root/practice/x1\n/root/practice/x2\n' | xargs touch
ls /root/practice/x*
```

**What goes wrong.** Expecting errors to travel through the pipe; using `uniq` without `sort`; piping into a command that ignores stdin.

## 2.7 `tee`: save output and keep it flowing

**Recap.** stdout normally goes to the screen. `> file` sends it to a file instead, so you no longer see it. A pipe sends it to another program instead.

**The problem.** Sometimes you want **both**: watch the output (or pass it to the next command) **and** keep a copy in a file. Redirection cannot do that, because fd 1 can be connected to only one place at a time.

**What `tee` is.** A small program that:

1. reads everything that arrives on its **stdin**,
2. writes a copy to **every file** named as an argument, and
3. writes another copy to its own **stdout**, which continues to the screen or to the next command in the pipeline.

**Why it is called `tee`.** After the T-shaped fitting in plumbing: one pipe in, two pipes out.

```
                                +---> file
command ---stdout---> [ tee ] --+
                                +---> stdout (screen, or the next command)
```

**How `tee` differs from `>`.** With `>`, the **shell** opens the file. With `tee`, the **`tee` program** opens the file. That sounds like a technicality, but it is precisely what makes the `sudo tee` technique below work.

**Anatomy.**

```bash
command | tee file              # overwrite file, and still show the output
command | tee -a file           # append instead (-a, like >>)
command | tee f1 f2             # several files at once
command | tee file | next       # copy to file AND pass it on to "next"
command | tee file > /dev/null  # write the file, show nothing
```

Without `-a`, `tee` empties the file first, just as `>` does.

**Try it.**

```bash
cd /root/practice
ls /etc | tee etc-list.txt | wc -l
wc -l < etc-list.txt       # the same number: the full list was saved
echo "first"  | tee log.txt
echo "second" | tee -a log.txt
cat log.txt                # first, second
```

### Capturing errors too: `command 2>&1 | tee logfile`

A pipe carries only stdout. With `command | tee log`, error messages bypass the pipe, appear on the screen, and never reach `log`. Put `2>&1` first and stderr is pointed at the same place as stdout, which at that moment is the pipe, so both streams reach `tee`:

```bash
ls /etc/hosts /nonexistent 2>&1 | tee run.log
cat run.log                # the error is in the log too
```

In bash, `|& tee run.log` is shorthand for `2>&1 | tee run.log`.

### `sudo tee`: writing to files you do not own

This problem appears as soon as you work as a regular user with `sudo`. (Part 9 explains `sudo` fully. For now: `sudo` runs a single command as root.)

```bash
sudo echo "10.0.0.5 web" >> /etc/hosts
# bash: /etc/hosts: Permission denied
```

**Why it fails.** Follow the order from 1.2 and 2.2. Your shell, running as *you*, sets up `>> /etc/hosts` **before** anything runs. You are not allowed to write to `/etc/hosts`, so it fails right there. `sudo` would only have elevated `echo`, and `echo` never opens the file anyway.

**The fix.**

```bash
echo "10.0.0.5 web" | sudo tee -a /etc/hosts > /dev/null
```

| Piece | Role |
|---|---|
| `echo "..."` | produces the text, as you (no privilege needed) |
| `\|` | hands it to the next command |
| `sudo tee -a /etc/hosts` | `tee` runs **as root**, so `tee` itself can open `/etc/hosts`; `-a` appends |
| `> /dev/null` | `tee` also copies to its stdout; this discards that copy so it does not clutter the screen |

Another way is to run the whole command line inside a root shell: `sudo sh -c 'echo "10.0.0.5 web" >> /etc/hosts'`.

**Try it** as the `student` user. This works if `student` is in the `wheel` group (it is, if you ticked "Make this user administrator" during install). Use student's password when `sudo` asks.

```bash
su - student
sudo echo test > /root/practice/sudo-test.txt       # Permission denied
echo test | sudo tee /root/practice/sudo-test.txt    # works
exit
cat /root/practice/sudo-test.txt
```

**Verify.** `cat` the file. Confirm the content is there and that nothing you meant to append was overwritten instead.

**What goes wrong.** Forgetting `-a` makes `tee` overwrite the file. On `/etc/hosts` or `/etc/fstab` that is destructive. Take a backup first.

**How RHCSA tests it.** Rarely by name. But `2>&1`, `tee`, and privileged writes appear inside many tasks, and understanding them prevents silent mistakes.

## 2.8 Redirection traps in one place

| Trap | Why it happens | Fix |
|---|---|---|
| `sort f > f` leaves `f` empty | the shell empties `f` before `sort` reads it | `sort -o f f`, or a temporary file |
| `>` instead of `>>` on a config file | overwrite instead of append | back up first; read the line before pressing Enter |
| `cmd 2>&1 > file` leaks errors | redirections are processed left to right | `cmd > file 2>&1` |
| `2>1` creates a file named `1` | the `&` is missing | `2>&1` |
| `2 > file` redirects stdout | the space turns `2` into an argument | `2>file` or `2> file` |
| `sudo echo x > /etc/f` is denied | your shell opens the file, as you | `echo x \| sudo tee /etc/f` |
| errors missing from a piped log | pipes carry only stdout | `2>&1 \|` or `\|&` |

### Part 2 self-check

1. What number is stderr, and why does it exist separately from stdout?
2. Why does `sort data.txt > data.txt` produce an empty file?
3. Walk through `cmd > out 2>&1` and `cmd 2>&1 > out`. Where do errors end up in each?
4. Why does `wc -l < file` print only a number?
5. What three things does `tee` do with its input?
6. Why does `sudo echo x >> /etc/hosts` fail while `echo x | sudo tee -a /etc/hosts` works?

---

# Part 3: Searching and analyzing text

> **Objective:** Use grep and regular expressions to analyze text.

## 3.1 Why text searching is a core admin skill

Configuration files and logs are text. Questions like "is root login allowed?", "which users have a real shell?", or "what went wrong this morning?" are answered by **finding the right lines in text**. `grep` is the tool for that.

The name comes from an old editor command, `g/re/p`: **g**lobally search for a **r**egular **e**xpression and **p**rint the matching lines.

## 3.2 `grep` fundamentals

**What it is.** `grep` reads text **line by line** and prints every line that contains a match for a pattern.

**Anatomy.**

```
grep [options] PATTERN [FILE...]
```

- `PATTERN` is what to look for: a *regular expression* (3.3).
- `FILE...` is zero or more files. **With no file, `grep` reads stdin**, which is why it works at the end of a pipe.
- With more than one file, each matching line is prefixed with the file's name.

**How it works.** The unit is always the **line**. If any part of a line matches, the **whole line** is printed.

**Try it.** Work on a copy so you can experiment freely:

```bash
cd /root/practice
cp /etc/passwd passwd
grep root passwd
```

You probably see more than one line. `grep root` matches `root` *anywhere*, including inside other words and other fields. Precision comes from options and from regular expressions.

**The options you need, and why you would use them.**

| Option | Meaning | Typical reason |
|---|---|---|
| `-i` | ignore case | logs mix `Error`, `ERROR`, and `error` |
| `-v` | invert: print lines that do **not** match | strip comments, exclude noise |
| `-c` | print the **count** of matching lines | "how many?" (counts lines, not occurrences) |
| `-n` | show line numbers | so you can jump to that line in `vim` |
| `-l` | list only the names of files that match | "which config file sets X?" |
| `-r` | search a whole directory, recursively | search all of `/etc/ssh` at once |
| `-w` | whole words only | `-w root` does not match `chroot` |
| `-x` | whole lines only | exact line equality |
| `-o` | print only the matching part | extract values instead of whole lines |
| `-A n`, `-B n`, `-C n` | also print n lines **A**fter, **B**efore, or around each match | see the context of a log entry |
| `-E` | extended regular expressions (3.3) | use `+ ? \| ( ) { }` without backslashes |
| `-F` | fixed string, no regex at all | search for text full of special characters |
| `-e PAT` | add a pattern; repeatable | several patterns at once |
| `-q` | quiet: print nothing, only set the exit status | scripts and `&&` / `\|\|` chains |

**Try it.**

```bash
grep -n nologin passwd | head -5
grep -c nologin passwd
grep -v nologin passwd
grep -w root passwd
grep -i ROOT passwd
grep -rn PermitRootLogin /etc/ssh/
grep -rl PermitRootLogin /etc/ssh/
grep -A2 '^Port' /etc/ssh/sshd_config
grep -q root passwd ; echo $?          # 0: found
grep -q nosuchname passwd ; echo $?    # 1: not found
```

## 3.3 Regular expressions from zero

**What a regular expression is.** A **regular expression** (regex) is a small language for describing *a set of strings*. Instead of searching for one exact word, you describe a shape: "a line that starts with `#`", "four or more digits", "either `root` or `adm` at the start of a line".

**Literal characters and metacharacters.** Most characters match themselves: the regex `root` matches the text `root`. A few **metacharacters** have special meanings. Learn them one group at a time.

### Anchors: where on the line

| Regex | Matches |
|---|---|
| `^root` | `root` at the **start** of a line |
| `bash$` | `bash` at the **end** of a line |
| `^$` | an **empty** line (start immediately followed by end) |

Anchors match *positions*, not characters.

```bash
grep '^root' passwd        # only the line that begins with root
grep 'bash$' passwd        # accounts whose shell ends in bash
```

### The dot: any single character

`.` matches **exactly one** character of any kind. `r..t` matches `root`, `rast`, and `r12t`.

To match a **literal** dot, escape it with a backslash: `\.` matches only `.`. This matters for IP addresses and filenames: `grep '10.0.0.1'` would also match `10x0y0z1`.

### Bracket expressions: one character from a set

| Regex | Matches exactly one character that is |
|---|---|
| `[abc]` | `a`, `b`, or `c` |
| `[0-9]` | a digit |
| `[a-zA-Z]` | a letter |
| `[^0-9]` | **not** a digit (a `^` as the *first character inside the brackets* means "not") |

So `^` means "start of line" outside brackets and "not" as the first character inside them.

**POSIX classes** are named sets used *inside* a bracket expression, which is why they appear with double brackets:

| Class | Same idea as |
|---|---|
| `[[:digit:]]` | `[0-9]` |
| `[[:alpha:]]` | letters |
| `[[:alnum:]]` | letters and digits |
| `[[:space:]]` | space, tab, and other whitespace |
| `[[:upper:]]`, `[[:lower:]]` | upper- or lowercase letters |

### Quantifiers: how many times

A quantifier applies to **the single item just before it**: one character, one bracket expression, or one group.

| Quantifier | Means |
|---|---|
| `*` | zero or more |
| `+` | one or more |
| `?` | zero or one (optional) |
| `{3}` | exactly 3 |
| `{3,}` | 3 or more |
| `{2,4}` | between 2 and 4 |

Two beginner traps:

- `.*` means "any character, any number of times", in other words "anything".
- `a*` means **zero** or more `a`, and every line contains zero `a`s somewhere, so `a*` matches every line. If you mean "at least one", write `a+`.

### Grouping and alternation

| Regex | Means |
|---|---|
| `(ab)+` | treat `ab` as one unit so a quantifier applies to all of it |
| `cat\|dog` | either `cat` or `dog` |
| `^(root\|adm):` | `root:` or `adm:` at the start of a line |

### Word boundaries

`\<` matches the start of a word, `\>` the end, and `\b` either. `\<root\>` matches `root` but not `chroot` or `rooted`. (`grep -w` achieves the same for a whole pattern.)

### Basic versus extended regular expressions

`grep` understands two dialects:

| Feature | Basic (plain `grep`) | Extended (`grep -E`) |
|---|---|---|
| `. * ^ $ [ ]` | special | special |
| `+ ? \| ( ) { }` | **literal** unless preceded by a backslash (`\+`, `\|`, `\{3\}`) | special |

**Recommendation: use `grep -E` whenever your pattern uses `+`, `?`, `|`, parentheses, or braces.** It matches the tables above as written. (`egrep` is an old name for `grep -E`.)

### Greediness

A quantifier grabs **as much text as it can**. With `-o`, `grep -o 'x.*y'` returns everything from the first `x` to the *last* `y` on the line, not the nearest one. Keep this in mind when extracting values.

## 3.4 Always single-quote your patterns

**Why.** Recall 1.2: the shell rewrites your line *before* `grep` runs. Regex metacharacters overlap with shell syntax. Unquoted, `*` and `[...]` may be globbed against filenames in the current directory, `$` may be treated as a variable, and `|` becomes a pipe. The shell mangles the pattern, and `grep` searches for something you never meant.

```bash
grep -E '^(root|adm):' passwd       # correct
grep -E ^(root|adm): passwd         # the shell chokes on ( and |: syntax error
```

**Rule: put every regex in single quotes.**

## 3.5 Building a regex step by step

Build patterns the way you build pipelines: start small, test, extend.

**Task:** list the accounts whose UID has four or more digits.

Think first. In `/etc/passwd` the UID is field 3. After the username comes `:x:`, then the UID, then another `:`.

```bash
grep ':x:' passwd                   # step 1: every line (sanity check)
grep -E ':x:[0-9]' passwd           # step 2: :x: followed by a digit
grep -E ':x:[0-9]{4,}:' passwd      # step 3: four or more digits, then a colon
```

**Verify with a different method.** When two independent approaches agree, you can trust the answer:

```bash
grep -cE ':x:[0-9]{4,}:' passwd
awk -F: '$3 >= 1000' passwd | wc -l
```

(`awk` is explained in 3.6.) The two counts should match.

**Second example:** display a config file without comments or blank lines, even when comments are indented.

```bash
grep -vE '^[[:space:]]*(#|$)' /etc/ssh/sshd_config
```

Read it left to right: *start of line*, then *any amount of whitespace*, then *either `#` or end of line*. That describes comment lines and blank lines. `-v` inverts it and prints everything else.

### Test yourself against known answers

Practising on the real `/etc/passwd` has a weakness: its contents differ from machine to machine, so you can never be sure your prediction was right. This file has **known contents**, so every command below has **one correct output**. Create it exactly as shown. Note that line 6 is empty and line 7 starts with four spaces.

```bash
mkdir -p /root/practice/regex && cd /root/practice/regex
cat > sample.txt <<'EOF'
root:x:0:0:root:/root:/bin/bash
alice:x:1001:1001::/home/alice:/bin/bash
bob:x:1002:1002::/home/bob:/sbin/nologin
chroot-helper:x:995:995::/:/sbin/nologin
# a comment line

    # an indented comment
Server 10.0.0.1 is up
Backup 10x0y0z1 is down
color
colour
colouur
Error: disk full
error: retrying
EOF
grep -c '' sample.txt       # should print 14 (see answer 15 for why this counts lines)
```

**How to use this.** For each command, **write down your prediction first**: which lines, and how many. Then run it. Then read the answer and its reason. A wrong prediction you understand is worth more than a right one you guessed.

```bash
grep root sample.txt                      #  1
grep '^root' sample.txt                   #  2
grep -w root sample.txt                   #  3
grep 'nologin$' sample.txt                #  4
grep -c nologin sample.txt                #  5
grep -i error sample.txt                  #  6
grep '10.0.0.1' sample.txt                #  7
grep '10\.0\.0\.1' sample.txt             #  8
grep -E '^colou?r$' sample.txt            #  9
grep -E '^colou*r$' sample.txt            # 10
grep -E '^colou+r$' sample.txt            # 11
grep -E '^(alice|bob):' sample.txt        # 12
grep -v '^#' sample.txt                   # 13
grep -vE '^[[:space:]]*(#|$)' sample.txt  # 14
grep -c '' sample.txt                     # 15
grep -n '^$' sample.txt                   # 16
```

**Answers.** These were captured from real runs.

| # | Output | Why |
|---|---|---|
| 1 | the `root` line **and** the `chroot-helper` line | unanchored `root` matches inside `chroot` too |
| 2 | the `root` line only | `^` requires `root` at the very start of the line |
| 3 | the `root` line only | `-w` needs `root` as a whole word; in `chroot` it is preceded by the letter `h` |
| 4 | the `bob` and `chroot-helper` lines | `$` requires `nologin` at the very end |
| 5 | `2` | `-c` counts matching **lines** |
| 6 | `Error: disk full` and `error: retrying` | `-i` ignores case |
| 7 | the `Server` line **and** the `Backup 10x0y0z1` line | each unescaped `.` matches **any** one character, including `x`, `y`, `z` |
| 8 | the `Server` line only | `\.` matches only a literal dot |
| 9 | `color`, `colour` | `u?` means zero or one `u` |
| 10 | `color`, `colour`, `colouur` | `u*` means zero or more `u` |
| 11 | `colour`, `colouur` | `u+` means one or more `u`, so `color` (zero) fails |
| 12 | the `alice` and `bob` lines | `(alice\|bob)` is either word, anchored at the start and followed by `:` |
| 13 | 12 lines, **including the blank line and the indented comment** | `^#` only matches a `#` in column one; the indented comment starts with spaces |
| 14 | 11 lines: the four account lines, `Server`, `Backup`, the three `colo...` lines, and both error lines | whitespace-then-`#`, or an empty line, are both excluded |
| 15 | `14` | an empty pattern matches every line, so this counts all lines, blank ones included |
| 16 | `6:` | line 6 is the only empty line; `-n` prefixes the line number |

Answers 13 and 14 together are the most useful lesson here. The obvious pattern for "strip comments" silently lets indented comments and blank lines through, and a grader comparing your output file would notice. **Always look at the output of a filter, do not assume it.**

## 3.6 Thinking in fields: `cut`, `awk`, `sort`, `uniq`, `wc`, `head`, `tail`, `sed`, `tr`

**The idea.** Much structured text consists of **records** (lines) divided into **fields** by a **delimiter**. In `/etc/passwd` the delimiter is `:`. In the output of many commands, fields are separated by spaces. Once you see text as fields, many tasks become "select these lines, then keep these fields".

### `cut`: extract fields or character positions

```bash
cut -d: -f1 passwd          # -d delimiter ":", -f field 1: the usernames
cut -d: -f1,7 passwd        # fields 1 and 7
cut -d: -f1-3 passwd        # fields 1 through 3
cut -c1-8 passwd            # characters 1 through 8 of every line
```

Limitation: `cut` accepts only a single-character delimiter and treats every occurrence as a boundary, so it copes badly with columns padded by several spaces. Use `awk` for space-separated output.

A second surprise: **a line that contains no delimiter at all is printed whole**, unchanged. On `/etc/passwd` that never matters, because every line has colons. On a file with comments or free text, those lines leak into your "field 1" output. `-s` (**s**uppress) drops lines that have no delimiter.

### `awk`: fields plus conditions

`awk` is a small programming language. For RHCSA you need one pattern:

```
awk -F<delimiter> '<condition> { <action> }' file
```

- `-F:` sets the field delimiter. Without `-F`, fields are separated by any run of spaces or tabs.
- Inside `awk`, `$1`, `$2`, and so on are the fields, `$0` is the whole line, and `NF` is the number of fields.
- The **condition** chooses which lines to act on. The **action** says what to do. With no action, `awk` prints the whole line.
- The program goes in **single quotes** so the shell does not treat `$1` as one of *its* variables.

```bash
awk -F: '{ print $1 }' passwd                     # every username
awk -F: '$3 >= 1000 { print $1, $3 }' passwd      # username and UID where UID is 1000 or more
awk -F: '$7 == "/bin/bash" { print $1 }' passwd   # usernames whose shell is exactly /bin/bash
awk -F: '$3 < 1000' passwd | wc -l                # how many system accounts
df -h | awk '{ print $1, $5 }'                     # whitespace-separated columns
```

`awk` compares numbers **as numbers**. That is why it is the right tool for "UID of 1000 or more": a regex only sees characters.

### `sort`

| Option | Effect |
|---|---|
| (none) | alphabetical, character by character |
| `-n` | numeric; without it, `10` sorts before `9` because the character `1` comes before `9` |
| `-r` | reverse |
| `-t: -k3` | treat `:` as the separator and sort by field 3 |
| `-u` | drop duplicate lines |

```bash
sort -t: -k3 -n passwd | head -3      # the three lowest UIDs
```

### `uniq`

Removes **adjacent** duplicate lines, so it nearly always follows `sort`. `-c` prefixes each line with how many times it occurred; `-d` shows only lines that were duplicated.

### `wc`

Counts: `-l` lines, `-w` words, `-c` bytes. It prints the filename after the number unless it read from stdin (2.5).

### `head` and `tail`

`head -n 5 file` prints the first five lines; `tail -n 5 file` the last five. `tail -f file` keeps following a growing file, which is ideal for watching a log live. Press `Ctrl-C` to stop.

### `sed`: edit text as it flows past

`sed` (the *stream editor*) is most often used for substitution:

```bash
sed 's/nologin/NOLOGIN/' passwd | head -3      # first match on each line
sed 's/nologin/NOLOGIN/g' passwd | head -3     # g: every match on each line
cp passwd passwd.work
sed -i.bak 's/nologin/NOLOGIN/g' passwd.work   # edit the file IN PLACE, keep passwd.work.bak
```

Without `-i`, `sed` only prints the changed text and leaves the file alone. **With `-i`, it rewrites the file.** Always add a backup suffix (`-i.bak`) when using it on system files. The `old` part of `s/old/new/` is a regular expression, so everything in 3.3 applies.

### `tr`: translate or delete characters

Reads stdin only.

```bash
tr 'a-z' 'A-Z' < /etc/hostname     # to uppercase
tr -d '.' < /etc/hostname          # delete every "."
tr -s ' ' < some-file              # squeeze runs of spaces into one space
```

### Test yourself again: fields

Use the same `sample.txt` from 3.5. Predict first, then run.

```bash
cd /root/practice/regex
awk -F: '$3 >= 1000 { print $1 }' sample.txt            # 1
awk -F: '$7 == "/sbin/nologin" { print $1 }' sample.txt  # 2
cut -d: -f1 sample.txt                                   # 3
cut -s -d: -f1 sample.txt                                # 4
```

| # | Output | Why |
|---|---|---|
| 1 | `alice`, `bob` | UIDs 1001 and 1002 pass; 0 and 995 do not. Lines with no third field have an empty `$3`, which never counts as 1000 or more, so they are skipped |
| 2 | `bob`, `chroot-helper` | an exact comparison of the whole seventh field |
| 3 | the four usernames, then **every non-account line printed whole** (the comments, the blank line, `Server...`, the `colo...` lines), then `Error` and `error` | lines without `:` pass through untouched; the two error lines *do* contain `:`, so `cut` returns the text before it |
| 4 | `root`, `alice`, `bob`, `chroot-helper`, `Error`, `error` | `-s` drops lines with no delimiter, but the error lines still qualify |

Answer 3 is why a grader might reject a "list of usernames" file: stray lines crept in. Answer 4 shows that even `-s` is not a filter for *meaning*. When the input is not clean, select the right lines **first** (with `grep` or an `awk` condition), then extract the field.

### What goes wrong in Part 3

- Forgetting to quote patterns (3.4).
- Forgetting anchors: `grep root` also matches `chroot`, `rootfs`, and any line with `root` in another field.
- Using `+`, `|`, or `{}` without `-E`.
- Expecting `-c` to count occurrences; it counts **lines**.
- Using `cut` on space-padded columns.
- Using `uniq` without `sort`.

### How RHCSA tests Part 3

Typical phrasing: *"Find all lines in /usr/share/xyz containing the string abc and write them, in their original order, to /root/lines"*, or *"Save the names of all users whose shell is X to /root/users, one per line"*. A grader compares your file with the expected output, so exactness matters: no extra lines, no headers, the requested order, and only the requested fields.

**Verify** by counting (`wc -l`), by viewing (`cat`, `head`), and, where possible, with a second method that should give the same answer.

### Part 3 self-check

1. What is the difference between `grep root` and `grep '^root:'` on `/etc/passwd`?
2. Why does `grep 'a*' file` print every line?
3. What does `[^0-9]` match? What does `^[0-9]` match?
4. Why use `awk` rather than a regex to select UIDs of 1000 or more?
5. Why must `sort` come before `uniq -c`?
6. What is the difference between `sed 's/a/b/' file` and `sed -i 's/a/b/' file`?

---

# Part 4: Working with files and directories

> **Objective:** Create, delete, copy, and move files and directories.

## 4.1 Looking around: `pwd`, `cd`, `ls`

`pwd` prints the current directory. `cd` changes it: `cd` alone goes home, `cd -` goes back, `cd ..` goes up one level.

**`ls` options worth knowing, and why.**

| Option | Shows | Why |
|---|---|---|
| `-l` | long format: type, permissions, owner, size, date | the default for admin work |
| `-a` | hidden files (names starting with `.`) | many config files, such as `.bashrc`, are hidden |
| `-h` | human-readable sizes (K, M, G) | easier reading |
| `-d` | the directory **itself**, not its contents | checking a directory's own permissions |
| `-R` | recurse into subdirectories | see a whole tree |
| `-t`, `-r` | sort by time; reverse | `ls -ltr` puts the newest last, handy in log directories |
| `-i` | inode numbers | links (Part 5) |
| `-Z` | SELinux security labels | the security section |

**Reading a long listing.** Every column means something, and later parts rely on them.

```
-rw-r--r--.  1 root root  158 Sep 21 10:00 hosts
|         |  |  |    |     |   |            |
|         |  |  |    |     |   |            +-- name
|         |  |  |    |     |   +--------------- modification time
|         |  |  |    |     +------------------- size in bytes
|         |  |  |    +------------------------- group owner
|         |  |  +------------------------------ user owner
|         |  +--------------------------------- link count (Part 5)
|         +------------------------------------ "." SELinux label present; "+" ACL present
+---------------------------------------------- type (0.5) and permissions (Part 6)
```

```bash
ls -l /etc/hosts
ls -ld /etc          # the directory itself
ls -la /root         # including hidden files
```

## 4.2 Creating: `touch` and `mkdir`

**`touch`** has two jobs. If the file does not exist, it creates an **empty** one. If it does exist, it updates the file's timestamps to "now" and leaves the content alone.

**`mkdir`** creates directories.

| Form | Effect |
|---|---|
| `mkdir dir` | create one directory; fails if its parent does not exist |
| `mkdir -p a/b/c` | create **every missing parent**, and do not complain if it already exists |
| `mkdir -m 750 dir` | create it with a specific permission mode (Part 6) |

`-p` makes commands safe to repeat, which is why scripts and exam answers use it.

```bash
cd /root/practice
mkdir x/y/z            # fails: x does not exist
mkdir -p x/y/z         # works
mkdir -p x/y/z         # no error the second time
touch x/y/z/empty.txt
ls -lR x
```

## 4.3 Copying: `cp`

**Anatomy.**

```
cp [options] SOURCE DEST
cp [options] SOURCE... DIRECTORY
```

**How `cp` decides what `DEST` means.**

- If `DEST` is an existing **directory**, the file is copied **into** it, keeping its name.
- Otherwise, `DEST` is the **new file's name**.
- With **several** sources, the last argument **must** be an existing directory.

```bash
cd /root/practice
cp /etc/hosts .                     # into the current directory, as ./hosts
cp /etc/hosts hosts.copy            # a new name
mkdir -p copies
cp /etc/hosts /etc/hostname copies/
ls copies
```

**Copying a directory needs `-r`** (recursive), because a directory is a container and `cp` must be told to walk into it:

```bash
cp /etc/ssh ssh-copy        # error: -r not specified; omitting directory
cp -r /etc/ssh ssh-copy
```

**The trap: run the same command twice.** Apply the `DEST` rule above to a directory. The first time, `ssh-copy` does not exist, so `cp` **creates** it as the copy. The second time, `ssh-copy` **exists and is a directory**, so `cp` copies `ssh` **into** it:

```bash
cd /root/practice
mkdir -p twice/src && touch twice/src/file
cp -r twice/src twice/dest
cp -r twice/src twice/dest      # same command again
find twice/dest
```

You should see:

```
twice/dest
twice/dest/file
twice/dest/src
twice/dest/src/file
```

The identical command did two different things. On the exam this is how a "restore" ends up one level too deep, and a grader looking for `/backup/ssh/sshd_config` finds `/backup/ssh/ssh/sshd_config` instead. Check whether the destination exists **before** copying a directory, and inspect the result with `find` or `ls -R` afterwards.

**Copying a directory's contents, hidden files included.** Section 1.5 showed that `*` skips names starting with a dot. So `cp -a src/* dest/` silently leaves out `.bashrc`, `.ssh`, and friends. The fix is to copy `src/.`: the `.` entry means "this directory itself", so `cp` copies everything in it, hidden or not.

```bash
cd /root/practice
mkdir -p hid/src hid/star hid/dot
touch hid/src/visible hid/src/.hidden
cp -a hid/src/* hid/star/
cp -a hid/src/. hid/dot/
ls -A hid/star      # visible            (.hidden is missing)
ls -A hid/dot       # .hidden  visible
```

`ls -A` is like `ls -a` but leaves out the `.` and `..` entries, so hidden files stand out.

**What a copy keeps and what it loses.** A copy is a **brand-new file**.

| Attribute | Plain `cp` | `cp -p` | `cp -a` |
|---|---|---|---|
| content | copied | copied | copied |
| owner and group | **whoever runs `cp`** | preserved | preserved |
| permission bits | the source's bits, filtered by your umask (6.9); special bits dropped | preserved | preserved |
| timestamps | **now** | preserved | preserved |
| SELinux label and other extended attributes | set fresh for the new location | not preserved | preserved |
| recursive; symlinks copied as symlinks | no | no | **yes** |

`cp -a` ("archive") means `-R` plus preserve everything. It is the right choice for backups.

One more subtlety: if the destination file **already exists**, plain `cp` replaces its **content** but keeps the destination's existing owner and permissions.

**Try it.**

```bash
cd /root/practice
touch -d '2020-01-01 12:00' old.txt
chmod 640 old.txt
chown student old.txt
cp old.txt plain.txt
cp -p old.txt preserved.txt
ls -l old.txt plain.txt preserved.txt
```

`plain.txt` belongs to root and carries today's date. `preserved.txt` matches `old.txt` exactly.

**Why labels matter (a preview).** Every file carries a security label (`ls -Z` shows it), and SELinux uses that label to decide access. A new file created by `cp` gets the label that suits its **new** location. The security section builds on this.

**What goes wrong.**

- Plain `cp` when the task says "preserve".
- Forgetting `-r`, or running `cp -r` into a destination that already exists (the nesting trap above).
- Copying with `src/*` and losing hidden files.
- Not noticing that an existing destination was overwritten.
- **Fighting the `-i` prompt the wrong way.** On RHEL, root's `cp` is an alias for `cp -i` (1.4), so it asks before overwriting. You might expect `cp -f` to silence it. **It does not.** For `cp`, `-f` means something else ("if the destination cannot be opened, remove it and retry"), and the prompt from the alias's `-i` still appears. Use `\cp` (the backslash skips the alias, 1.4) when you truly want to overwrite without being asked. (For `rm` and `mv`, a later `-f` does override `-i`. `cp` is the odd one out.)

## 4.4 Moving and renaming: `mv`

**What it is.** `mv` moves or renames a file or directory. Renaming *is* moving to a new name. It follows the same `DEST` rules as `cp`.

**How it works.** It depends on whether the source and destination are on the same filesystem (the same partition or volume; the storage sections explain these):

- **Same filesystem:** `mv` only changes the directory entry that points at the file. The file's data, owner, permissions, timestamps, and **SELinux label all stay exactly as they were**. It is instant, even for huge files.
- **Different filesystems:** `mv` copies the data across and then deletes the original.

The fact that a same-filesystem `mv` **keeps the original SELinux label** is a classic cause of "the web server cannot read my file". A file created in `/root` and then moved into `/var/www/html` keeps the label that belongs to `/root`. You will fix exactly this situation in the security section.

```bash
cd /root/practice
mv hosts.copy hosts.renamed
mkdir -p moved
mv hosts.renamed moved/
ls moved
```

## 4.5 Deleting: `rm` and `rmdir`

**What it is.** `rm` removes files. `rm -r` removes directories together with everything inside them. `rmdir` removes only **empty** directories.

| Option | Effect |
|---|---|
| `-r` | recursive: directories and their contents |
| `-f` | force: never ask; ignore files that do not exist |
| `-i` | ask before each removal (root's default alias on RHEL) |
| `-v` | report each removal |

**There is no recycle bin.** A removed file is gone.

**Deleting is controlled by the directory, not by the file.** Removing a file changes the *directory's* list of names, so it requires **write and execute permission on the directory**. The file's own permissions do not matter. Part 6 explains why.

**Safety habits.**

- Before `rm` with a pattern, preview it: `echo rm /tmp/old*` or `ls /tmp/old*`.
- Chain with `&&`: `cd /some/dir && rm -rf ./*`.
- Reread `rm -rf` lines for stray spaces. `rm -rf / tmp/junk` (note the accidental space) targets `/`. Modern `rm` refuses to delete `/` itself, but it will delete anything else you point it at.

```bash
cd /root/practice
rmdir x            # fails: directory not empty
rm -r x
ls
```

## 4.6 Finding files: `find`

**What it is.** `find` walks a directory tree and, for every file and directory it meets, evaluates a list of **tests**. For each entry that passes, it performs an **action**. The default action is to print the path.

**Anatomy.**

```
find  STARTING-POINT...  [TESTS]         [ACTION]
find  /etc               -name '*.conf'  -print
```

**Common tests.**

| Test | True when |
|---|---|
| `-name 'PATTERN'` | the name matches a **glob** pattern (quote it!) |
| `-iname 'PATTERN'` | the same, ignoring case |
| `-type f`, `-type d`, `-type l` | regular file, directory, symbolic link |
| `-user NAME`, `-group NAME` | owned by that user, or that group |
| `-size +10M`, `-size -10k` | larger than 10 MiB; smaller than 10 KiB **after rounding up** (units: `c` bytes, `k`, `M`, `G`; see the rounding note below) |
| `-mtime -7`, `-mtime +30` | age in **whole days**: under 7 days; over 30 full days (see the rounding note below) |
| `-mmin -60` | modified within the last 60 minutes |
| `-perm 644` | permissions **exactly** 644 |
| `-perm -4000` | **all** of these bits set (here, SUID) |
| `-perm /022` | **any** of these bits set |
| `-maxdepth N` | do not descend more than N levels (write it before the other tests) |
| `-newer FILE` | modified more recently than `FILE` |

**Two rounding surprises: `-size` and `-mtime`.** Both tests compare **whole units**, and the rounding catches people out.

*Size rounds up.* `find` converts each file's size into the unit you asked for and **rounds up** to a whole number. A 9,500-byte file is 9.3 KiB, which becomes **10** in `k` units. So:

- `-size -10k` means "fewer than 10 units after rounding up", which in practice means **9 KiB or less**. The 9,500-byte file is **not** included.
- `-size -1M` rounds **every** non-empty file up to at least 1, so it matches **only empty files**. This one fools almost everyone.
- `+` behaves as you would expect: `-size +1M` really does mean "more than 1 MiB".
- **The fix:** when you need "smaller than", use a finer unit (`-size -1024k`) or bytes (`-size -1048576c`).

*Age rounds down.* `-mtime` measures age in whole **24-hour periods** and throws away the fraction. A file modified 36 hours ago has an age of 1.5 days, which counts as **1**. So:

- `-mtime 1` matches it (age exactly 1).
- `-mtime -1` does **not** (it needs an age below 1: modified within the last 24 hours).
- `-mtime +1` does **not** either (it needs an age above 1: at least 48 hours).
- So `-mtime +7` means "at least **8** full days old", not 7. When the hours matter, use `-mmin` in minutes instead.

Prove both yourself. `head -c 9500 /dev/zero > FILE` writes exactly 9,500 zero bytes into a file, and `touch -d` sets a file's time:

```bash
mkdir -p /root/practice/round && cd /root/practice/round
head -c 9500 /dev/zero > f9500
head -c 500  /dev/zero > f500
touch f0
find . -type f -size -10k                   # ./f500 and ./f0, but NOT ./f9500
find . -type f -size -1M                    # ./f0 only
touch -d '36 hours ago' old36
find . -name old36 -mtime 1                 # found
find . -name old36 -mtime -1                # nothing
find . -name old36 -mtime +1                # nothing
cd /root/practice
```

**Why the `-name` pattern must be quoted.** Without quotes, the *shell* expands `*.conf` against files in **your current directory** before `find` even starts (1.2 again). If there happens to be one `.conf` file where you are standing, `find` receives that single name and searches only for it.

**Combining tests.** Tests written one after another are joined by AND. Use `-o` for OR and `!` for NOT, and group with `\(` and `\)`. The backslashes stop the shell from interpreting the parentheses.

```bash
find /etc -type f -name '*.conf'                    # AND
find /etc \( -name '*.conf' -o -name '*.cfg' \)     # OR, grouped
find /tmp ! -user root                              # NOT
```

**Actions.**

| Action | Effect |
|---|---|
| `-print` | print the path (the default) |
| `-ls` | print details, like `ls -l` |
| `-delete` | delete each match. **Always run the same command with `-print` first.** |
| `-exec CMD {} \;` | run `CMD` once per match; `{}` is replaced by the path |
| `-exec CMD {} +` | run `CMD` once with many paths at a time (faster) |

Why `\;`? `find` needs a `;` argument to know where the `-exec` command ends, but a bare `;` would be consumed by the shell as its own command separator. The backslash passes it through to `find`.

**Try it.**

```bash
find /etc -maxdepth 1 -name '*.conf' | head
find /var/log -type f -size +100k
find /root/practice -type f -mmin -60
find /usr/bin -perm -4000 -type f             # SUID programs (Part 6)
find / -user student -type f 2> /dev/null     # files owned by student
mkdir -p /root/practice/found
find /etc -maxdepth 1 -type f -name 'host*' -exec cp -p {} /root/practice/found/ \;
ls -l /root/practice/found
```

**Verify.** Run the search with plain `-print` (or pipe it into `wc -l`) and read the list **before** adding `-exec` or `-delete`.

**`locate`** searches a prebuilt database of paths. It is fast, but it may not be installed, and its database is only as current as the last `updatedb` run. `find` always searches the real filesystem. Know `find` well.

**How RHCSA tests it.** *"Find all files owned by user X and copy them to /root/findfiles"*, or *"Find all files larger than 3 MiB in /usr/share and list them in /root/bigfiles"*. Read carefully: files only, or directories too? Preserve metadata? Full paths?

## 4.7 Inspecting files: `file` and `stat`

**`file`** reports what a file really contains by examining its bytes. Linux does not care about extensions: a file named `report.pdf` might be plain text, and `file` will say so.

**`stat`** shows everything the system records about a file:

```bash
stat /etc/hosts
```

You will see the size, the **inode** number and **link count** (Part 5), the permissions in octal and symbolic form (Part 6), the owner and group, the SELinux context, and three timestamps:

| Timestamp | Updated when |
|---|---|
| Access (atime) | the content is read (often updated lazily) |
| Modify (mtime) | the **content** changes; this is the time `ls -l` shows |
| Change (ctime) | the **metadata** changes (permissions, owner, links), or the content changes |

`stat -c` prints only the fields you choose, which makes precise verification easy:

```bash
stat -c '%U %G %a %n' /etc/hosts     # owner, group, octal mode, name
```

### Part 4 self-check

1. You run `cp report.txt /backup`. What happens if `/backup` is a directory? If it does not exist?
2. Which attributes does plain `cp` change that `cp -p` preserves?
3. Why does `mv` within one filesystem keep the original SELinux label?
4. What permission do you need in order to delete a file?
5. Why must you write `find / -name '*.log'` with quotes?
6. What is the difference between `-perm -4000` and `-perm 4000`?
7. You run `cp -r /etc/ssh /backup/ssh` twice. Where does `sshd_config` end up after the second run?
8. Why does `find /var -size -1M` return only empty files?
9. How do you copy everything in `/home/alice`, hidden files included, into an existing `/backup/alice`?

---

# Part 5: Links and inodes

> **Objective:** Create hard and soft links.

## 5.1 What a filename really is

To understand links you need one more piece of how Linux stores files. A file is really **three separate things**:

1. **Data blocks:** the actual content, somewhere on the disk.
2. **The inode:** a record holding everything *about* the file: its type, permissions, owner, group, size, timestamps, link count, and where its data blocks are. Every inode has a number, unique **within its filesystem**. Notice what the inode does **not** hold: the file's **name**.
3. **Directory entries:** a directory is essentially a table that maps **names to inode numbers**. The name `hosts` in `/etc` is just one row in that table, saying "`hosts` means inode 1234567".

```
directory /etc                      inode 1234567                data blocks
+----------+------------+           +--------------------+       +--------------+
| hosts    | 1234567 ---|---------->| type: file         |------>| 127.0.0.1 ...|
| hostname | 1234599    |           | mode: rw-r--r--    |       +--------------+
| ...      |            |           | owner: root        |
+----------+------------+           | links: 1           |
                                    +--------------------+
```

A library analogy: the inode is the book itself, together with its catalogue record. Directory entries are index cards that point to the book. Several cards can point to the same book.

**Try it.**

```bash
ls -i /etc/hosts
stat /etc/hosts | grep -E 'Inode|Links'
```

## 5.2 Hard links

**What it is.** A **hard link** is an extra directory entry that points to an **existing inode**. It is another **name** for exactly the same file.

**Anatomy.** The argument order matches `cp`: the thing that already exists first, then the new name.

```
ln  EXISTING_FILE  NEW_NAME
```

**How it works.**

- Creating a hard link increases the inode's **link count** by one.
- All names are **equal**. There is no "original" and no "copy"; each is simply a name for the same inode.
- A change made through one name is visible through every other name, because there is only one file.
- Removing a name decreases the link count. The data is freed only when the count reaches zero (and no running program still has the file open).

**Limits, and why they exist.**

- **Same filesystem only.** Inode numbers are unique only within one filesystem, so a directory entry cannot refer to an inode on a different one. Trying gives `Invalid cross-device link`.
- **No hard links to directories.** They could create loops in the tree that tools would never finish walking. (Directories do have a link count: a new directory starts at 2, for its name in the parent plus its own `.` entry, and each subdirectory adds one through its `..` entry.)

**Try it.**

```bash
cd /root/practice
mkdir -p links && cd links
echo "version 1" > data.txt
ln data.txt hard.txt
ls -li
```

Both names show the **same inode number** and a link count of `2`.

```bash
echo "version 2" >> hard.txt
cat data.txt                  # both lines: one file, two names
rm data.txt
cat hard.txt                  # still works: the inode still has a name
stat -c '%h %n' hard.txt      # link count is back to 1
```

## 5.3 Symbolic (soft) links

**What it is.** A **symbolic link** (symlink, soft link) is a separate, tiny file whose content is a **path**. When a program opens the symlink, the kernel reads that path and opens whatever it leads to.

**Anatomy.**

```
ln -s  TARGET_PATH  LINK_NAME
```

**How it works.**

- The symlink has **its own inode**; all it stores is a path string.
- It can point **across filesystems** and to **directories**, because it stores a path rather than an inode number.
- If the target is deleted or moved, the symlink becomes **dangling** (broken): the path it stores no longer leads anywhere.
- `ls -l` shows type `l` and `name -> target`. Its own permissions always display as `lrwxrwxrwx` and are ignored; access is decided by the **target's** permissions.

**The relative-target trap.** A relative target is resolved relative to **the directory that contains the link**, not relative to where you were standing when you created it.

```bash
cd /root/practice/links
echo hello > target.txt
ln -s target.txt /tmp/badlink                        # stores the text "target.txt"
cat /tmp/badlink                                     # FAILS: it looks for /tmp/target.txt
ln -s /root/practice/links/target.txt /tmp/goodlink
cat /tmp/goodlink                                    # works
rm /tmp/badlink /tmp/goodlink
```

Use an **absolute** target when the link and the target live in different places, or when the target is a fixed system path. Use a relative target when link and target always move together.

**Try it.**

```bash
cd /root/practice/links
ln -s hard.txt soft.txt
ls -li
cat soft.txt
readlink soft.txt            # the path stored in the link
readlink -f soft.txt         # the fully resolved final path
mv hard.txt moved.txt
cat soft.txt                 # broken: dangling link
ls -l soft.txt
mv moved.txt hard.txt        # restore the target
cat soft.txt                 # works again
ln -sf /etc/hosts soft.txt   # -f replaces an existing link
readlink soft.txt
```

**Symlinks are everywhere on RHEL.** `/bin` is a symlink to `usr/bin`. `/etc/localtime` is a symlink to your time zone's file. And when you **enable** a service with `systemctl enable` (a later section), systemd creates a symlink. Recognizing them now makes those sections easier.

## 5.4 Hard versus soft

| | Hard link | Symbolic link |
|---|---|---|
| Points to | an **inode** | a **path** |
| Has its own inode | no, it shares the target's | yes |
| Across filesystems | **no** | yes |
| To a directory | **no** | yes |
| If the original name is deleted | still works; the data survives | **breaks** (dangling) |
| In `ls -l` | looks like an ordinary file with a link count above 1 | type `l`, shows `-> target` |
| Permissions that apply | the shared inode's | the target's |

**Verify.**

```bash
ls -li NAME1 NAME2           # hard link: the same inode number
stat -c '%i %h %n' NAME      # inode number, link count, name
readlink -f LINK             # symlink: where it finally leads
test -L LINK && echo "is a symlink"
```

**What goes wrong.**

- Reversing the arguments. It is `ln EXISTING NEW`, like `cp`.
- A relative symlink target that only makes sense from your current directory.
- Trying to hard link across filesystems, or to a directory.

**How RHCSA tests it.** *"Create a hard link /x/y to the file /a/b"* or *"Create a symbolic link ..."*. Graders check the inode for hard links and the resolved path for symlinks, so verify both ways.

### Part 5 self-check

1. What does an inode hold, and what important thing does it not hold?
2. After `ln a b` and then `rm a`, can you still read `b`? Why?
3. After `ln -s a b` and then `rm a`, can you still read `b`? Why?
4. Why can't you hard link from `/home` to `/var` if they are separate filesystems?
5. You are in `/root` and run `ln -s notes.txt /tmp/n`. What path does `/tmp/n` try to open?

---

# Part 6: Permissions

> **Objective:** List, set, and change standard ugo/rwx permissions.

## 6.1 Why permissions exist

Linux is a multi-user system. Permissions protect users from one another and protect the system from its users. The model is simple:

- Every **file** has a **user owner**, a **group owner**, and a set of **permission bits** (its *mode*).
- Every **process** runs as a **user** (a UID) and carries a set of **groups** (0.3, 0.6).

Whenever a process tries to read, write, or execute something, the kernel compares the process's identity with the file's owner, group, and mode.

## 6.2 How the kernel decides: first match wins

This is the rule most people get subtly wrong. The kernel checks **in order** and uses **only the first category that applies**:

1. **Is the process running as root (UID 0)?** Reading and writing are allowed regardless of the bits. (Executing is allowed if at least one `x` bit is set anywhere.)
2. **Otherwise, is the process's UID the file's owner?** Use the **owner** bits, and **only** the owner bits.
3. **Otherwise, is the file's group one of the process's groups?** Use the **group** bits only.
4. **Otherwise,** use the **other** bits.

The categories are **not added together**. If you own a file whose owner bits are `---`, you are refused even when the group and other bits allow everything.

**Try it: prove "first match wins".** Create two test users first. As root you can switch to them without a password, and you will reuse them throughout this part.

```bash
useradd alice
useradd bob
mkdir -p /srv/permtest
cd /srv/permtest
echo "surprise" > owned.txt
chown alice owned.txt
chmod 077 owned.txt                           # owner ---, group rwx, other rwx
ls -l owned.txt                               # ----rwxrwx
su - alice -c 'cat /srv/permtest/owned.txt'   # Permission denied
su - bob   -c 'cat /srv/permtest/owned.txt'   # works: bob falls into "other"
```

Alice owns the file and is refused. Bob, a stranger, is allowed. Alice matched "owner" first, so the kernel never looked at the other bits.

## 6.3 Reading the mode string

```
-rwxr-x---.
| |  |  |  |
| |  |  |  +-- "." SELinux label present, "+" ACL present (later sections)
| |  |  +----- other:        ---  no access
| |  +-------- group:        r-x  read and execute
| +----------- user (owner): rwx  read, write, execute
+------------- type: - file, d directory, l symlink ...
```

Each triplet is always in the order **r**ead, **w**rite, e**x**ecute. A `-` in a position means that permission is off.

## 6.4 What r, w, and x mean: files versus directories

On a file, the meanings are intuitive. On a directory they are different, and this is where most permission problems come from.

**Remember from 5.1: a directory is a table of names.** Each permission controls what you may do **with that table**.

| Bit | On a file | On a directory |
|---|---|---|
| `r` | read the content | **list** the names in the table (`ls`) |
| `w` | change the content | **change the table**: create, delete, or rename entries |
| `x` | run it as a program | **use** the directory: enter it (`cd`) and reach things inside it by name |

Consequences worth memorizing:

- **Deleting a file requires `w` and `x` on its directory.** The file's own permissions are irrelevant, because deleting removes a row from the directory's table. You can delete a file you cannot even read if you have write access to its directory.
- **You need `x` on every directory along a path.** To open `/srv/a/b/file`, you need `x` on `/`, `/srv`, `/srv/a`, and `/srv/a/b`. A missing `x` anywhere blocks everything below it. This is why other users cannot reach anything under `/root`: its mode is `dr-xr-x---`.
- **`r` without `x` on a directory** lets you list names but not open anything inside or see details.
- **`x` without `r`** lets you open a file whose exact name you already know, but not list the directory.

| Directory bits (for you) | Can list? | Can open files inside by name? | Can create or delete? |
|---|---|---|---|
| `r-x` | yes | yes | no |
| `rwx` | yes | yes | yes |
| `--x` | no | yes | no |
| `r--` | names only | no | no |
| `-wx` | no | yes | yes (a "drop box") |

**Try it.**

```bash
mkdir /srv/permtest/vault
echo secret > /srv/permtest/vault/file.txt
chmod 644 /srv/permtest/vault/file.txt
chmod 711 /srv/permtest/vault                     # other: --x
su - bob -c 'ls /srv/permtest/vault'              # Permission denied: no r
su - bob -c 'cat /srv/permtest/vault/file.txt'    # works: has x and knows the name
chmod 744 /srv/permtest/vault                     # other: r--
su - bob -c 'ls /srv/permtest/vault'              # the name is listed
su - bob -c 'cat /srv/permtest/vault/file.txt'    # Permission denied: no x
```

**A tool for path problems: `namei -l`.** It shows the permissions of **every** component of a path, so a missing `x` stands out:

```bash
namei -l /srv/permtest/vault/file.txt
```

## 6.5 Octal (numeric) notation

**What it is.** Each permission is one bit with a value:

| Permission | Value |
|---|---|
| `r` | 4 |
| `w` | 2 |
| `x` | 1 |

Add the values for each of user, group, and other, and you get three digits:

| Digit | Sum | Bits |
|---|---|---|
| 7 | 4+2+1 | `rwx` |
| 6 | 4+2 | `rw-` |
| 5 | 4+1 | `r-x` |
| 4 | 4 | `r--` |
| 3 | 2+1 | `-wx` |
| 2 | 2 | `-w-` |
| 1 | 1 | `--x` |
| 0 | 0 | `---` |

**Why octal?** One octal digit covers exactly three bits, which is exactly one triplet.

**Converting.**

- `rwxr-x---`: `rwx` = 7, `r-x` = 5, `---` = 0, so **750**.
- `rw-r--r--`: 6, 4, 4, so **644**.
- **640**: 6 = `rw-`, 4 = `r--`, 0 = `---`, so `rw-r-----`.

Modes to recognize instantly: `755` (programs and ordinary directories), `644` (ordinary files), `700` and `600` (private), `750` and `640` (owner plus group, nobody else).

A **fourth, leading digit** holds the special bits (6.8), as in `2775`, `1777`, and `4755`.

## 6.6 `chmod`: changing permissions

`chmod` accepts two notations.

**Numeric** sets **every** bit to exactly what you give:

```bash
chmod 640 file
chmod 755 dir
```

**Symbolic** changes **selected** bits and leaves the rest alone:

```
chmod  WHO    OPERATOR  PERMISSIONS   file
       u g o a  + - =     r w x  (X s t)
```

| Part | Choices |
|---|---|
| who | `u` user/owner, `g` group, `o` other, `a` all (used if you omit who) |
| operator | `+` add, `-` remove, `=` set exactly (anything not listed for that category is turned off) |
| permissions | `r`, `w`, `x`, and the special letters `X`, `s`, `t` explained below |

```bash
chmod u+x script.sh
chmod g-w,o-rwx file
chmod u=rw,g=r,o= file      # "o=" with nothing after it: other gets no permissions
chmod a+r file
```

**Which to use.** If the task states the **final** permissions ("mode 0640", "readable and writable only by the owner"), numeric is direct and unambiguous. If the task says "**also** allow" or "remove **only**", symbolic changes exactly that and cannot accidentally alter anything else.

**Recursive changes and the capital `X`.** `chmod -R 755 dir` makes every *file* executable, which is wrong. `chmod -R 644 dir` strips `x` from every *subdirectory*, which makes them unusable (6.4). A capital `X` solves this: it means "execute, but only for directories and for files that already have an execute bit somewhere".

```bash
chmod -R u=rwX,g=rX,o= /srv/project    # directories get x; ordinary files do not
```

**Try it.**

```bash
cd /srv/permtest
touch f.txt
chmod 600 f.txt              ; stat -c '%a %A' f.txt
chmod g+r f.txt              ; stat -c '%a %A' f.txt
chmod u=rwx,g=rx,o=r f.txt   ; stat -c '%a %A' f.txt
chmod a-x f.txt              ; stat -c '%a %A' f.txt
```

`stat -c '%a %A'` prints the mode in both octal and symbolic form, a quick way to check your conversions.

## 6.7 `chown` and `chgrp`: changing ownership

```bash
chown alice file              # change the owner
chown alice:alice file        # owner and group together
chown :bob file               # group only (same as: chgrp bob file)
chgrp bob file
chown -R alice:alice /srv/x   # recursive
```

**Who may do this?** Only **root** may change a file's **owner**. (Otherwise users could hand files to others to dodge disk quotas or to frame someone.) A file's owner may change its **group**, but only to a group they belong to.

**Verify.**

```bash
stat -c '%U:%G %a %n' file
ls -l file
```

## 6.8 Special permissions: SUID, SGID, and sticky

Three extra bits live in the leading fourth octal digit.

| Bit | Octal | Symbolic | On an executable file | On a directory |
|---|---|---|---|---|
| **SUID** | 4000 | `u+s` | the program runs as the **file's owner**, not as whoever started it | ignored on Linux |
| **SGID** | 2000 | `g+s` | the program runs with the **file's group** | **new files inside inherit the directory's group** |
| **Sticky** | 1000 | `o+t` | no effect | only a file's **owner** (or the directory's owner, or root) may delete or rename it |

**Why each one exists.**

- **SUID:** a regular user must be able to change their own password, which means writing to `/etc/shadow`, which only root may write. `/usr/bin/passwd` is owned by root and has SUID set, so it runs as root on the user's behalf and carefully changes only that user's entry. (Linux ignores SUID on shell scripts; it applies only to compiled programs.)
- **SGID on a directory:** without it, a new file takes the **creator's primary group**. In a shared team directory, every file would then belong to a different personal group and teammates could not collaborate. With SGID set, every new file automatically takes the directory's group. **This is the standard answer to "create a shared directory for a group".**
- **Sticky on a directory:** `/tmp` must be writable by everyone, but write access to a directory alone would let anyone delete anyone else's files (6.4). The sticky bit adds "only the owner may delete". `/tmp` has mode `1777`.

**How they display.** They appear in the `x` position of the relevant triplet:

```
-rwsr-xr-x    SUID     (s in the owner's x position)
drwxrwsr-x    SGID     (s in the group's x position)
drwxrwxrwt    sticky   (t in the other's x position)
```

A **lowercase** `s` or `t` means the `x` underneath is also set. An **uppercase** `S` or `T` means the special bit is set but `x` is not. For SUID and SGID, an uppercase letter is almost always a mistake: `drwxrwSr-x` means group members cannot even enter the directory. For the sticky bit on a directory that others cannot access at all (for example mode `3770`, shown as `drwxrws--T`), an uppercase `T` is expected and fine.

**Setting them.**

```bash
chmod 2775 /srv/team            # SGID plus rwxrwxr-x
chmod g+s /srv/team             # add only SGID
chmod 1777 /srv/drop            # sticky plus rwxrwxrwx
chmod o+t /srv/drop             # add only sticky
chmod u+s /usr/local/bin/tool   # SUID (use rarely: it is a security risk)
```

**A GNU `chmod` detail that surprises people.** On a **directory**, a three-digit numeric mode such as `chmod 775 dir` **keeps** an existing SUID or SGID bit instead of clearing it. To remove one, use symbolic notation (`chmod g-s dir`) or an extra leading zero (`chmod 00775 dir`). Always confirm with `ls -ld` afterward.

**Try it.**

```bash
groupadd team
usermod -aG team alice
usermod -aG team bob
mkdir /srv/permtest/shared
chgrp team /srv/permtest/shared
chmod 2770 /srv/permtest/shared
ls -ld /srv/permtest/shared                        # drwxrws---
su - alice -c 'touch /srv/permtest/shared/a.txt'
ls -l /srv/permtest/shared/a.txt                   # group is team, not alice

chmod +t /srv/permtest/shared                      # now mode 3770
ls -ld /srv/permtest/shared                        # drwxrws--T
su - bob -c 'rm -f /srv/permtest/shared/a.txt'     # Operation not permitted
```

Bob is in `team` and the directory is group-writable, yet he cannot delete Alice's file: that is the sticky bit at work.

**Security note.** SUID programs run with their owner's power, so unexpected SUID files are a classic attack path. List them with `find / -perm -4000 -type f 2> /dev/null`.

## 6.9 `umask`: default permissions for new files

**What it is.** When a program creates a file, it requests a starting mode, and the kernel **removes** the bits listed in the process's **umask** (user file-creation mask).

**How it works.**

- Programs normally request **666** (`rw-rw-rw-`) for new files and **777** (`rwxrwxrwx`) for new directories. Files do not get `x` by default, because most files are not programs.
- The umask lists bits to turn **off**. It is a mask, not arithmetic subtraction: any bit set in the umask is cleared, and a bit that was already off simply stays off.

| umask | New file (from 666) | New directory (from 777) |
|---|---|---|
| `022` | 644 `rw-r--r--` | 755 `rwxr-xr-x` |
| `002` | 664 `rw-rw-r--` | 775 `rwxrwxr-x` |
| `027` | 640 `rw-r-----` | 750 `rwxr-x---` |
| `077` | 600 `rw-------` | 700 `rwx------` |

Why "a mask, not subtraction" matters: with umask `033`, a new file gets **644**, not 633. The file never had any `x` bits (it started from 666), so masking them off changes nothing. Subtraction would give the wrong answer.

**Anatomy.**

```bash
umask          # show the current mask, e.g. 0022
umask -S       # show it as the permissions that REMAIN, e.g. u=rwx,g=rx,o=rx
umask 027      # change it, for this shell only
```

**Where it comes from and how to make it last.** `umask` is a shell setting. Programs you start inherit it, and it disappears when the shell exits. RHEL sets a default at login (typically `0022` for root, and often `0002` for regular users who have their own private group; check with `umask` as each user). To make a change permanent: `~/.bashrc` for one user, or a `.sh` file in `/etc/profile.d/` for everyone. The security section returns to this.

**Try it.**

```bash
cd /srv/permtest
umask
umask 077
touch private.txt
mkdir private.d
ls -ld private.txt private.d     # rw------- and rwx------
umask 022
```

## 6.10 A method for permission problems

When access is denied, work through this list:

1. **Who is the process?** `id` or `id USER`. Note the UID and every group.
2. **Can it reach the file?** `namei -l /full/path`. Look for a directory on the path missing `x` for this user.
3. **Which category applies?** Owner, else group, else other (6.2). Read **only** that triplet.
4. **Is it the right kind of permission?** Reading needs `r` on the file. Writing needs `w` on the file. Creating, deleting, or renaming needs `w` **and** `x` on the **directory**.
5. **Still denied although the bits look right?** A `+` in `ls -l` means an ACL applies, and SELinux can deny access the bits would allow. Both are covered in later sections.

**What goes wrong in Part 6.**

- Assuming owner, group, and other permissions add up.
- Fixing a file's mode when the real problem is a directory on the path.
- `chmod -R` with a mode that puts `x` on files or strips it from directories.
- An uppercase `S` from setting SGID on a directory without group `x`.
- Expecting a group change to apply in a session that was already logged in (Part 9 explains why).

**How RHCSA tests Part 6.** *"Create /x owned by group Y; members of Y can create files there; files created there belong to Y; other users have no access"* (SGID). *"Only a file's owner may delete it"* (sticky). *"File Z must be readable and writable by its owner only"* (600). Graders check exact modes, owners, and groups, and may test access as specific users. **Verify with `stat -c '%U:%G %a'` and by trying the operation as the relevant user with `su - USER -c '...'`.**

**Clean up** the test users and directory when you finish this part:

```bash
cd /root
userdel -r alice
userdel -r bob
groupdel team
rm -rf /srv/permtest
```

### Part 6 self-check

1. A file is `----rw-rw-` and you own it. Can you read it? Why?
2. Which permissions do you need on a directory to delete a file inside it?
3. Convert `rwxr-x--x` to octal, and `640` to symbolic.
4. What does `chmod -R u=rwX,g=rX,o= dir` do differently from `chmod -R 750 dir`?
5. What does SGID do on a directory, and why is it useful?
6. With umask `027`, what mode does a new file get? A new directory?

---

# Part 7: Creating and editing text files

> **Objective:** Create and edit text files.

## 7.1 Why editing matters, and which editor

Almost every configuration task ends with changing a text file. On a minimal RHEL install, the editor you can always count on is **vi**/**vim**. (`vi` comes from the always-installed `vim-minimal` package; the fuller `vim` comes from `vim-enhanced`.) Other editors such as `nano` may not be installed. Learn vim well enough that it never slows you down.

## 7.2 The idea that makes vim make sense: modes

**What it is.** vim is a **modal** editor: the same key does different things depending on which mode you are in.

| Mode | What keys do | How to get there |
|---|---|---|
| **Normal** | keys are **commands** (move, delete, copy, paste) | vim starts here; `Esc` always returns here |
| **Insert** | keys type **text** | `i`, `a`, `o` and others, from Normal mode |
| **Command-line** | type a command at the bottom of the screen (save, quit, search and replace) | `:` from Normal mode |

```
              i  a  o  A  O
   NORMAL  ----------------->  INSERT
     ^  |  <-----------------
     |  |         Esc
     |  |  :
     |  v
   COMMAND-LINE   (Enter runs the command and returns to Normal; Esc cancels)
```

**Why it works this way.** vim descends from `vi`, which was designed for slow terminals with no mouse. Making every key a command in Normal mode gives you powerful editing without a mouse or menus.

**Knowing where you are.** Insert mode shows `-- INSERT --` at the bottom left. If you are ever unsure, press `Esc` twice. You are now in Normal mode.

## 7.3 Survival: open, edit, save, quit

```bash
vim /root/practice/notes.txt
```

1. Press `i` to enter Insert mode, and type a few lines.
2. Press `Esc` to return to Normal mode.
3. Type `:wq` and press Enter to **w**rite (save) and **q**uit.

| Command | Does |
|---|---|
| `:w` | save |
| `:q` | quit; refuses if there are unsaved changes (`E37: No write since last change`) |
| `:wq` or `:x` | save and quit |
| `:q!` | quit **and discard** changes |
| `:w!`, `:wq!` | force the write, for example to a read-only file you are allowed to change |
| `:e!` | throw away changes since the last save and reload the file |

## 7.4 Moving around (Normal mode)

| Keys | Move |
|---|---|
| arrow keys, or `h` `j` `k` `l` | left, down, up, right |
| `w`, `b` | forward one word, back one word |
| `0`, `$` | start of line, end of line |
| `gg`, `G` | first line, last line |
| `:42` or `42G` | line 42 |
| `Ctrl-f`, `Ctrl-b` | page down, page up |

## 7.5 Editing (from Normal mode)

| Keys | Does |
|---|---|
| `i`, `a` | insert before the cursor, after the cursor |
| `I`, `A` | insert at the start of the line, at the end of the line |
| `o`, `O` | open a new line below, above, and start inserting |
| `x` | delete the character under the cursor |
| `dd` | delete (cut) the whole line |
| `dw` | delete to the end of the word |
| `D` | delete to the end of the line |
| `yy` | yank (copy) the line |
| `p`, `P` | paste after, before |
| `cw` | change a word (delete it and enter Insert mode) |
| `r` then a character | replace one character |
| `u`, `Ctrl-r` | undo, redo |
| `.` | repeat the last change |

A number before a command repeats it: `3dd` deletes three lines, `5j` moves down five lines.

## 7.6 Searching and replacing

| Command | Does |
|---|---|
| `/text` | search forward; `n` for the next match, `N` for the previous |
| `?text` | search backward |
| `:s/old/new/` | replace the first match on the current line |
| `:%s/old/new/g` | replace **every** match in the **whole file** (`%` means every line, `g` every match on each line) |
| `:%s/old/new/gc` | the same, but ask before each replacement |

The search pattern is a **regular expression** (Part 3). To work with paths that contain `/`, use another separator: `:%s#/old/path#/new/path#g`.

## 7.7 Useful extras

| Command | Does |
|---|---|
| `:set nu`, `:set nonu` | show, hide line numbers |
| `:set list` | show hidden characters: tabs as `^I`, line ends as `$` |
| `:r /path/file` | insert another file below the cursor |
| `:r !command` | insert the output of a command |
| `v`, `V`, `Ctrl-v` | select by character, by line, or as a block; then `d`, `y`, or `>` |

## 7.8 The swap file warning

If vim was interrupted (the connection dropped, the VM was reset) or the file is already open in another session, you will see `E325: ATTENTION ... Found a swap file`. vim keeps unsaved changes in a hidden `.swp` file and is warning you about it.

- If you are sure nobody else is editing and you do not need any unsaved work, press `D` to delete the swap file, or `E` to edit anyway.
- If you may have lost work, press `R` to recover it, save, and then delete the old swap file.

## 7.9 Practise with `vimtutor`

Run `vimtutor`. It is a 30-minute interactive lesson inside vim and the fastest way to build real fluency. If the command is not found, use the technique from Part 11: `dnf provides '*/vimtutor'` tells you which package supplies it.

## 7.10 Creating files without an editor

| Method | Best for |
|---|---|
| `touch file` | an empty file |
| `echo "text" > file` | a single line |
| `printf 'line1\nline2\n' > file` | a few lines; `printf` handles `\n` consistently, unlike `echo` |
| `cat > file <<'EOF'` ... `EOF` | a whole configuration block (2.5) |

**Verify content exactly.** `cat file` shows the text. `cat -A file` also reveals invisible characters: `$` at the end of each line and `^I` for each tab. Stray spaces and tabs break some configuration files, and `cat -A` exposes them.

**How RHCSA tests Part 7.** Indirectly, in almost every task: editing `/etc/fstab`, a service configuration, a cron entry, a sudoers file. Fast, accurate vim use turns directly into time for other tasks.

### Part 7 self-check

1. You are typing text and want to save and quit. What do you press, in order?
2. What is the difference between `:q` and `:q!`?
3. How do you replace every `http` with `https` in the whole file?
4. From the shell, how do you reveal the tab characters in a file?

---

# Part 8: Archiving and compression

> **Objective:** Archive, compress, unpack, and uncompress files using tar, gzip, and bzip2.

## 8.1 Two different ideas

**Archiving** combines many files and directories, **with their metadata**, into **one** file. **Compressing** makes data **smaller**. They are separate jobs done by separate tools:

| Job | Tool | Result |
|---|---|---|
| archive | `tar` | `backup.tar` |
| compress | `gzip`, `bzip2`, `xz` | `file.gz`, `file.bz2`, `file.xz` |
| both | `tar` calling a compressor | `backup.tar.gz`, `backup.tar.bz2`, `backup.tar.xz` |

**Why separate?** Compressors work on a single stream of bytes and know nothing about files or directories. `tar` turns a whole tree into one stream, which a compressor can then shrink. The name `tar` comes from **t**ape **ar**chive: it was built to write directory trees onto backup tapes.

**What a tar archive stores:** file contents, relative paths, permissions, ownership, timestamps, and symbolic links. It can **optionally** store ACLs, extended attributes, and SELinux labels, but only when you ask (8.5).

## 8.2 `tar` anatomy

```
tar  MODE  [options]  -f ARCHIVE  [files or directories...]
```

**Exactly one mode:**

| Mode | Meaning |
|---|---|
| `-c` | **c**reate a new archive |
| `-t` | lis**t** the contents |
| `-x` | e**x**tract |

**Common options:**

| Option | Meaning |
|---|---|
| `-f FILE` | the archive **f**ile's name. Always use it. It takes a value, so it goes **last** in a bundle (1.1). |
| `-v` | **v**erbose: print each file as it is processed |
| `-z` | compress or decompress with **gzip** (`.tar.gz`, `.tgz`) |
| `-j` | with **bzip2** (`.tar.bz2`) |
| `-J` | with **xz** (`.tar.xz`) |
| `-C DIR` | change into `DIR` first (where to extract to, or where to archive from) |
| `--exclude=PATTERN` | leave matching files out |
| `-p` | keep the archived permissions when extracting (the default when running as root) |

**Read commands aloud.** `tar -czvf /root/etc.tar.gz /etc` reads as: "**c**reate, g**z**ip, **v**erbose, **f**ile `/root/etc.tar.gz`, containing `/etc`."

The leading dash is optional for tar's bundled letters (`tar czvf ...` is the traditional style). Both forms work.

**Reading detects compression for you; creating does not.** GNU `tar` recognizes the compression format automatically when listing or extracting, so `tar -xf file.tar.bz2` works without `-j`. **When creating, you must choose** `-z`, `-j`, or `-J`, or the archive is not compressed at all, whatever you name it.

## 8.3 Paths inside the archive, and where extraction goes

**The leading `/` is removed.** Archive `/etc/sysconfig` and tar prints:

```
tar: Removing leading `/' from member names
```

This is normal and deliberate. The archive stores `etc/sysconfig/...` as a **relative** path, so extracting it cannot silently overwrite live system files.

**Extraction happens relative to your current directory**, unless you use `-C`. Extract that archive while standing in `/root` and you get `/root/etc/sysconfig/...`. This surprises beginners who expected the files to go "back where they came from".

```bash
tar -xzf backup.tar.gz -C /tmp/restore      # extract under /tmp/restore
```

The directory given to `-C` must already exist.

**`-C` while creating** controls how paths are stored:

```bash
tar -czf a.tar.gz /etc/sysconfig            # stored as etc/sysconfig/...
tar -czf b.tar.gz -C /etc sysconfig         # stored as sysconfig/...
```

**Extracting a single item:** name it exactly as it is stored (as `-t` shows it, with no leading `/`):

```bash
tar -xzf a.tar.gz etc/sysconfig/<name-exactly-as-tar-t-shows-it>
```

## 8.4 Look before you leap: `-t`

List an unfamiliar archive before extracting it, and list your own archives after creating them to verify:

```bash
tar -tf archive.tar.gz          # names only
tar -tvf archive.tar.gz         # with permissions, owners, sizes, dates
```

## 8.5 Metadata: ownership, permissions, SELinux labels

- **Ownership** is restored on extraction only when you extract **as root**. As a regular user, extracted files belong to you.
- **Permissions** are restored when extracting as root (or with `-p`).
- **SELinux labels, extended attributes, and ACLs** are saved **only** if you ask when creating, and restored only if you ask again when extracting:

```bash
tar --selinux --xattrs --acls -czf ssh-backup.tar.gz /etc/ssh
tar --selinux --xattrs --acls -xzf ssh-backup.tar.gz -C /some/restore/dir
```

Why it matters: without their labels, restored system files get whatever label suits their new location, and services may be denied access to them (the security section explains why).

## 8.6 The standalone compressors

`gzip`, `bzip2`, and `xz` share nearly the same interface:

| Task | gzip | bzip2 | xz |
|---|---|---|---|
| compress (**replaces the original**) | `gzip file` makes `file.gz` | `bzip2 file` makes `file.bz2` | `xz file` makes `file.xz` |
| keep the original too | `gzip -k file` | `bzip2 -k file` | `xz -k file` |
| decompress | `gunzip file.gz` or `gzip -d` | `bunzip2 file.bz2` or `bzip2 -d` | `unxz file.xz` or `xz -d` |
| read without decompressing to disk | `zcat` | `bzcat` | `xzcat` |
| compression level | `-1` (fast) to `-9` (smallest) | same | same |

**Two surprises:**

- **By default, compressing replaces the original file** with the compressed one. Add `-k` to keep it.
- **They compress single files, not directories.** To compress a directory, `tar` it with `-z`, `-j`, or `-J`.

**Choosing.** gzip is the fastest with the least compression, bzip2 sits in the middle, and xz produces the smallest files but is the slowest. If a task names a format, use that format.

**Helpers:** `zgrep` and `zless` search and page through gzip files directly, which is handy for rotated logs.

## 8.7 Identifying an archive

Extensions are only names; nothing enforces them. `file` reads the actual bytes:

```bash
file archive.tar.gz     # gzip compressed data ...
file archive.tar.bz2    # bzip2 compressed data ...
```

**Try it.**

```bash
cd /root/practice
mkdir -p arch && cd arch

tar -czvf sysconfig.tar.gz /etc/sysconfig
tar -tzf sysconfig.tar.gz | head -5
file sysconfig.tar.gz

tar -cjf sysconfig.tar.bz2 /etc/sysconfig
tar -cJf sysconfig.tar.xz /etc/sysconfig
ls -lh sysconfig.tar.*                        # compare the sizes

mkdir restore
tar -xzf sysconfig.tar.gz -C restore
ls restore                                    # etc
diff -r /etc/sysconfig restore/etc/sysconfig && echo "identical"

tar -czf nolog.tar.gz --exclude='*.log' /var/log/anaconda
tar -tzf nolog.tar.gz | grep -c '\.log$'      # 0

cp /etc/services .
gzip -k services
bzip2 -k services
xz -k services
ls -lh services*
zcat services.gz | head -3
```

**Proving that SELinux labels were saved.** Extract a labelled archive twice, once with `--selinux` and once without, and compare:

```bash
cd /root/practice/arch
tar --selinux --xattrs -czf ssh.tar.gz /etc/ssh
mkdir with without
tar --selinux --xattrs -xzf ssh.tar.gz -C with
tar -xzf ssh.tar.gz -C without
ls -Z with/etc/ssh/sshd_config without/etc/ssh/sshd_config
```

The `with` copy keeps the original system label (containing `etc_t`). The `without` copy gets a label based on its new location under `/root`. You do not need to understand the labels yet; the point is that one extraction carried them over and the other did not.

**Verify.** `file` for the compression type, `tar -tf` for the contents, and a test extraction into a scratch directory for anything important.

**What goes wrong.** `-f` not last in the bundle; forgetting the compression flag when creating; extracting into the wrong place (forgetting `-C`); leaving out `--selinux` and `--xattrs` when a task says to preserve contexts; `gzip` deleting an original you still needed.

**How RHCSA tests Part 8.** *"Create a bzip2-compressed tar archive of /etc named /root/etc.tar.bz2"*, *"Extract archive X into directory Y"*. Check the exact name and location, the compression type with `file`, and the contents with `tar -tf`.

### Part 8 self-check

1. What is the difference between archiving and compressing?
2. Why does `tar -cfz x.tar.gz /etc` go wrong?
3. You extract `etc.tar.gz` while in `/tmp`. Where do the files go?
4. What happens to `report.txt` when you run `gzip report.txt`?
5. What must you add to preserve SELinux labels, and at which steps?

---

# Part 9: Logging in and switching users

> **Objective:** Log in and switch users in multiuser targets.

## 9.1 Sessions, login shells, and startup files

**What a login is.** Logging in means proving who you are (with a password or an SSH key) and receiving a **session**: a shell running as your user.

**Login shells and non-login shells.** Bash reads different startup files depending on how it was started. This decides where settings such as variables, aliases, and umask must go in order to take effect.

| Kind | Started by | Reads |
|---|---|---|
| login shell | console login, SSH login, `su -`, `sudo -i` | `/etc/profile` (which runs the `/etc/profile.d/*.sh` files), then `~/.bash_profile` (which on RHEL also runs `~/.bashrc`) |
| non-login interactive shell | typing `bash`, `su` without `-`, a new terminal window on a desktop | `~/.bashrc` (which on RHEL also runs `/etc/bashrc`) |

**Practical rule:** personal aliases, variables, and umask go in `~/.bashrc`; system-wide settings go in a `.sh` file inside `/etc/profile.d/`. Changes affect **new** shells. To load them into your current shell, run `source ~/.bashrc`.

## 9.2 Consoles and targets

**Terminals.** Linux offers several **virtual consoles** (`tty1` to `tty6`) on the machine's own screen, each an independent login. Remote sessions and terminal windows use **pseudo-terminals** (`pts/0`, `pts/1`, and so on).

```bash
tty          # which terminal am I on? e.g. /dev/tty1 or /dev/pts/0
who          # who is logged in, and on which terminal
```

On physical hardware, `Ctrl+Alt+F2` switches to `tty2`. In a VMware console the host often intercepts that key combination, so switch from inside the VM instead:

```bash
chvt 2       # switch to tty2 and log in there; chvt 1 brings you back
```

Run `chvt` as root, at the VM's own console. It switches the machine's physical display, so it does nothing useful from an SSH session.

**Targets.** A systemd **target** is a named system state: a set of services that should be running. Two matter now:

| Target | State |
|---|---|
| `multi-user.target` | full networking and services, text logins, many users at once. **The normal server state, and what your lab machines use.** |
| `graphical.target` | everything in `multi-user.target` plus a graphical desktop |

```bash
systemctl get-default
```

The objective's phrase "in multiuser targets" simply means: log in and switch users on a normal, running, text-mode server. Targets are covered in depth in the "Operate running systems" section.

## 9.3 `su`: become another user

**What it is.** `su` (**s**ubstitute **u**ser) starts a **new shell** running as another user. With no username, it means root.

**Password rules.** You type the **target** user's password (root's password for `su -`). If you are already root, no password is needed.

**`su` versus `su -`.** The dash (also written `-l` or `--login`) makes the new shell a **login shell**:

| | `su USER` | `su - USER` |
|---|---|---|
| environment variables | **kept** from the original user (only a few, such as `HOME` and `SHELL`, change) | **reset** to a clean login environment |
| current directory | **unchanged** | the target user's **home** |
| login startup files | not read | read, just like a real login |

Keeping someone else's environment causes confusing behavior: wrong settings, the wrong directory, files created in the wrong place. **Use `su -`.**

**Try it** (as root):

```bash
useradd carol
echo 'redhat' | passwd --stdin carol
cd /tmp
export COLOR=blue
su carol -c 'pwd; echo "COLOR=$COLOR"'      # /tmp  and  COLOR=blue   (inherited)
su - carol -c 'pwd; echo "COLOR=$COLOR"'    # /home/carol  and  COLOR=  (clean)
cd /root
```

`-c 'command'` runs just that one command as the other user and returns.

**Shells nest.** `su` does not *replace* your shell; it starts a new one *inside* it. `exit` (or `Ctrl-D`) leaves the inner shell and returns you to the previous user. Watch the prompt so you always know who you are; working as the wrong user is a common and silent mistake.

```bash
su - carol
whoami       # carol
exit
whoami       # root
```

## 9.4 `sudo`: run one command with elevated rights

**What it is.** `sudo` runs **one command** as another user, root by default, **if a policy allows it**. You prove your identity with **your own** password, not root's.

**Why it exists, and why it is preferred over `su`.**

- Nobody needs to know the root password.
- Rights can be granted per user, per group, even per command.
- Every `sudo` command is logged, so you know who did what.

**Where the policy lives.** In `/etc/sudoers` and files inside `/etc/sudoers.d/`. On RHEL, `/etc/sudoers` contains the line `%wheel ALL=(ALL) ALL`, meaning members of the `wheel` group may run any command as any user. So "give a user full sudo rights" usually means "add them to `wheel`". (Editing sudoers safely with `visudo` is covered in the users and security sections.)

**Anatomy.**

```bash
sudo COMMAND           # run COMMAND as root
sudo -u USER COMMAND   # run it as a specific user
sudo -i                # a root login shell (like su -, but with your own password)
sudo -l                # list what you are allowed to run
```

After you authenticate, `sudo` remembers you for a few minutes (5 by default), so the next `sudo` does not ask again.

**Group changes need a new login.** A process's groups are fixed when its session starts. After `usermod -aG wheel carol`, any session carol already has open does **not** gain `wheel`. She must log out and back in (or start a new login shell, as `su - carol` does).

**Try it.**

```bash
usermod -aG wheel carol
su - carol
id                # wheel appears (this is a fresh login)
sudo whoami       # asks for carol's own password (redhat), then prints root
sudo -l
exit
```

## 9.5 Who am I, and who else is here?

| Command | Shows |
|---|---|
| `whoami` | your effective username |
| `id`, `id USER` | UID, GID, all groups (and your SELinux context) |
| `groups USER` | group names only |
| `who` | who is logged in, and on which terminal |
| `w` | the same, plus what each user is running |
| `last` | recent logins and reboots |
| `lastb` | recent **failed** logins (root only) |

**What goes wrong in Part 9.**

- Using `su` without `-` and inheriting the wrong environment and directory.
- Forgetting to `exit` and carrying on as the wrong user.
- Expecting a new group membership to work in a session that was already open.
- Typing root's password to `sudo`. It wants **yours**.

**How RHCSA tests Part 9.** Directly, rarely. Indirectly, constantly. Tasks say "as user X, do Y", "user X must be able to run Z with sudo", or require you to confirm access as a particular user. `su - USER -c 'COMMAND'` is the fastest way to test from another user's point of view.

**Clean up:**

```bash
userdel -r carol
```

### Part 9 self-check

1. Give two differences between `su carol` and `su - carol`.
2. Whose password does `sudo` ask for?
3. You added alice to `wheel` while she was logged in. Why can't she use `sudo` yet?
4. How do you find out which terminal you are using?

---

# Part 10: Remote access with SSH

> **Objectives:** Access remote systems using SSH. (Also the related objective from "Operate running systems": securely transfer files between systems.)

## 10.1 What SSH is and why it exists

**What it is.** **SSH** (**S**ecure **SH**ell) gives you a shell on another machine over the network. It can also run single commands remotely and copy files.

**Why it exists.** Older tools such as `telnet` and `rsh` sent everything, **passwords included**, across the network as plain text that anyone watching the traffic could read. SSH **encrypts** the whole connection and lets each side verify the other's identity.

## 10.2 Client and server

| Side | Program | Package |
|---|---|---|
| client (where you type) | `ssh`, `scp`, `sftp` | `openssh-clients` |
| server (the machine you log in to) | `sshd`, the SSH **d**aemon (a background service) | `openssh-server` |

`sshd` listens on **TCP port 22** by default. For a connection to succeed, `sshd` must be running on the server and the server's firewall must allow SSH (RHEL allows it by default).

```bash
systemctl status sshd       # is the server running?
ss -tlnp | grep ':22'       # is anything listening on port 22?
```

## 10.3 Host keys: how your client trusts the server

**The problem.** How do you know you are talking to the real `node2` and not an impostor sitting in between?

**How it works.** Every SSH server has a **host key**, stored in the files `/etc/ssh/ssh_host_*_key`. The first time you connect, your client has never seen it and asks:

```
The authenticity of host 'node2 (172.25.250.11)' can't be established.
ED25519 key fingerprint is SHA256:....
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Answering `yes` saves the key in your `~/.ssh/known_hosts`. On every later connection, the client checks that the server presents the **same** key. This approach is called *trust on first use*.

If the key ever changes, the client refuses to connect and prints `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`. That could mean an attack, but in a lab it almost always means **you rebuilt the machine**, which generated a new host key. When you know that is the cause, delete the old entry:

```bash
ssh-keygen -R node2
```

## 10.4 Two ways to prove who you are

**Password authentication.** You type the remote account's password. It is simple, but passwords can be guessed, and automated jobs cannot type them.

**Public key authentication.** You create a **key pair**: two mathematically linked keys.

- The **private key** stays on your client and must be kept secret.
- The **public key** can be shared freely. You place a copy in `~/.ssh/authorized_keys` on the server, inside the home directory of the account you want to log in to.

When you connect, the server challenges the client to prove it holds the private key matching one of the public keys in `authorized_keys`. The client proves it mathematically **without ever sending the private key**.

An analogy: the public key is a padlock you are happy to hand out, and only your private key opens it. You fit your padlock to the server's door; from then on, only you can open that door.

A **passphrase** optionally encrypts the private key file on disk, so a stolen copy is useless. For lab work, and for RHCSA tasks that say "without a password", leave it empty.

## 10.5 Setting up key-based login, step by step

**Step 0: work out which two accounts are involved.** This is where most people lose the points, before typing anything.

Key-based login always connects **one local account** to **one remote account**:

- The key pair belongs to the **local user who runs `ssh`**. It lives in *that user's* `~/.ssh/`.
- The public key must be placed in the **remote user's** `~/.ssh/authorized_keys`.

So read the task for both names. *"User student on node1 must be able to log in to node2 as student without a password"* must be done **as student on node1**:

```bash
su - student               # become the local user named in the task
ssh-keygen                 # creates /home/student/.ssh/id_ed25519
ssh-copy-id student@node2  # installs it for the remote user named in the task
exit
```

If you run `ssh-keygen` as root instead, you create **root's** keys in `/root/.ssh/`. They are useless to `student`, and a grader that logs in as `student` will be asked for a password. Everything in steps 1 to 3 below happens as the correct local user.

**Step 1: generate a key pair on the client.**

```bash
ssh-keygen
```

It asks where to save the key (press Enter for the default) and for a passphrase (press Enter twice for none). It creates two files in `~/.ssh/`:

| File | What it is |
|---|---|
| `id_ed25519` | the **private** key. Current OpenSSH, including RHEL 10's, creates the Ed25519 type by default. Older versions defaulted to RSA and named the file `id_rsa`; either works the same way. |
| `id_ed25519.pub` | the **public** key: a single line of text |

**Step 2: install the public key on the server.**

```bash
ssh-copy-id root@node2
```

This logs in once using the password, appends your public key to `~/.ssh/authorized_keys` on `node2` (creating the directory and file if needed), and sets their permissions correctly.

**Step 3: test it properly.**

```bash
ssh -o BatchMode=yes root@node2 hostname
```

`BatchMode=yes` tells ssh never to prompt for anything. If key authentication works, you get the remote hostname. If it does not, you get an error **instead of** a password prompt. That makes it a genuine test: a plain `ssh` that quietly falls back to asking for a password can fool you into thinking keys work.

When the task names a user other than root, **test as that user**, from root's shell, exactly the way a grader would:

```bash
su - student -c 'ssh -o BatchMode=yes student@node2 hostname'
```

**Doing it by hand**, when `ssh-copy-id` is unavailable:

```bash
cat ~/.ssh/id_ed25519.pub | ssh root@node2 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

Read it using Parts 1 and 2: `cat` sends your public key into the pipe; on `node2`, the quoted commands create the directory, append stdin to `authorized_keys`, and fix the permissions. The single quotes make sure `~` is expanded on `node2`, not locally.

## 10.6 Why sshd is fussy about permissions

If anyone other than the account's owner could write to `~/.ssh/authorized_keys`, they could add **their own** key and log in as that user. So `sshd` checks permissions (its `StrictModes` setting) and **silently ignores the keys** if the files are too open. You just get a password prompt, with no explanation on the client side.

| Path | Required |
|---|---|
| the home directory | not writable by group or others |
| `~/.ssh` | `700` (`drwx------`) |
| `~/.ssh/authorized_keys` | `600` (`-rw-------`) |
| `~/.ssh/id_ed25519` (the private key, on the client) | `600`; ssh refuses to use a private key that others can read |
| `~/.ssh/id_ed25519.pub` | `644` is fine |

SELinux labels matter too: files under `~/.ssh` should carry the `ssh_home_t` type. If you created them in an unusual way (for example by moving them in from elsewhere), fix the labels with `restorecon -Rv ~/.ssh` (explained in the security section).

**Where to look when it fails.** On the **server**, `journalctl -u sshd` (or `/var/log/secure`) usually states the exact reason. On the **client**, `ssh -v` prints each step of the negotiation.

## 10.7 Using ssh

```bash
ssh node2                      # connect using your current username
ssh student@node2              # a specific user
ssh -p 2222 user@host          # a non-standard port (lowercase p)
ssh root@node2 'df -h /'       # run one command remotely, then return
exit                           # or Ctrl-D: end the remote session
```

**Quoting decides where things expand.** Your local shell processes the line first (1.2):

```bash
ssh root@node2 "echo $HOSTNAME"    # prints node1: YOUR shell expanded it before sending
ssh root@node2 'echo $HOSTNAME'    # prints node2: sent literally, expanded remotely
```

## 10.8 Copying files securely

### `scp`

```
scp [options] SOURCE DESTINATION
```

A remote location is written `user@host:path`. **The colon is what makes it remote.** Without it, `scp file node2` simply copies `file` to a local file named `node2`.

```bash
scp /etc/hosts root@node2:/tmp/                  # local to remote
scp root@node2:/etc/hostname /tmp/n2-hostname    # remote to local
scp -r /etc/ssh root@node2:/tmp/ssh-copy         # a directory needs -r
scp -p file root@node2:/tmp/                     # preserve times and modes
scp -P 2222 file user@host:/tmp/                 # port: CAPITAL P (ssh uses lowercase)
```

(On RHEL 9 and later, `scp` uses the SFTP protocol underneath. The command line is unchanged.)

### `rsync`

`rsync` transfers only what has changed, so repeated copies are fast, and it preserves metadata well.

```bash
rsync -av /srv/data/ root@node2:/srv/data/
```

| Option | Meaning |
|---|---|
| `-a` | archive: recursive, preserving permissions, times, owner, group, and symlinks |
| `-v` | verbose |
| `-z` | compress data in transit |
| `--delete` | remove files at the destination that no longer exist at the source |
| `-X`, `-A` | also preserve extended attributes (including SELinux labels), and ACLs |

**A trailing slash on the source changes the meaning.** `rsync -a src/ dest/` copies the **contents** of `src` into `dest`. `rsync -a src dest/` copies the **directory itself**, creating `dest/src`. `rsync` must be installed on **both** machines.

### `sftp`

An interactive transfer session: `sftp root@node2`, then `ls`, `cd`, `get FILE`, `put FILE`, `lls` and `lcd` (the local versions of `ls` and `cd`), and `bye` to leave.

## 10.9 A first look at server configuration

The server reads `/etc/ssh/sshd_config`. Near its top, that file includes every `*.conf` file in `/etc/ssh/sshd_config.d/`. For most settings, **the first value sshd reads wins**, so a setting in a drop-in file overrides the same setting further down the main file. Put your own changes in a drop-in file.

```bash
sshd -t                     # check the configuration for errors (no output means OK)
systemctl restart sshd      # apply changes
sshd -T | grep -i permitrootlogin    # the EFFECTIVE value, after every file is combined
```

`sshd -t` (lowercase) only checks syntax. `sshd -T` (uppercase) prints the **final** value of every setting after sshd has read the main file and all the drop-ins. Because "first value wins" makes it hard to predict which file's setting applies, `sshd -T` is the fastest way to answer "what is sshd actually going to do?" Both need root.

**Do not lock yourself out.** When you change sshd over an SSH connection, keep that session open, and test the new settings from a **second** session. If the change broke logins, the first session is still there to fix it.

Common settings include `PermitRootLogin` and `PasswordAuthentication`. The security section covers them in depth.

**What goes wrong in Part 10.**

| Symptom | Likely cause |
|---|---|
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | the server was rebuilt; `ssh-keygen -R host` |
| still asks for a password after setting up keys | permissions on `~/.ssh` or `authorized_keys`; wrong user; key installed for another account |
| `Connection refused` | the host was reached but nothing listens on that port: `sshd` stopped, or wrong port |
| `No route to host` | often the firewall rejecting the connection, or a wrong IP address |
| `Connection timed out` | packets are silently dropped: firewall, wrong network, or the host is down |
| `Could not resolve hostname` | name resolution; check `/etc/hosts` |
| a local file named after the host appeared | the `:` was missing from an `scp` destination |

**How RHCSA tests Part 10.** *"Configure key-based authentication so user X can log in to host Y without a password"*, *"Copy file F to host Y"*, and many tasks where you must first log in to a second machine. Verify key authentication with `ssh -o BatchMode=yes ...`, and verify copies by checking the file on the destination.

### Part 10 self-check

1. What is stored in `~/.ssh/known_hosts`, and why?
2. Which key goes to the server, and into which file?
3. Why is `ssh -o BatchMode=yes` a better test than plain `ssh`?
4. What is the difference between `scp file node2` and `scp file node2:`?
5. Why would `sshd` ignore your key if `~/.ssh` had mode `777`?
6. A task says student on node1 must log in to node2 as student without a password. You ran `ssh-keygen` and `ssh-copy-id` as root. Why does the grader still get a password prompt?

---

# Part 11: Finding documentation

> **Objective:** Locate, read, and use system documentation including man, info, and files in /usr/share/doc.

## 11.1 Why this may be the most important skill in Section 1

The exam gives you **no internet** and **no notes**. You will forget an option letter or the exact format of a config file. The system's own documentation is always there, and the candidate who finds an answer in 30 seconds has time that others do not. Treat this part as a core exam skill.

Documentation arrives with software packages: when a package is installed, its man pages, info pages, and files under `/usr/share/doc` come with it.

## 11.2 `man`: the manual pages

**What it is.** A **man page** documents one command, configuration file, or programming function. `man NAME` opens it.

**Sections.** The manual is divided into numbered sections, and the same name can exist in more than one:

| Section | Contains | Examples |
|---|---|---|
| 1 | user commands | `man ls`, `man 1 passwd` |
| 5 | **file formats and configuration files** | `man 5 passwd`, `man 5 fstab`, `man 5 sshd_config` |
| 7 | overviews and conventions | `man 7 regex` |
| 8 | **system administration commands** | `man 8 useradd`, `man 8 mount` |
| 2, 3, 4 | system calls, library functions, device files | mainly for programmers |

`man passwd` opens the **first** section that has a match: the `passwd` *command* in section 1. To read about the `/etc/passwd` *file format*, request section 5: `man 5 passwd`. In documentation, the notation `passwd(5)` means "`passwd`, section 5".

**Sections 5 and 8 hold most exam answers.**

**When a page is missing.** On a minimal install you may see `No manual entry for passwd in section 5`. The page exists; it is simply in a package that is not installed. Many section 5 and 7 pages come from the `man-pages` package. Rather than guess, ask the package database which package owns the page (11.6), install it, and try again:

```bash
dnf provides '*/man5/passwd.5*'     # which package contains the section 5 passwd page?
dnf install man-pages               # typically the answer
man 5 passwd
```

If the `man` command itself is missing, install `man-db`.

**The layout of a man page.**

| Heading | Tells you |
|---|---|
| NAME | the name and a one-line description |
| SYNOPSIS | the command's syntax |
| DESCRIPTION | what it does, in detail |
| OPTIONS | each option explained |
| EXAMPLES | worked examples; often near the **end**, and often the quickest route to an answer |
| FILES | the configuration files it uses |
| SEE ALSO | related pages worth reading next |

**Reading the SYNOPSIS.** It uses a small notation:

| Notation | Means |
|---|---|
| **bold** text | type it exactly as shown |
| *underlined* or *italic* text | replace it with your own value |
| `[ ]` | optional |
| `...` | may be repeated |
| `a \| b` | choose one |

For example, `cp [OPTION]... SOURCE DEST` reads as: "`cp`, then zero or more options, then one source, then one destination".

**Moving around.** Man pages open in a pager program called `less`:

| Key | Does |
|---|---|
| `Space`, `b` | page down, page up |
| `/word` | search forward; `n` next match, `N` previous |
| `g`, `G` | top, bottom |
| `q` | quit |
| `h` | help on every key |

**Jumping to a specific option.** Options are usually indented, so searching with leading spaces skips mentions inside running text: type `/ *-M` to find the lines that describe `-M`.

### Finding the right page when you do not know its name

```bash
man -k password                 # search page names and one-line descriptions (same as: apropos password)
man -k password | grep '(8)'    # only administration commands
man -f passwd                   # which sections have a page called passwd (same as: whatis passwd)
man -K 'some phrase'            # search the FULL TEXT of every page: slow but thorough
```

`man -k` searches a prebuilt index. On a fresh system it may answer `nothing appropriate`. Build the index, then try again:

```bash
mandb
```

## 11.3 `info`

**What it is.** A hypertext documentation system used by GNU projects. For some tools (the core utilities, `tar`, `grep`, `bash`) the info manual is fuller and more tutorial-like than the man page.

```bash
info coreutils
info tar
info coreutils 'ls invocation'
```

| Key | Does |
|---|---|
| `n`, `p` | next node (page), previous node |
| `u` | up one level |
| `Enter` | follow the link under the cursor |
| `Tab` | jump to the next link |
| `l` | go back |
| `s` | search |
| `q` | quit |

If a name has no info page, `info` displays its man page instead.

## 11.4 `/usr/share/doc`

Each package may install a directory under `/usr/share/doc/` with READMEs, change logs, licences, and, most usefully, **example and sample configuration files**. Copying a working example is often faster and safer than writing configuration syntax from memory.

```bash
ls /usr/share/doc | head -30
ls /usr/share/doc/openssh*
rpm -qd openssh-server                   # every documentation file a package installed
ls -d /usr/share/doc/*/examples 2> /dev/null
```

## 11.5 Quick help

- **`COMMAND --help`** prints a short option summary for most GNU tools. It is the fastest route when you only need an option letter.
- **`help NAME`** documents **shell builtins** such as `cd`, `export`, `umask`, `test`, `for`, and `if`. Builtins are part of bash, so many have no man page of their own. `type NAME` tells you whether something is a builtin (1.4).

## 11.6 When the command itself is missing

On a minimal system, many tools are not installed. The package database can tell you which package provides a file, even offline, using your DVD repository:

```bash
dnf provides '*/semanage'        # which package would install a file named semanage?
dnf search keyword               # packages whose name or summary mentions the word
rpm -qf /etc/ssh/sshd_config     # which INSTALLED package owns this file?
rpm -ql openssh-server           # every file an installed package contains
rpm -qc openssh-server           # just its configuration files
```

`dnf provides` is one of the most valuable commands in the exam: a tool is missing, you ask which package supplies it, you install it, you carry on. (Section 2 covers package management fully.)

## 11.7 A worked search: from a vague task to a command

**Task:** *"Make the password of user carol expire every 90 days."* Suppose you have no idea which command does this.

1. **Pick keywords from the task and search:** `man -k password | grep -iE 'age|expir'`
2. **Read the one-line descriptions.** One says roughly `chage (1) - change user password expiry information`. That fits.
3. **Open it:** `man chage`.
4. **Read the SYNOPSIS:** `chage [options] LOGIN`, so the username goes last.
5. **Search for the concept:** `/maximum`. You find `-M, --maxdays MAX_DAYS`: the maximum number of days a password stays valid.
6. **Build the command:** `chage -M 90 carol`.
7. **Find the verification on the same page:** `-l` lists the current settings, so `chage -l carol`.

Nothing in that process required knowing `chage` beforehand. **That is the skill.** Practise it until it is quick.

### Part 11 self-check

1. Which man section documents configuration file formats? Which documents administration commands?
2. `man -k` says "nothing appropriate". What do you run?
3. Where would you look for a sample configuration file shipped with a package?
4. How do you get help for `cd`, which has no man page?
5. `semanage: command not found`. Which single command tells you what to install?

---

# Part 12: Reasoning through an unfamiliar task

This is the goal of the whole section. RHCSA tasks describe **outcomes** ("user X must be able to...", "the file must contain...") rather than commands. Your job is to translate an outcome into commands, and then to prove the outcome is true.

## 12.1 A method

1. **Read the whole task twice.** Mark the **objects** (files, directories, users, groups, hosts), the **actions** (create, copy, find, restrict, archive), and the **constraints** (owned by, only, preserve, sorted, one per line, must persist).
2. **Classify it.** Which part of these notes does it belong to? Text, files, links, permissions, archives, users, remote access?
3. **Translate the wording into tools.** Use the table in 12.2.
4. **If unsure of the syntax, look it up** (Part 11). If the action is destructive, test it on a scratch copy first.
5. **Do it,** using the absolute paths exactly as given.
6. **Verify from the grader's point of view:** the exact path and name, the exact content, the owner, group, and mode, and, where access is involved, access tested **as the user named in the task**.
7. **Ask whether it survives a reboot.** File-level changes (content, links, permissions, archives) do. Many later tasks (services, mounts, networking, SELinux) need an extra step to persist.

## 12.2 From task wording to tools

| The task says... | Think of... |
|---|---|
| "find / locate all files that..." | `find` with tests (4.6) |
| "lines containing / matching" | `grep` (3.2) |
| "only the usernames", "only field X" | `cut` or `awk` (3.6) |
| "UID greater than", any numeric comparison | `awk` (3.6) |
| "sorted", "unique", "how many" | `sort`, `uniq`, `wc -l` (3.6) |
| "write only the number" | `wc -l < file` (2.5) |
| "save the output **and the errors**" | `> file 2>&1` (2.4) |
| "append" | `>>` or `tee -a` (2.2, 2.7) |
| "copy **preserving** ownership, permissions, timestamps" | `cp -p` or `cp -a` (4.3) |
| "another name for the same file", "survives deletion of the original" | hard link, `ln` (5.2) |
| "shortcut", "points to", "across filesystems", "to a directory" | symbolic link, `ln -s` (5.3) |
| "only the owner can read and write" | `chmod 600` (6.5) |
| "group members can create files in..." | group `w` and `x` on the directory (6.4) |
| "new files automatically belong to group X" | SGID on the directory, `chmod g+s` (6.8) |
| "users cannot delete each other's files" | sticky bit, `chmod +t` (6.8) |
| "gzip / bzip2 / xz archive of..." | `tar -czf`, `-cjf`, `-cJf` (8.2) |
| "preserve SELinux contexts" in an archive | `tar --selinux --xattrs` (8.5) |
| "extract into directory X" | `tar -x... -C X` (8.3) |
| "log in to host X without a password" | `ssh-keygen` and `ssh-copy-id` (10.5) |
| "securely copy to host X" | `scp` or `rsync` (10.8) |
| "as user X, ..." | `su - X`, or `su - X -c '...'` (9.3) |
| "I don't recognize this at all" | `man -k` keywords, then `man` (11.2, 11.7) |

## 12.3 Worked example A

> *Find all regular files under /usr/share that are larger than 1 MiB and write their full paths, one per line, to /root/bigfiles.txt.*

**Objects:** files under `/usr/share`; the output file `/root/bigfiles.txt`.
**Actions:** find; write a list.
**Constraints:** regular files only; larger than 1 MiB; full paths; one per line.

**Reasoning.** "Find files by a property" means `find`. "Regular files" means `-type f`. "Larger than 1 MiB" means `-size +1M`. `find` prints **full** paths, one per line, when its starting point is an absolute path. The list goes into the file with `>`. Any permission errors would stay on the screen rather than polluting the file, because they travel on stderr (2.3).

```bash
find /usr/share -type f -size +1M > /root/bigfiles.txt
```

**Verify.**

```bash
wc -l /root/bigfiles.txt
head -3 /root/bigfiles.txt
ls -lh "$(head -1 /root/bigfiles.txt)"    # spot-check: is the first entry really over 1M?
```

## 12.4 Worked example B

> *Create the directory /srv/devteam, owned by group devteam. Members of devteam must be able to create files in it, every new file must automatically belong to devteam, and users must not be able to delete files created by other users. Users outside the group must have no access at all.*

**Objects:** the directory `/srv/devteam`; the group `devteam`.

**Constraints, translated one at a time:**

| Requirement | Mechanism | Bits |
|---|---|---|
| owned by group devteam | `chgrp devteam` | |
| members can create files | group `w` and `x` on the directory | group `rwx` = 7 |
| the owner (root) has full control | | user `rwx` = 7 |
| outsiders have no access | | other `---` = 0 |
| new files belong to devteam | SGID | 2 |
| cannot delete each other's files | sticky | 1 |

The special digit is 2 + 1 = **3**, so the full mode is **3770**.

```bash
groupadd devteam
mkdir -p /srv/devteam
chgrp devteam /srv/devteam
chmod 3770 /srv/devteam
```

**Verify.**

```bash
stat -c '%U:%G %a %A' /srv/devteam      # root:devteam 3770 drwxrws--T
```

The uppercase `T` is expected here: the sticky bit is set and others have no `x` (6.8). Then test **behavior**, not just bits: create two test users in `devteam`, have one create a file, confirm its group is `devteam`, and confirm the other user cannot delete it. When you are done, clean up with `rm -rf /srv/devteam` and `groupdel devteam` (after removing any test users).

## 12.5 Worked example C

> *Save the usernames of all accounts with a UID below 1000, sorted in reverse alphabetical order, to /root/system-users.txt.*

**Reasoning.** Usernames and UIDs are fields 1 and 3 of `/etc/passwd`. "UID below 1000" is a **numeric** comparison, so `awk` rather than a regex. "Usernames" means print only field 1. "Reverse alphabetical" means `sort -r`.

```bash
awk -F: '$3 < 1000 { print $1 }' /etc/passwd | sort -r > /root/system-users.txt
```

**Verify.**

```bash
head /root/system-users.txt
wc -l /root/system-users.txt
awk -F: '$3 < 1000' /etc/passwd | wc -l     # the same count, by another route
```

**Read the data, not just the task.** `root` (UID 0) is included, because 0 is below 1000. The `nobody` account has UID 65534, so it is **excluded** here, but a naive "regular users" filter of `$3 >= 1000` would **include** it. Graders use exact definitions, so look at the real data before trusting a filter.

## 12.6 Habits that save points

- Use the absolute paths from the task, exactly, and let Tab completion confirm them.
- Run the "look" version of a command before the "change" version: `find ... -print` before `-delete`, `tar -t` before `tar -x`, `echo rm ...` before `rm ...`.
- Verify every task immediately, while it is fresh, with a command that reads the result back.
- Test access as the user the task names, not as root. Root bypasses permission checks, so a test as root proves nothing about anyone else.
- Leave nothing half-finished: an incomplete task usually scores zero.

---

# Appendix A: Compact reference

Use these tables for lookup **after** you understand the parts they summarize.

### Shell syntax (Part 1)

| Syntax | Meaning |
|---|---|
| `NAME=value`, `$NAME`, `"$NAME"` | set a variable, read it, read it safely |
| `export NAME` | pass a variable to child processes |
| `*`, `?`, `[abc]`, `[!abc]` | globs: any string, one character, one of, none of |
| `{a,b}`, `{1..5}` | brace expansion: generate text |
| `$(command)` | command substitution |
| `'...'`, `"..."`, `\x` | no expansion; variables only; escape one character |
| `$?` | exit status of the last command (0 = success) |
| `a ; b`, `a && b`, `a \|\| b` | always, only on success, only on failure |
| `type NAME`, `which NAME` | what a command name resolves to |

### Redirection (Part 2)

| Syntax | Effect |
|---|---|
| `> f`, `>> f` | stdout to a file: overwrite, append |
| `2> f`, `2>> f` | stderr to a file: overwrite, append |
| `> f 2>&1`, `&> f` | both streams to one file |
| `2> /dev/null` | discard errors |
| `< f` | a file as stdin |
| `<<'EOF'` ... `EOF` | here document (quoted: literal text) |
| `<<< "text"` | here string |
| `a \| b`, `a \|& b` | pipe stdout; pipe stdout and stderr |
| `\| tee f`, `\| tee -a f` | copy the stream to a file and pass it on: overwrite, append |
| `\| sudo tee -a f > /dev/null` | privileged append |

### grep and regular expressions (Part 3)

| grep option | Meaning |
|---|---|
| `-i -v -c -n -l -r -w -x -o` | ignore case, invert, count lines, line numbers, file names only, recursive, whole word, whole line, only the match |
| `-A n -B n -C n` | context lines after, before, around |
| `-E`, `-F`, `-q` | extended regex, fixed string, quiet (exit status only) |

| Regex | Meaning |
|---|---|
| `^`, `$` | start, end of line |
| `.` | any one character (`\.` a literal dot) |
| `[abc]`, `[^abc]`, `[[:digit:]]` | one of, none of, a POSIX class |
| `*`, `+`, `?` | 0 or more, 1 or more, 0 or 1 (`+ ?` need `-E`) |
| `{n}`, `{n,}`, `{n,m}` | exact count, at least, range (`-E`) |
| `(a\|b)` | group and alternation (`-E`) |
| `\<word\>` | word boundaries |

### Text tools (Part 3)

| Command | Use |
|---|---|
| `cut -d: -f1,3` | fields 1 and 3, colon-delimited |
| `awk -F: '$3 >= 1000 {print $1}'` | condition plus action on fields |
| `sort -n -r -u`, `sort -t: -k3 -n` | numeric, reverse, unique; by field |
| `uniq -c` | count adjacent duplicates (sort first) |
| `wc -l -w -c` | lines, words, bytes |
| `head -n N`, `tail -n N`, `tail -f` | first N, last N, follow |
| `sed 's/a/b/g'`, `sed -i.bak ...` | substitute; edit in place with a backup |
| `tr 'a-z' 'A-Z'`, `tr -d x` | translate, delete characters (stdin only) |

### Files and find (Part 4)

| Command | Use |
|---|---|
| `mkdir -p`, `touch` | create a directory tree; create a file or update its time |
| `cp -r`, `cp -p`, `cp -a` | recursive; preserve mode, owner, times; archive (everything) |
| `cp -a src/. dest/` | copy all contents, **hidden files included** |
| `\cp` | skip root's `cp -i` alias (`cp -f` does **not**) |
| `mv`, `rm -r`, `rmdir` | move or rename; delete recursively; delete an empty directory |
| `stat -c '%U:%G %a %n'` | owner, group, octal mode, name |

| find | Meaning |
|---|---|
| `-name '*.x'`, `-iname` | name glob (quoted), ignoring case |
| `-type f\|d\|l` | file, directory, symlink |
| `-user U`, `-group G` | ownership |
| `-size +5M`, `-mtime -7`, `-mmin -60` | size, days modified, minutes modified |
| rounding | size rounds **up** (`-size -1M` = empty files only); age rounds **down** (`-mtime +7` = 8+ days) |
| `-perm 644`, `-perm -4000`, `-perm /022` | exact, all bits, any bit |
| `-maxdepth N` | limit depth |
| `-exec cmd {} \;`, `-exec cmd {} +` | run per match, run in batches |
| `-delete` | delete matches (test with `-print` first) |

### Links (Part 5)

| Command | Creates |
|---|---|
| `ln EXISTING NEW` | hard link: same inode, same filesystem, not for directories |
| `ln -s TARGET LINK` | symlink: stores a path; relative targets resolve from the link's directory |
| `ls -li`, `readlink -f` | compare inodes; resolve a symlink |

### Permissions (Part 6)

| Item | Values |
|---|---|
| r, w, x | 4, 2, 1 |
| SUID, SGID, sticky | 4000, 2000, 1000 (`u+s`, `g+s`, `o+t`) |
| directory `r`, `w`, `x` | list names; create, delete, rename; enter and access |
| decision order | root, then owner only, then group only, then other |
| default modes | files 666, directories 777, minus the umask bits |
| `chmod -R u=rwX,g=rX,o=` | safe recursive change (`X` = x for directories only) |
| `namei -l /path` | permissions of every component of a path |

### vim (Part 7)

| Keys | Action |
|---|---|
| `i`, `a`, `o`, `A` | enter Insert mode (before, after, new line below, end of line) |
| `Esc` | back to Normal mode |
| `:w`, `:q`, `:wq`, `:q!` | save, quit, save and quit, quit discarding |
| `dd`, `yy`, `p`, `u` | cut line, copy line, paste, undo |
| `/text`, `n` | search, next match |
| `:%s/old/new/g` | replace everywhere |
| `gg`, `G`, `:N` | first line, last line, line N |

### Archives (Part 8)

| Command | Use |
|---|---|
| `tar -czf a.tar.gz DIR` | create gzip (`-j` bzip2, `-J` xz) |
| `tar -tvf a.tar.gz` | list with details |
| `tar -xf a.tar.gz -C DIR` | extract into DIR (compression detected) |
| `--selinux --xattrs --acls` | preserve labels, xattrs, ACLs (at create and extract) |
| `gzip -k f`, `gzip -d f.gz`, `zcat f.gz` | compress keeping the original, decompress, read |
| `file a.tar.gz` | identify the real compression |

### Users and switching (Part 9)

| Command | Use |
|---|---|
| `su - USER`, `su - USER -c 'cmd'` | login shell as USER; run one command as USER |
| `sudo cmd`, `sudo -i`, `sudo -l` | one command as root; root login shell; list rights |
| `id`, `whoami`, `who`, `tty` | identity, name, logged-in users, current terminal |
| `systemctl get-default` | current default target |

### SSH (Part 10)

| Command | Use |
|---|---|
| `ssh-keygen`, `ssh-copy-id user@host` | create a key pair; install the public key (run **as the local user in the task**) |
| `ssh -o BatchMode=yes user@host cmd` | prove key login works |
| `su - USER -c 'ssh -o BatchMode=yes USER@host hostname'` | prove it works for a non-root user |
| `sshd -t`, `sshd -T` | syntax check; show the effective configuration |
| `ssh-keygen -R host` | forget a changed host key |
| `scp SRC user@host:PATH`, `scp -r`, `scp -P port` | copy; recursive; port |
| `rsync -av src/ user@host:dest/` | sync the contents of src |
| `~/.ssh` 700, `authorized_keys` 600 | required permissions |

### Documentation (Part 11)

| Command | Use |
|---|---|
| `man N name` | page from section N (1 commands, 5 files, 8 admin) |
| `man -k word`, `mandb` | search descriptions; rebuild the index |
| `info name` | GNU info manual |
| `/usr/share/doc/PKG`, `rpm -qd PKG` | package docs and examples |
| `cmd --help`, `help builtin` | quick option list; bash builtin help |
| `dnf provides '*/cmd'` | which package supplies a missing command |

---

# Appendix B: Self-check answers

### Part 0

1. `/` is the top directory of the tree. `root` is the superuser account (UID 0). `/root` is that account's home directory.
2. `/var/log/messages`.
3. The UID is `48`. `/sbin/nologin` means the account cannot log in interactively; it exists to run a service.
4. It is a symbolic link.

### Part 1

1. The shell splits on spaces, so it tries to run a command named `NAME` with the arguments `=` and `value`.
2. The list of matching filenames, such as `/etc/a.conf /etc/b.conf`. It never sees the asterisk (unless nothing matches).
3. Double quotes expand the variable and print your home directory; single quotes print the literal text `$HOME`.
4. The literal text `*.bak`, because bash passes an unmatched pattern through unchanged. `ls` then reports that it cannot access `*.bak`.
5. With `&&`, `rm` runs only if `cd` succeeded. With `;`, a failed `cd` leaves you where you were, and `rm -rf *` runs there.
6. A separate program runs as a child process. It could only change its own directory and would then exit, leaving the shell unchanged.
7. `||` runs its right side whenever everything to its left failed, and everything to its left is `true && false`. `true` succeeded, but `false` failed, so the whole left side failed and `echo c` ran. `a && b || c` is not an if/else.

### Part 2

1. File descriptor 2. It lets errors be routed separately from results, so results can be saved or piped cleanly while errors still reach you.
2. The shell opens and empties `data.txt` before `sort` starts, so `sort` reads an empty file.
3. `cmd > out 2>&1`: fd 1 becomes `out`, then fd 2 copies it, so both go to `out`. `cmd 2>&1 > out`: fd 2 copies fd 1 while it still points at the screen, then fd 1 becomes `out`, so errors appear on the screen.
4. The shell opened the file and connected it to stdin. `wc` never learns the filename, so it has none to print.
5. It reads its stdin, writes a copy to every named file, and writes a copy to its stdout.
6. In the first, your unprivileged shell performs the `>>` redirection before `sudo` runs, so opening `/etc/hosts` fails. In the second, `tee` opens the file, and `tee` runs as root.

### Part 3

1. `grep root` matches `root` anywhere on any line (other words, other fields). `grep '^root:'` matches only the line whose username field is exactly `root`.
2. `a*` means zero or more `a`. Every line contains zero `a`s somewhere, so every line matches.
3. `[^0-9]` matches one character that is not a digit, anywhere on the line. `^[0-9]` matches a digit at the start of the line.
4. `awk` compares values as numbers. A regex only sees characters, so expressing "1000 or more" needs awkward patterns that are easy to get wrong.
5. `uniq` only merges **adjacent** duplicates; `sort` puts identical lines next to each other.
6. Without `-i`, `sed` prints the changed text and leaves the file alone. With `-i`, it rewrites the file.

### Part 4

1. If `/backup` is a directory, the file is copied into it as `/backup/report.txt`. If `/backup` does not exist, a new file named `/backup` is created.
2. Ownership (owner and group), timestamps, and the exact permission bits (plain `cp` filters the bits through the umask and drops special bits).
3. It only changes the directory entry. The inode, which holds the label, is untouched.
4. Write and execute permission on the directory containing the file.
5. Without quotes, the shell may expand `*.log` against files in your current directory before `find` sees the pattern.
6. `-perm -4000` matches any file with the SUID bit set, whatever its other bits. `-perm 4000` matches only a file whose entire mode is exactly 4000.
7. In `/backup/ssh/ssh/sshd_config`. The first run created `/backup/ssh` as the copy. The second time `/backup/ssh` already existed as a directory, so `cp` copied `ssh` into it.
8. `find` rounds each size **up** to whole units of the size you asked for. Every non-empty file becomes at least `1M`, and "less than 1" leaves only size 0. Use `-size -1024k` or a byte count with `c`.
9. `cp -a /home/alice/. /backup/alice/`. The `.` means the directory itself, so its entire contents are copied. `/home/alice/*` would skip every name starting with a dot.

### Part 5

1. Type, permissions, owner, group, size, timestamps, link count, and where the data is stored. It does not hold the file's name.
2. Yes. `b` is a name for the same inode; removing `a` only lowers the link count to 1.
3. No. `b` stores the path `a`, which no longer exists, so `b` is dangling.
4. A hard link is a directory entry holding an inode number, and inode numbers only mean something inside one filesystem.
5. `/tmp/notes.txt`, because a relative target is resolved from the directory that contains the link.

### Part 6

1. No. You are the owner, so only the owner bits (`---`) are used; the group and other bits are never consulted.
2. Write and execute (`w` and `x`) on the directory.
3. `rwxr-x--x` is `751`. `640` is `rw-r-----`.
4. `X` gives execute only to directories (and files that are already executable), so ordinary files do not become executable. `chmod -R 750` makes every file executable for owner and group.
5. New files created inside take the directory's group instead of the creator's primary group, so a team can share files.
6. A new file gets `640` (`rw-r-----`); a new directory gets `750` (`rwxr-x---`).

### Part 7

1. `Esc`, then `:wq`, then Enter.
2. `:q` refuses to quit when there are unsaved changes; `:q!` quits and throws them away.
3. `:%s/http/https/g`. (Careful: this would also turn an existing `https` into `httpss`. Matching `http:` and replacing it with `https:` avoids that. Always look at the data first.)
4. `cat -A file`. Tabs appear as `^I`.

### Part 8

1. Archiving combines many files and their metadata into one file (`tar`). Compressing makes data smaller (`gzip`, `bzip2`, `xz`).
2. `-f` takes the next word as the archive name, so the archive is named `z`, and `x.tar.gz` is treated as a file to put into it.
3. Under `/tmp`, as `/tmp/etc/...`, because tar extracts its relative paths into the current directory.
4. It is replaced by `report.txt.gz`; the original is removed unless you used `-k`.
5. `--selinux` (together with `--xattrs`), both when creating the archive and when extracting it.

### Part 9

1. `su - carol` resets the environment, changes to carol's home directory, and reads the login startup files. Plain `su carol` keeps your environment and your current directory.
2. Your own (the invoking user's) password.
3. Group memberships are fixed when a session starts. She needs a new login.
4. `tty`.

### Part 10

1. The host keys of servers you have connected to, so the client can detect if a server's identity changes.
2. The public key, in `~/.ssh/authorized_keys` of the target account on the server.
3. BatchMode forbids prompts, so it fails instead of quietly falling back to a password. Success therefore proves key authentication works.
4. Without the colon, `scp` makes a local copy named `node2`. With `node2:`, it copies into your home directory on `node2`.
5. Anyone could add their own key and log in as you, so `sshd` (with `StrictModes`) refuses to trust keys stored where others can write.
6. Running the commands as root created **root's** key in `/root/.ssh/` and installed it for whichever remote account you named. The grader connects as `student`, whose `~/.ssh/` has no key. The commands must be run as the local user in the task (`su - student` first).

### Part 11

1. Section 5 for file formats; section 8 for administration commands.
2. `mandb`, then search again.
3. `/usr/share/doc/<package>/`; `rpm -qd <package>` lists the documentation files.
4. `help cd`.
5. `dnf provides '*/semanage'`.

---

*Next step: work through `01-essential-tools-LABS.md`. When you can finish the labs without looking back at these notes, take the timed `01-essential-tools-EXAM.md` and run `grade-01.sh`.*
