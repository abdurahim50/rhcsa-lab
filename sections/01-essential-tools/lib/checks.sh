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

# Write an archive's uncompressed bytes to stdout, whatever it is
# compressed with. Used to read pax headers directly.
archive_raw_stream() {
    case $1 in
        *.bz2|*.tbz2) bzip2 -dc -- "$1" ;;
        *.gz|*.tgz)   gzip  -dc -- "$1" ;;
        *.xz|*.txz)   xz    -dc -- "$1" ;;
        *)            cat      -- "$1" ;;
    esac
}

# archive_has_xattr_key <archive> <extended-regex matching the xattr name>
#
# Does the archive carry stored extended attributes matching the key?
#
# A plain "tar -tvf" NEVER shows extended attributes, so grepping its
# output is the classic way to write a check that can never pass. GNU
# tar needs --xattrs AND two -v flags before it prints attribute lines,
# which look like:   x:  31 security.selinux
#
# Some tar builds print nothing useful even then, so the fallback reads
# the pax headers out of the raw stream. GNU tar stores them as
# SCHILY.xattr.<name>; RHEL's older patched tar used RHT.<name>.
archive_has_xattr_key() {
    local archive=$1 key=$2
    [[ -f $archive ]] || { CHECK_WHY="archive $archive does not exist"; return 1; }

    if tar --xattrs -tvvf "$archive" 2>/dev/null | grep -Eq "x:.*${key}"; then
        CHECK_WHY="xattr matching '${key}' listed by tar --xattrs -tvv"
        return 0
    fi
    if archive_raw_stream "$archive" 2>/dev/null |
           grep -aEq "(SCHILY\.xattr\.|RHT\.)${key}"; then
        CHECK_WHY="pax header for '${key}' found in the archive stream"
        return 0
    fi
    CHECK_WHY="no stored xattr matching '${key}'"
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
# Was the archive actually extracted into this directory, with every
# member present? Checking only that a directory exists passes for an
# empty directory someone made by hand.
archive_matches_tree() {
    local archive=$1 root=$2 missing=0 total=0 member
    [[ -f $archive ]] || { CHECK_WHY="archive $archive does not exist"; return 1; }
    [[ -d $root ]]    || { CHECK_WHY="$root does not exist"; return 1; }

    while IFS= read -r member; do
        [[ -n $member ]] || continue
        total=$((total + 1))
        [[ -e $root/$member ]] || missing=$((missing + 1))
    done < <(tar -tf "$archive" 2>/dev/null)

    if (( total == 0 )); then
        CHECK_WHY="could not list the archive's contents"
        return 1
    fi
    if (( missing == 0 )); then
        CHECK_WHY="all $total archive members present under $root"
        return 0
    fi
    CHECK_WHY="$missing of $total archive members missing under $root"
    return 1
}

# file_sha <path>  -- sha256 of a file, empty string if unreadable
file_sha() { sha256sum -- "$1" 2>/dev/null | cut -d' ' -f1; }
