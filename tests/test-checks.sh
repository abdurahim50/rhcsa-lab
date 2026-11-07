#!/bin/bash
# =====================================================================
# test-checks.sh  --  offline tests for the grader's helpers.
#
# Runs anywhere bash and tar exist; needs no RHEL, no root, no VMs.
# It exists because a grader bug is invisible: a check that can never
# pass looks exactly like a learner who got the task wrong.
#
#   ./tests/test-checks.sh
# =====================================================================
set -u

HERE=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
# shellcheck source=../sections/01-essential-tools/lib/checks.sh
. "$HERE/../sections/01-essential-tools/lib/checks.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
RUN=0; FAIL=0; SKIP=0

pass_() { printf '  \033[32mok\033[0m    %s\n' "$1"; }
fail_() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; printf '        %s\n' "$2"; FAIL=$((FAIL+1)); }
skip_() { printf '  \033[33mskip\033[0m  %s\n' "$1"; SKIP=$((SKIP+1)); }

# assert_ok   <description> <command...>
assert_ok() {
    local desc=$1; shift; RUN=$((RUN+1))
    if "$@"; then pass_ "$desc"; else fail_ "$desc" "expected success, got failure: ${CHECK_WHY:-}"; fi
}
# assert_fail <description> <command...>
assert_fail() {
    local desc=$1; shift; RUN=$((RUN+1))
    if "$@"; then fail_ "$desc" "expected failure, but it passed: ${CHECK_WHY:-}"; else pass_ "$desc"; fi
}

echo "== same_metadata"
mkdir -p "$TMP/meta"
printf 'x\n' > "$TMP/meta/src"
cp -p "$TMP/meta/src" "$TMP/meta/preserved"
cp    "$TMP/meta/src" "$TMP/meta/plain"
touch -d '2001-02-03 04:05:06' "$TMP/meta/src"      # force a timestamp gap
assert_fail "plain cp is rejected (mtime differs)"  same_metadata "$TMP/meta/src" "$TMP/meta/plain"
touch -r "$TMP/meta/src" "$TMP/meta/preserved"
assert_ok   "cp -p equivalent is accepted"          same_metadata "$TMP/meta/src" "$TMP/meta/preserved"
assert_fail "missing destination is rejected"       same_metadata "$TMP/meta/src" "$TMP/meta/absent"
chmod 600 "$TMP/meta/preserved"
assert_fail "mode change is rejected"               same_metadata "$TMP/meta/src" "$TMP/meta/preserved"

echo "== archive_matches_tree"
mkdir -p "$TMP/tree/etc/sysconfig"
printf 'alpha\n' > "$TMP/tree/etc/sysconfig/one"
printf 'beta\n'  > "$TMP/tree/etc/sysconfig/two"
( cd "$TMP/tree" && tar -czf "$TMP/t.tar.gz" etc/sysconfig )

mkdir -p "$TMP/full"    && tar -xzf "$TMP/t.tar.gz" -C "$TMP/full"
mkdir -p "$TMP/empty"
mkdir -p "$TMP/partial" && tar -xzf "$TMP/t.tar.gz" -C "$TMP/partial" && rm "$TMP/partial/etc/sysconfig/two"
# Right names, wrong bytes. This is what an existence-only check waves through.
mkdir -p "$TMP/hollow/etc/sysconfig" && : > "$TMP/hollow/etc/sysconfig/one" && : > "$TMP/hollow/etc/sysconfig/two"
# Same byte count, different content: size alone cannot catch this.
mkdir -p "$TMP/samesize" && tar -xzf "$TMP/t.tar.gz" -C "$TMP/samesize" && printf 'bets\n' > "$TMP/samesize/etc/sysconfig/two"
# Correct contents, different mtime: must still pass, nobody asked for -p.
mkdir -p "$TMP/touched" && tar -xzf "$TMP/t.tar.gz" -C "$TMP/touched" && touch "$TMP/touched/etc/sysconfig/one"

assert_ok   "fully extracted tree is accepted"      archive_matches_tree "$TMP/t.tar.gz" "$TMP/full"
assert_ok   "differing mtime alone still passes"    archive_matches_tree "$TMP/t.tar.gz" "$TMP/touched"
assert_fail "empty directory is rejected"           archive_matches_tree "$TMP/t.tar.gz" "$TMP/empty"
assert_fail "partial extraction is rejected"        archive_matches_tree "$TMP/t.tar.gz" "$TMP/partial"
assert_fail "empty files with right names rejected" archive_matches_tree "$TMP/t.tar.gz" "$TMP/hollow"
assert_fail "same-size corrupted file is rejected"  archive_matches_tree "$TMP/t.tar.gz" "$TMP/samesize"
assert_fail "missing archive is rejected"           archive_matches_tree "$TMP/nope.tar.gz" "$TMP/full"

echo "== archive_has_xattr_key"
# Negative case always runs: an archive with no xattrs must not pass.
( cd "$TMP/tree" && tar -cjf "$TMP/plain.tar.bz2" etc/sysconfig )
assert_fail "archive without xattrs is rejected"    archive_has_xattr_key "$TMP/plain.tar.bz2" 'security\.selinux'
assert_fail "missing archive is rejected"           archive_has_xattr_key "$TMP/gone.tar.bz2" 'security\.selinux'

# Build archives carrying GENUINE pax metadata, without needing setfattr,
# and prove both keyword spellings RHEL tar has used are recognised.
for key in SCHILY.xattr.security.selinux RHT.security.selinux; do
    RHCSA_OUT="$TMP/pax-$key.tar.bz2" RHCSA_KEY=$key python3 -I -c '
import io, os, tarfile
info = tarfile.TarInfo("etc/ssh/sshd_config"); data = b"PermitRootLogin yes\n"
info.size = len(data)
info.pax_headers = {os.environ["RHCSA_KEY"]: "system_u:object_r:etc_t:s0"}
with tarfile.open(os.environ["RHCSA_OUT"], "w:bz2", format=tarfile.PAX_FORMAT) as tf:
    tf.addfile(info, io.BytesIO(data))
'
    assert_ok "real pax keyword $key is recognised" \
        archive_has_xattr_key "$TMP/pax-$key.tar.bz2" 'security\.selinux'
done

# THE false-positive guard. An ordinary text file whose CONTENT mentions
# the keyword carries no SELinux metadata whatsoever. A check that reads
# the raw stream passes this and awards the mark for a text file.
mkdir -p "$TMP/decoy"
printf 'SCHILY.xattr.security.selinux=system_u:object_r:etc_t:s0\n' > "$TMP/decoy/notes.txt"
printf 'see also RHT.security.selinux in older tar\n' >> "$TMP/decoy/notes.txt"
( cd "$TMP/decoy" && tar -cjf "$TMP/decoy.tar.bz2" notes.txt )
assert_fail "keyword in file CONTENT does not count" \
    archive_has_xattr_key "$TMP/decoy.tar.bz2" 'security\.selinux'

# Same trap one level up: a FILENAME containing the keyword is not metadata.
mkdir -p "$TMP/decoy2"
: > "$TMP/decoy2/security.selinux"
( cd "$TMP/decoy2" && tar -cjf "$TMP/decoy2.tar.bz2" security.selinux )
assert_fail "keyword in a FILENAME does not count" \
    archive_has_xattr_key "$TMP/decoy2.tar.bz2" 'security\.selinux'

# Real xattrs, when the host can make them. GitHub runners can after
# installing attr; most sandboxes cannot, so this skips rather than fails.
if command -v setfattr >/dev/null 2>&1 &&
   setfattr -n user.rhcsa.test -v present "$TMP/tree/etc/sysconfig/one" 2>/dev/null; then
    ( cd "$TMP/tree" && tar --xattrs -cjf "$TMP/xattr.tar.bz2" etc/sysconfig )
    RUN=$((RUN+1))
    if archive_has_xattr_key "$TMP/xattr.tar.bz2" 'user\.rhcsa\.test'; then
        pass_ "real stored xattr is detected"
    else
        fail_ "real stored xattr is detected" "tar stored it but the check missed it: $CHECK_WHY"
    fi
    assert_fail "unrelated key is not matched" archive_has_xattr_key "$TMP/xattr.tar.bz2" 'security\.selinux'
else
    skip_ "real xattr round-trip (setfattr unavailable on this host)"
fi

echo
printf 'ran %d, failed %d, skipped %d\n' "$RUN" "$FAIL" "$SKIP"
(( FAIL == 0 ))
