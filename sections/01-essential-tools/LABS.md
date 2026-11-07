# RHCSA · Section 1 — Guided Labs
### Run on **node1** as `root` unless stated otherwise

These are guided: the commands are shown. Type them, don't paste — the point is
fingers, not reading. Every lab ends with a verification step. Do not skip it.

Reset point if you wreck something: `rm -rf /labs` and start the lab again.

```bash
mkdir -p /labs && cd /labs
```

---

## Lab 1.1 — Shell syntax, globbing, quoting

```bash
cd /labs
mkdir -p glob && cd glob
touch file{1..5}.txt report{a,b}.log .hidden
ls
ls *.txt
ls file?.txt
ls file[13].txt
ls file[!13].txt
ls -a
```

**Watch what the shell does before the command sees it:**
```bash
echo *.txt
echo /etc/*.conf | tr ' ' '\n' | head
```

Quoting:
```bash
NAME=world
echo "hello $NAME"
echo 'hello $NAME'
echo "today is $(date +%F)"
echo "path is ${PATH}"
```

Prove why quoting variables matters:
```bash
touch "two words.txt"
F="two words.txt"
ls $F          # FAILS - two arguments
ls "$F"        # works
```

Exit status:
```bash
ls /etc >/dev/null; echo $?
ls /nope 2>/dev/null; echo $?
ls /etc && echo "succeeded"
ls /nope 2>/dev/null || echo "failed"
```

**Verify:** you can explain out loud why `ls $F` failed.

---

## Lab 1.2 — Redirection

```bash
cd /labs && mkdir -p redir && cd redir

ls /etc /nosuchdir > out.txt 2> err.txt
cat out.txt | head -3
cat err.txt
```

Combine both:
```bash
ls /etc /nosuchdir > both.txt 2>&1
grep -c . both.txt
```

Now demonstrate the ordering trap — the second command leaks stderr to your terminal:
```bash
ls /etc /nosuchdir > a.txt 2>&1
ls /etc /nosuchdir 2>&1 > b.txt
grep -i 'no such' a.txt && echo "a.txt HAS the error"
grep -i 'no such' b.txt || echo "b.txt does NOT have the error"
```

Append vs overwrite:
```bash
echo one  > f.txt
echo two  > f.txt      # overwrites
cat f.txt
echo three >> f.txt    # appends
cat f.txt
```

tee, and discarding:
```bash
ls /etc | tee list.txt | wc -l
cat list.txt | wc -l
ls /nosuchdir 2> /dev/null; echo "exit=$?"
```

Here-document:
```bash
cat > conf.txt <<'EOF'
Literal: $HOSTNAME
EOF
cat > conf2.txt <<EOF
Expanded: $HOSTNAME
EOF
cat conf.txt conf2.txt
```

**Verify:** `cat conf.txt` shows a literal `$HOSTNAME`; `conf2.txt` shows `node1...`.

---

## Lab 1.3 — grep and regular expressions

```bash
cd /labs && mkdir -p grep && cd grep
cp /etc/passwd .
```

```bash
grep root passwd
grep -i ROOT passwd
grep -n nologin passwd | head -5
grep -c nologin passwd
grep -v nologin passwd
grep '^root' passwd
grep '/bin/bash$' passwd
grep -w root passwd
```

Extended regex:
```bash
grep -E '^(root|student):' passwd
grep -E ':[0-9]{4,}:' passwd
grep -E '^[a-z]+:x:[0-9]+:' passwd | head -3
```

Strip comments and blank lines from a config — you'll do this constantly:
```bash
grep -v '^#' /etc/ssh/sshd_config | grep -v '^$'
grep -vE '^(#|$)' /etc/ssh/sshd_config
```

Context and recursion:
```bash
grep -A2 -B2 'Port' /etc/ssh/sshd_config
grep -rn 'PermitRootLogin' /etc/ssh/
grep -o '[0-9]\+' /etc/passwd | head
```

Field extraction with the neighbours:
```bash
cut -d: -f1,3,7 passwd | head
awk -F: '$3 >= 1000 {print $1, $3}' passwd
awk -F: '{print $7}' passwd | sort | uniq -c | sort -rn
```

**Verify:**
```bash
grep -c '/sbin/nologin$' passwd
awk -F: '$7=="/sbin/nologin"' passwd | wc -l
```
Both numbers must match.

---

## Lab 1.4 — Files, directories, and finding

```bash
cd /labs && mkdir -p fs && cd fs

mkdir -p project/{src,doc,bin}
tree project 2>/dev/null || ls -R project
touch project/src/main.c project/doc/readme.md

cp -a project project-backup
ls -la project-backup/src

mv project-backup project-old
rm -rf project-old/bin
ls project-old
```

Preserving attributes — see the difference:
```bash
touch -d '2020-01-01' original.txt
chmod 640 original.txt
cp original.txt plain.txt
cp -p original.txt preserved.txt
ls -l original.txt plain.txt preserved.txt
```

`plain.txt` has today's date and default permissions; `preserved.txt` matches the
original. **`cp` without `-p` or `-a` silently loses metadata** — a real point-loser.

find:
```bash
find /labs -name '*.txt'
find /etc -maxdepth 1 -name '*.conf' | head
find /var/log -type f -size +100k
find /etc -newer /etc/hostname -maxdepth 1 2>/dev/null | head
find /labs -type f -name '*.c' -exec ls -l {} \;
find / -perm -4000 -type f 2>/dev/null | head
```

**Verify:** `find /labs -type d | wc -l` returns a plausible count.

---

## Lab 1.5 — Hard and soft links

```bash
cd /labs && mkdir -p links && cd links

echo "original content" > data.txt
ln    data.txt hard.txt
ln -s data.txt soft.txt
ls -li
```

Same inode number on `data.txt` and `hard.txt`; `soft.txt` has its own and shows
`-> data.txt`.

```bash
stat data.txt | grep -i links
echo "appended" >> hard.txt
cat data.txt              # changed - same inode
```

Now the critical difference:
```bash
rm data.txt
cat hard.txt              # STILL WORKS
cat soft.txt              # BROKEN - dangling
ls -l soft.txt            # target shown in red
```

Restore and inspect:
```bash
ln hard.txt data.txt
cat soft.txt
readlink soft.txt
readlink -f soft.txt
```

Limits:
```bash
ln /etc/hosts /tmp/hosts.hard      # works: same filesystem
mkdir d && ln d dlink              # FAILS: no hard links to directories
ln -s d dlink                      # works
```

**Verify:**
```bash
ls -li data.txt hard.txt | awk '{print $1}' | uniq | wc -l
```
Must print `1` — one unique inode.

---

## Lab 1.6 — Permissions

```bash
cd /labs && mkdir -p perms && cd perms
useradd -M alice 2>/dev/null; useradd -M bob 2>/dev/null
groupadd -f team
usermod -aG team alice; usermod -aG team bob

touch shared.txt
ls -l shared.txt
chmod 640 shared.txt          ; ls -l shared.txt
chmod u+x,g-r shared.txt      ; ls -l shared.txt
chmod u=rw,g=r,o= shared.txt  ; ls -l shared.txt
chown alice:team shared.txt   ; ls -l shared.txt
stat -c '%U %G %a %n' shared.txt
```

Prove directory `x` is traversal, not listing:
```bash
mkdir -p /labs/perms/vault
echo secret > /labs/perms/vault/f.txt
chmod 711 /labs/perms/vault
chmod 644 /labs/perms/vault/f.txt

su - alice -c 'ls /labs/perms/vault'        # DENIED - no r
su - alice -c 'cat /labs/perms/vault/f.txt' # WORKS  - has x, knows the name
```

That is the single most misunderstood thing about Unix permissions.

Special bits:
```bash
mkdir /labs/perms/shared
chgrp team /labs/perms/shared
chmod 2775 /labs/perms/shared
ls -ld /labs/perms/shared                     # rwxrwsr-x

su - alice -c 'touch /labs/perms/shared/a.txt'
ls -l /labs/perms/shared/a.txt                # group is 'team', inherited via SGID
```

Sticky bit:
```bash
mkdir /labs/perms/drop
chmod 1777 /labs/perms/drop
ls -ld /labs/perms/drop                       # rwxrwxrwt
su - alice -c 'touch /labs/perms/drop/a'
su - bob   -c 'rm /labs/perms/drop/a'         # DENIED - sticky
```

umask:
```bash
umask
umask 077; touch restricted.txt; mkdir restricted.d
ls -l restricted.txt; ls -ld restricted.d     # 600 and 700
umask 022
```

**Verify:**
```bash
stat -c '%a' /labs/perms/shared     # 2775
stat -c '%a' /labs/perms/drop       # 1777
```

---

## Lab 1.7 — Archiving and compression

```bash
cd /labs && mkdir -p arch && cd arch

tar -czvf etc-sysconfig.tar.gz /etc/sysconfig
tar -tzvf etc-sysconfig.tar.gz | head
```

Note the "Removing leading `/`" warning — that's tar making the paths relative. Good.

```bash
tar -cjvf logs.tar.bz2 /var/log/anaconda
tar -cJvf logs.tar.xz  /var/log/anaconda
ls -lh *.tar.*
```

Compare the three compressors on the same input, then extract:
```bash
mkdir -p restore
tar -xzvf etc-sysconfig.tar.gz -C restore
ls restore/etc/sysconfig | head
```

Archive without the leading path, and with an exclusion:
```bash
tar -czf sysconfig-only.tar.gz -C /etc sysconfig
tar -tzf sysconfig-only.tar.gz | head -3

tar -czf nolog.tar.gz --exclude='*.log' /var/log/anaconda
tar -tzf nolog.tar.gz | grep -c '\.log$'      # expect 0
```

Preserve SELinux contexts — matters when restoring system files:
```bash
tar --selinux --xattrs -czf ssh-backup.tar.gz /etc/ssh
mkdir -p /labs/arch/sshrestore
tar --selinux --xattrs -xzf ssh-backup.tar.gz -C /labs/arch/sshrestore
ls -Z /labs/arch/sshrestore/etc/ssh/sshd_config
```

Standalone compressors:
```bash
cp /etc/services .
gzip -k services  ; ls -lh services*
bzip2 -k services ; ls -lh services*
xz    -k services ; ls -lh services*
zcat services.gz | head -3
gunzip services.gz
```

**Verify:**
```bash
tar -tzf etc-sysconfig.tar.gz >/dev/null && echo "archive is readable"
file logs.tar.bz2
```

---

## Lab 1.8 — SSH and secure transfer

```bash
ssh root@node2 'hostname; uptime'
```

Key-based auth:
```bash
ssh-keygen -t rsa -b 3072 -N '' -f /root/.ssh/id_rsa
ssh-copy-id root@node2
ssh root@node2 'hostname'          # no password prompt
```

Inspect the permissions sshd insists on:
```bash
ls -ld /root/.ssh
ls -l  /root/.ssh
ssh root@node2 'ls -l ~/.ssh/authorized_keys'
```

Break it deliberately, then fix it — this is how you'll recognise the failure:
```bash
ssh root@node2 'chmod 644 ~/.ssh/authorized_keys'
ssh -o BatchMode=yes root@node2 'hostname'     # FAILS, falls back to password
ssh root@node2 'chmod 600 ~/.ssh/authorized_keys'   # type the password
ssh -o BatchMode=yes root@node2 'hostname'     # works again
```

File transfer:
```bash
scp /labs/arch/etc-sysconfig.tar.gz root@node2:/tmp/
ssh root@node2 'ls -lh /tmp/etc-sysconfig.tar.gz'
scp root@node2:/etc/hostname /tmp/node2-hostname
cat /tmp/node2-hostname

rsync -av /labs/arch/ root@node2:/tmp/archsync/
ssh root@node2 'ls /tmp/archsync'
```

**Verify:**
```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 root@node2 true && echo "key auth OK"
```

---

## Lab 1.9 — Switching users

```bash
useradd -m carol 2>/dev/null
echo 'redhat' | passwd --stdin carol

su - carol
  whoami
  id
  echo $PATH
  exit

su carol -c 'echo $PATH'      # note: NOT a login shell
su - carol -c 'echo $PATH'    # login shell - different PATH
```

sudo:
```bash
usermod -aG wheel carol
su - carol
  sudo whoami                 # 'root' after entering carol's password
  sudo -i
    whoami
    exit
  exit
```

Who's on:
```bash
who
w
last | head
id carol
groups carol
```

**Verify:** `su - carol -c 'sudo -n true' ; echo $?` — nonzero is fine (it prompts);
the point is that `wheel` membership grants the right.

---

## Lab 1.10 — Documentation

Offline documentation is your only resource in the exam. Practise finding answers.

```bash
man -k passwd
man -f passwd
man 1 passwd     # the command
man 5 passwd     # the file format
```

Answer these **using only man pages**, and write the answers down:

1. Which field of `/etc/shadow` holds the maximum password age? → `man 5 shadow`
2. What `/etc/fstab` option prevents a failed mount from blocking boot? → `man 5 fstab`
3. Which `tar` option preserves SELinux contexts? → `man 1 tar`, then `/selinux`
4. What does the `crontab` field order look like? → `man 5 crontab`
5. Which `useradd` flag sets a non-default home directory? → `man 8 useradd`

Rebuild the index if `man -k` fails:
```bash
mandb
man -k firewall | head
```

Sample configs and package docs:
```bash
ls /usr/share/doc | head -30
rpm -qd openssh-server | head
rpm -qc openssh-server
rpm -qf /etc/ssh/sshd_config
```

The offline lifeline:
```bash
dnf provides */semanage
dnf provides */showmount
dnf provides '*/bin/lsof'
```

Builtins have no man page:
```bash
help cd
help test
type -a cd
```

**Verify:** you found all five answers without a browser. If any took more than 60
seconds, redo it — documentation speed is a graded skill in disguise.

---

## Cleanup

```bash
cd /
rm -rf /labs
userdel -r carol 2>/dev/null
userdel alice 2>/dev/null; userdel bob 2>/dev/null
groupdel team 2>/dev/null
rm -f /tmp/hosts.hard /tmp/node2-hostname
ssh root@node2 'rm -rf /tmp/archsync /tmp/etc-sysconfig.tar.gz'
```

Leave the SSH keys in place — you'll want them for later sections.
