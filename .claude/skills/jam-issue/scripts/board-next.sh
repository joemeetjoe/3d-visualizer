#!/usr/bin/env bash
# List issues for a track that are still `todo`, with their blockers and whether every blocker is `done`.
# Usage: board-next.sh <A|B|C|D>
set -euo pipefail
TRACK=${1:?track letter A|B|C|D}
BOARD="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/BOARD.md"
status_of() { grep -E "^\| $1 \|" "$BOARD" | sed -E 's/.*\| *([a-z]+) *\|[[:space:]]*$/\1/'; }
grep -E "^\| ${TRACK}[0-9][a-z]? \|" "$BOARD" | while IFS='|' read -r _ id title target blocked status _; do
  id=$(echo "$id" | xargs); status=$(echo "$status" | xargs); blocked=$(echo "$blocked" | xargs)
  [ "$status" = "todo" ] || continue
  ready=y
  for b in $(echo "$blocked" | tr ',' ' ' | grep -oE '^[A-DX][0-9][a-z]?$|[A-DX][0-9][a-z]?' ); do
    s=$(status_of "$b" || true); [ "$s" = "done" ] || ready=n
  done
  printf "%-5s %-8s blocked-by: %-22s %s\n" "$id" "$([ $ready = y ] && echo READY || echo waiting)" "${blocked:--}" "$(echo "$title" | xargs)"
done
