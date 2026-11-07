#!/bin/bash
# =====================================================================
# grade.sh  --  grades RHCSA Section 1 practice tasks.
# Run as root on node1, AFTER a reboot.
#
#   scp root@node1:/path/grade.sh /root/  ... or curl it from the host
#   chmod +x grade.sh && ./grade.sh
#
# Read-only: it inspects, it never fixes anything for you.
# Exits 0 only if you scored 70% or more, so CI and scripts can use it.
# =====================================================================

R=/opt/reports
NODE2=node2.lab.example.com
PASS=0; TOTAL=0
declare -a MISSED

# Shared, unit-tested verification helpers. Keep grade.sh next to lib/.
LIB=${BASH_SOURCE[0]%/*}/lib/checks.sh
if [[ -r $LIB ]]; then
    # shellcheck source=lib/checks.sh
    . "$LIB"
else
    echo "Cannot read $LIB - copy the whole section folder, not just this file." >&2
    exit 2
fi

ssh2() {
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=8 \
        "root@$NODE2" "$@" 2>/dev/null
}

ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; PASS=$((PASS+1)); }
no()   { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; printf '        \033[33mwhy:\033[0m %s\n' "$2"; MISSED+=("$3"); }
task() { TOTAL=$((TOTAL+1)); printf '\n\033[1mTask %s\033[0m — %s\n' "$1" "$2"; }

[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }

echo "==============================================="
echo " RHCSA Section 1 — Essential Tools"
echo " Graded on $(hostname -f) at $(date '+%F %T')"
echo "==============================================="

# ---------------------------------------------------------------- 1
task 1 "SGID collaborative directory"
if [[ ! -d $R ]]; then
    no "/opt/reports" "directory does not exist" "1: mkdir -p /opt/reports"
else
    MODE=$(stat -c %a "$R"); OWN=$(stat -c %U:%G "$R")
    if [[ $OWN == root:wheel && $MODE == 2775 ]]; then
        ok "root:wheel, mode 2775"
    else
        no "/opt/reports" "found $OWN mode $MODE, expected root:wheel mode 2775" \
           "1: chown root:wheel /opt/reports; chmod 2775 /opt/reports"
    fi
fi

# ---------------------------------------------------------------- 2
task 2 "Preserved copies of passwd/group/shadow"
MISS=""; BAD=""
for f in passwd group shadow; do
    if [[ ! -f $R/etc-copies/$f ]]; then MISS+="$f "; continue; fi
    same_metadata "/etc/$f" "$R/etc-copies/$f" || BAD+="$f($CHECK_WHY) "
done
if [[ -z $MISS && -z $BAD ]]; then
    ok "all three copied with original ownership, mode and timestamps"
else
    no "etc-copies" "missing: ${MISS:-none}; wrong metadata: ${BAD:-none}" \
       "2: cp -p /etc/{passwd,group,shadow} /opt/reports/etc-copies/   (plain cp loses the timestamps)"
fi

# ---------------------------------------------------------------- 3
task 3 "Lines for /sbin/nologin accounts"
EXP=$(awk -F: '$7=="/sbin/nologin"' /etc/passwd | sort)
if [[ ! -f $R/nologin.txt ]]; then
    no "nologin.txt" "file does not exist" "3: awk -F: '\$7==\"/sbin/nologin\"' /etc/passwd > $R/nologin.txt"
elif [[ "$(sort "$R/nologin.txt")" == "$EXP" ]]; then
    ok "$(wc -l < "$R/nologin.txt") lines, exact match"
else
    no "nologin.txt" "contents differ; expected $(wc -l <<<"$EXP") lines, got $(wc -l < "$R/nologin.txt")" \
       "3: grep '/sbin/nologin\$' /etc/passwd > $R/nologin.txt"
fi

# ---------------------------------------------------------------- 4
task 4 "Count of UID >= 1000"
EXP=$(awk -F: '$3>=1000' /etc/passwd | wc -l)
GOT=$(tr -d '[:space:]' < "$R/usercount.txt" 2>/dev/null)
if [[ $GOT == "$EXP" ]]; then
    ok "$EXP"
else
    no "usercount.txt" "expected '$EXP', got '${GOT:-<missing>}'" \
       "4: awk -F: '\$3>=1000' /etc/passwd | wc -l > $R/usercount.txt"
fi

# ---------------------------------------------------------------- 5
task 5 "Sorted usernames with /bin/bash"
EXP=$(awk -F: '$7=="/bin/bash"{print $1}' /etc/passwd | sort)
if [[ ! -f $R/bashusers.txt ]]; then
    no "bashusers.txt" "file does not exist" \
       "5: awk -F: '\$7==\"/bin/bash\"{print \$1}' /etc/passwd | sort > $R/bashusers.txt"
elif [[ "$(cat "$R/bashusers.txt")" == "$EXP" ]]; then
    ok "usernames only, sorted"
else
    no "bashusers.txt" "expected:\n$EXP\n        got:\n$(cat "$R/bashusers.txt")" \
       "5: usernames only (field 1), sorted, no other fields"
fi

# ---------------------------------------------------------------- 6
task 6 "gzip archive of /etc/sysconfig"
if [[ ! -f /root/sysconfig.tar.gz ]]; then
    no "sysconfig.tar.gz" "file does not exist" "6: tar -czf /root/sysconfig.tar.gz /etc/sysconfig"
elif ! file -b /root/sysconfig.tar.gz | grep -qi gzip; then
    no "sysconfig.tar.gz" "not gzip: $(file -b /root/sysconfig.tar.gz)" "6: use tar -czf (z = gzip)"
elif tar -tzf /root/sysconfig.tar.gz 2>/dev/null | grep -q 'etc/sysconfig/'; then
    ok "gzip, contains etc/sysconfig/"
else
    no "sysconfig.tar.gz" "gzip but etc/sysconfig/ not found inside" "6: tar -czf /root/sysconfig.tar.gz /etc/sysconfig"
fi

# ---------------------------------------------------------------- 7
task 7 "bzip2 archive of /etc/ssh with SELinux contexts"
if [[ ! -f /root/sshconf.tar.bz2 ]]; then
    no "sshconf.tar.bz2" "file does not exist" \
       "7: tar --selinux --xattrs -cjf /root/sshconf.tar.bz2 /etc/ssh"
elif ! file -b /root/sshconf.tar.bz2 | grep -qi bzip2; then
    no "sshconf.tar.bz2" "not bzip2: $(file -b /root/sshconf.tar.bz2)" "7: use tar -cjf (j = bzip2)"
elif ! tar -tjf /root/sshconf.tar.bz2 2>/dev/null | grep -q 'etc/ssh/'; then
    no "sshconf.tar.bz2" "bzip2 but etc/ssh/ not found inside" "7: tar -cjf ... /etc/ssh"
elif archive_has_selinux_xattr /root/sshconf.tar.bz2; then
    ok "bzip2, /etc/ssh, SELinux contexts stored ($CHECK_WHY)"
else
    no "sshconf.tar.bz2" "archive is correct but carries no SELinux context metadata ($CHECK_WHY)" \
       "7: add --selinux --xattrs to the tar command"
fi

# ---------------------------------------------------------------- 8
task 8 "Hard link and symlink to /etc/hosts"
HOK=0; SOK=0
if [[ -f $R/hosts.hard ]] && [[ "$(stat -c %i /etc/hosts)" == "$(stat -c %i "$R/hosts.hard" 2>/dev/null)" ]]; then HOK=1; fi
if [[ -L $R/hosts.soft ]] && [[ "$(readlink -f "$R/hosts.soft" 2>/dev/null)" == "/etc/hosts" ]]; then SOK=1; fi
if (( HOK && SOK )); then
    ok "hard link shares inode $(stat -c %i /etc/hosts); symlink resolves to /etc/hosts"
else
    D=""
    (( HOK )) || D+="hosts.hard is not a hard link to /etc/hosts (inode mismatch); "
    (( SOK )) || D+="hosts.soft is not a symlink resolving to /etc/hosts; "
    no "links" "$D" "8: ln /etc/hosts $R/hosts.hard ; ln -s /etc/hosts $R/hosts.soft"
fi

# ---------------------------------------------------------------- 9
task 9 "Owner-only file with exact content"
if [[ ! -f $R/secret.txt ]]; then
    no "secret.txt" "file does not exist" "9: echo classified > $R/secret.txt; chmod 600 ..."
else
    C=$(cat "$R/secret.txt"); M=$(stat -c %a "$R/secret.txt"); O=$(stat -c %U:%G "$R/secret.txt")
    if [[ $C == "classified" && $M == 600 && $O == root:root ]]; then
        ok "content, root:root, 0600"
    else
        no "secret.txt" "content='$C' mode=$M owner=$O; expected 'classified' / 600 / root:root" \
           "9: echo classified > $R/secret.txt; chown root:root ...; chmod 600 ..."
    fi
fi

# --------------------------------------------------------------- 10
task 10 "Split stdout and stderr"
OOK=0; EOK=0
[[ -s $R/out.txt ]] && grep -q '^passwd$' "$R/out.txt" && ! grep -qi 'no such' "$R/out.txt" && OOK=1
[[ -s $R/err.txt ]] && grep -qi 'no such file' "$R/err.txt" && EOK=1
if (( OOK && EOK )); then
    ok "out.txt has the listing only; err.txt has the error only"
else
    D=""
    (( OOK )) || D+="out.txt missing, empty, or contaminated with the error; "
    (( EOK )) || D+="err.txt missing or does not contain the error; "
    no "redirection" "$D" "10: ls /etc /nosuchdir > $R/out.txt 2> $R/err.txt"
fi

# --------------------------------------------------------------- 11
task 11 "Combined stdout and stderr"
if [[ -s $R/both.txt ]] && grep -q '^passwd$' "$R/both.txt" && grep -qi 'no such file' "$R/both.txt"; then
    ok "both streams captured in one file"
else
    no "both.txt" "must contain BOTH the /etc listing and the error message" \
       "11: ls /etc /nosuchdir > $R/both.txt 2>&1   (note: order matters)"
fi

# --------------------------------------------------------------- 12
task 12 "Man section for the passwd FILE FORMAT"
GOT=$(tr -d '[:space:]' < "$R/mansection.txt" 2>/dev/null)
if [[ $GOT == "5" ]]; then
    ok "5"
else
    no "mansection.txt" "expected '5', got '${GOT:-<missing>}'" \
       "12: man -f passwd  -> section 5 is file formats; section 1 is the command"
fi

# --------------------------------------------------------------- 13
task 13 "Passwordless SSH to node2"
if ssh2 true; then
    ok "key-based login to root@node2 works non-interactively"
else
    no "ssh key auth" "BatchMode login to root@node2 failed (key missing, wrong perms, or node2 down)" \
       "13: ssh-keygen -N '' ; ssh-copy-id root@node2 ; check ~/.ssh is 700 and authorized_keys 600"
fi

# --------------------------------------------------------------- 14
task 14 "Archive copied to node2:/tmp"
LOCAL_SHA=$(file_sha /root/sysconfig.tar.gz)
REMOTE_SHA=$(ssh2 'sha256sum /tmp/sysconfig.tar.gz 2>/dev/null | cut -d" " -f1')
if [[ -z $REMOTE_SHA ]]; then
    no "scp" "/tmp/sysconfig.tar.gz not found on node2 (or SSH unavailable)" \
       "14: scp /root/sysconfig.tar.gz root@node2:/tmp/"
elif [[ -z $LOCAL_SHA ]]; then
    no "scp" "a file exists on node2 but /root/sysconfig.tar.gz is missing locally, so it cannot be the same file" \
       "14: finish task 6 first, then scp the archive"
elif [[ $LOCAL_SHA == "$REMOTE_SHA" ]]; then
    ok "/tmp/sysconfig.tar.gz on node2 is byte-identical to the local archive"
else
    no "scp" "node2 has a /tmp/sysconfig.tar.gz but its checksum differs from the local archive (stale copy from an earlier attempt?)" \
       "14: re-copy it: scp /root/sysconfig.tar.gz root@node2:/tmp/"
fi

# --------------------------------------------------------------- 15
task 15 "Extracted archive"
if [[ ! -d $R/archive ]]; then
    no "archive extraction" "$R/archive does not exist" \
       "15: mkdir -p $R/archive; tar -xzf /root/sysconfig.tar.gz -C $R/archive"
elif archive_matches_tree /root/sysconfig.tar.gz "$R/archive"; then
    ok "every member of the archive is present under $R/archive"
else
    no "archive extraction" "$CHECK_WHY" \
       "15: mkdir -p $R/archive; tar -xzf /root/sysconfig.tar.gz -C $R/archive"
fi

# --------------------------------------------------------------- result
PCT=$(( PASS * 100 / TOTAL ))
echo
echo "==============================================="
printf ' SCORE: %d / %d  (%d%%)\n' "$PASS" "$TOTAL" "$PCT"
if (( PCT >= 70 )); then
    printf ' \033[32mPASSING\033[0m — the real exam needs 70%%.\n'
else
    printf ' \033[31mBELOW PASSING\033[0m — the real exam needs 70%%.\n'
fi
echo "==============================================="

if (( ${#MISSED[@]} )); then
    echo
    echo "Review these:"
    printf '  %s\n' "${MISSED[@]}"
    echo
    echo "Redo the matching guided lab, then retake this set in 2-3 days."
    echo "Do not just apply the fixes above and re-grade -- that trains nothing."
fi

# Exit status mirrors the result: 0 passing, 1 below 70%.
(( PCT >= 70 ))
