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
printf 'a\n' > "$TMP/tree/etc/sysconfig/one"
printf 'b\n' > "$TMP/tree/etc/sysconfig/two"
( cd "$TMP/tree" && tar -czf "$TMP/t.tar.gz" etc/sysconfig )
mkdir -p "$TMP/full" && tar -xzf "$TMP/t.tar.gz" -C "$TMP/full"
mkdir -p "$TMP/empty"
mkdir -p "$TMP/partial/etc/sysconfig" && printf 'a\n' > "$TMP/partial/etc/sysconfig/one"
assert_ok   "fully extracted tree is accepted"      archive_matches_tree "$TMP/t.tar.gz" "$TMP/full"
assert_fail "empty directory is rejected"           archive_matches_tree "$TMP/t.tar.gz" "$TMP/empty"
assert_fail "partial extraction is rejected"        archive_matches_tree "$TMP/t.tar.gz" "$TMP/partial"
assert_fail "missing archive is rejected"           archive_matches_tree "$TMP/nope.tar.gz" "$TMP/full"

echo "== archive_has_xattr_key"
# Negative case always runs: an archive with no xattrs must not pass.
( cd "$TMP/tree" && tar -cjf "$TMP/plain.tar.bz2" etc/sysconfig )
assert_fail "archive without xattrs is rejected"    archive_has_xattr_key "$TMP/plain.tar.bz2" 'security\.selinux'
assert_fail "missing archive is rejected"           archive_has_xattr_key "$TMP/gone.tar.bz2" 'security\.selinux'

# The fallback path reads pax headers straight out of the stream. Prove it
# recognises the two keyword spellings RHEL tar has used.
for key in SCHILY.xattr.security.selinux RHT.security.selinux; do
    mkdir -p "$TMP/pax"; printf '%s=system_u:object_r:etc_t:s0\n' "$key" > "$TMP/pax/header"
    ( cd "$TMP/pax" && tar -cjf "$TMP/pax-$key.tar.bz2" header )
    assert_ok "pax keyword $key is recognised" \
        archive_has_xattr_key "$TMP/pax-$key.tar.bz2" 'security\.selinux'
done

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
