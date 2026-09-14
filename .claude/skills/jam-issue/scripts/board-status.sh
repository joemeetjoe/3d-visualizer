#!/usr/bin/env bash
# Update an issue's Status cell in docs/BOARD.md.
# Usage: board-status.sh <ISSUE_ID> <todo|doing|done|cut|stretch>
set -euo pipefail
ID=${1:?issue id}; STATUS=${2:?status}
case "$STATUS" in todo|doing|done|cut|stretch) ;; *) echo "bad status: $STATUS" >&2; exit 1;; esac
BOARD="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/BOARD.md"
if ! grep -qE "^\| $ID \|" "$BOARD"; then echo "no row for $ID in $BOARD" >&2; exit 1; fi
# last cell of the row is Status
sed -i.bak -E "s/^(\| $ID \|.*\| )[a-z]+( \|)[[:space:]]*$/\1$STATUS\2/" "$BOARD" && rm -f "$BOARD.bak"
grep -E "^\| $ID \|" "$BOARD"
