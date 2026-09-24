#!/bin/bash
# SessionStart: link ~/agent-docs/<repo> into the checkout, then list its open work.
# <repo> is the main checkout's folder name, so every worktree gets the same folder.
# A repo opts in by having ~/agent-docs/<repo>; otherwise this prints nothing.

STALE_DAYS=14

cwd=$(jq -r '.cwd // empty' 2>/dev/null)
cd "${cwd:-$PWD}" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
repo=$(basename "$(dirname "$common")")
docs="$HOME/agent-docs/$repo"
[ -d "$docs" ] || exit 0

[ -e "$root/agent-docs" ] || [ -L "$root/agent-docs" ] || ln -s "$docs" "$root/agent-docs"

now=$(date +%s)
lines=()
for dir in "$docs"/work/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  status=$(grep -m1 '^\*\*Status:\*\*' "$dir/plan.md" 2>/dev/null |
    sed 's/^\*\*Status:\*\* *//; s/\. .*//; s/;.*//' | cut -c1-80)
  newest=$(find "$dir" -type f -exec stat -f %m {} + 2>/dev/null | sort -n | tail -1)
  days=$(( (now - ${newest:-$now}) / 86400 ))
  note=""
  case "$status" in
    done* | dropped* | rejected*) note=" [finished: keep what matters, then delete]" ;;
    *) [ "$days" -ge "$STALE_DAYS" ] && note=" [untouched ${days}d]" ;;
  esac
  lines+=("- $name: ${status:-no Status line in plan.md}$note")
done

[ ${#lines[@]} -eq 0 ] && exit 0
echo "Open work in ${docs/#$HOME/~}/work:"
printf '%s\n' "${lines[@]}"
exit 0
