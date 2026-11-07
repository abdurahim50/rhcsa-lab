#!/bin/bash
# =====================================================================
# check-links.sh  --  verify every relative Markdown link resolves.
#
# Only local targets. External URLs are not fetched: a CI job that
# depends on someone else's website is a CI job that fails on their
# bad day, not yours.
#
#   ./tests/check-links.sh
# =====================================================================
set -u
cd -- "${BASH_SOURCE[0]%/*}/.." || exit 2
exec python3 -I - <<'PY'
import pathlib, re, sys, urllib.parse

LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
root = pathlib.Path(".").resolve()
broken, checked = [], 0

for md in sorted(root.rglob("*.md")):
    if ".git" in md.parts:
        continue
    for raw in LINK.findall(md.read_text(encoding="utf-8")):
        target = raw.strip().split(" ", 1)[0]
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        path = urllib.parse.unquote(target.split("#", 1)[0])
        if not path:
            continue
        checked += 1
        if not (md.parent / path).resolve().exists():
            broken.append(f"{md.relative_to(root)} -> {target}")

print(f"checked {checked} relative link(s) across the repository")
if broken:
    print("\nbroken:")
    for b in broken:
        print(f"  {b}")
    sys.exit(1)
print("all resolve")
PY
