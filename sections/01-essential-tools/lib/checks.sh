#!/bin/bash
# =====================================================================
# checks.sh  --  verification helpers shared by grade.sh and the tests.
#
# Sourced, not executed. Every function is pure: it inspects and returns
# 0 or 1, and writes an explanation to CHECK_WHY for the caller to show.
#
# These live apart from grade.sh so tests/test-checks.sh can exercise
# them off a RHEL box, in CI. The bugs this file exists to prevent are
# graders that silently always-pass or always-fail.
# =====================================================================

# CHECK_WHY is written here and read by whoever sources this file.
# shellcheck disable=SC2034
CHECK_WHY=""

# archive_has_xattr_key <archive> <extended-regex matching the xattr name>
#
# Does the archive carry stored extended attributes matching the key?
#
# Getting this right is harder than it looks, and both easy approaches
# are wrong:
#
#   tar -tvf | grep ...     NEVER shows xattrs at all, so the check can
#                           never pass. GNU tar needs --xattrs and two
#                           -v flags, and even then some archives list
#                           nothing useful.
#   zcat archive | grep ... searches FILE CONTENTS as well as headers,
#                           so an ordinary text file that happens to
#                           mention security.selinux passes. That is a
#                           grader handing out marks for a text file.
#
# The only correct answer is to parse the pax metadata. Python's
# tarfile does exactly that and exposes it per member, and python3 is
# present on every RHEL 10 install. GNU tar stores these keys as
# SCHILY.xattr.<name>; RHEL's older patched tar used RHT.<name>.
archive_has_xattr_key() {
    local archive=$1 key=$2 found
    [[ -f $archive ]] || { CHECK_WHY="archive $archive does not exist"; return 1; }

    if command -v python3 >/dev/null 2>&1; then
        found=$(RHCSA_ARCHIVE=$archive RHCSA_KEY=$key python3 -I -c '
import os, re, sys, tarfile
key = re.compile(os.environ["RHCSA_KEY"])
try:
    with tarfile.open(os.environ["RHCSA_ARCHIVE"]) as tf:
        for member in tf:
            for name in member.pax_headers:
                stripped = re.sub(r"^(SCHILY\.xattr\.|RHT\.)", "", name)
                if key.search(stripped):
                    print(f"{member.name}: {name}")
                    sys.exit(0)
except Exception as exc:
    print(f"unreadable: {exc}", file=sys.stderr)
    sys.exit(2)
' 2>/dev/null)
        if [[ -n $found ]]; then
            CHECK_WHY="pax metadata carries it (${found})"
            return 0
        fi
        CHECK_WHY="no stored xattr matching '${key}' in the archive's pax metadata"
        return 1
    fi

    # No python3: fall back to tar's own parse. Anchored to the "x:"
    # attribute lines so a FILENAME containing the key cannot match.
    if tar --xattrs -tvvf "$archive" 2>/dev/null |
           grep -Eq "^[[:space:]]*x:[[:space:]]+[0-9]+[[:space:]]+.*${key}"; then
        CHECK_WHY="xattr matching '${key}' listed by tar --xattrs -tvv"
        return 0
    fi
    CHECK_WHY="no stored xattr matching '${key}' (checked with tar; python3 unavailable)"
    return 1
}

# archive_has_selinux_xattr <archive>
archive_has_selinux_xattr() {
    archive_has_xattr_key "$1" 'security\.selinux'
}

# same_metadata <src> <dst>
#
# Do two files share owner, group, mode AND modification time?
#
# The mtime is the part that matters: as root, a plain "cp" of a 644
# root:root file produces another 644 root:root file, so owner and mode
# alone cannot tell "cp" from "cp -p". Only the timestamp can.
same_metadata() {
    local src=$1 dst=$2 a b
    [[ -f $src ]] || { CHECK_WHY="source $src does not exist"; return 1; }
    [[ -f $dst ]] || { CHECK_WHY="$dst does not exist"; return 1; }

    a=$(stat -c '%U:%G:%a:%Y' "$src")
    b=$(stat -c '%U:%G:%a:%Y' "$dst")
    if [[ $a == "$b" ]]; then
        CHECK_WHY="owner, group, mode and mtime all match"
        return 0
    fi

    local -a d=()
    [[ $(stat -c %U "$src") == "$(stat -c %U "$dst")" ]] || d+=("owner")
    [[ $(stat -c %G "$src") == "$(stat -c %G "$dst")" ]] || d+=("group")
    [[ $(stat -c %a "$src") == "$(stat -c %a "$dst")" ]] || d+=("mode")
    [[ $(stat -c %Y "$src") == "$(stat -c %Y "$dst")" ]] || d+=("mtime")
    CHECK_WHY="differs in: ${d[*]} (want $a, got $b)"
    return 1
}

# archive_matches_tree <archive> <extracted-root>
#
# Was the archive genuinely extracted here: every member present, and
# every file's CONTENT matching what the archive holds?
#
# Checking that the paths exist is not enough. Empty files with the
# right names pass that, and so does a half-finished extraction that
# was interrupted. "tar --compare" does the real work: it reads the
# archive and diffs each member against what is on disk.
#
# Timestamp and ownership differences are deliberately ignored. The
# task asks for the contents to be extracted, not for metadata to be
# preserved, and failing someone over an mtime they were never asked
# to keep is the grader being wrong, not the learner.
archive_matches_tree() {
    local archive=$1 root=$2 out real total
    [[ -f $archive ]] || { CHECK_WHY="archive $archive does not exist"; return 1; }
    [[ -d $root ]]    || { CHECK_WHY="$root does not exist"; return 1; }

    total=$(tar -tf "$archive" 2>/dev/null | grep -c .)
    if (( total == 0 )); then
        CHECK_WHY="could not list the archive's contents"
        return 1
    fi

    # Keep only the differences that mean the extraction is wrong.
    out=$(tar --compare --file="$archive" --directory="$root" 2>&1 |
          grep -Ev ': (Mod time|Mode|Uid|Gid) differs$')
    real=$(printf '%s' "$out" | grep -c .)

    if (( real == 0 )); then
        CHECK_WHY="all $total members present and matching under $root"
        return 0
    fi
    CHECK_WHY="$real of $total members wrong: $(printf '%s' "$out" |
               sed 's/^tar: //' | head -3 | paste -sd'; ' -)"
    return 1
}

# file_sha <path>  -- sha256 of a file, empty string if unreadable
file_sha() { sha256sum -- "$1" 2>/dev/null | cut -d' ' -f1; }
