#!/bin/bash
# Reports zcode's state to herdr, so it shows in the Agents list and `herdr agent wait` works.
# Called by zcode's hooks (event JSON on stdin) and by the zcode launcher (`start` / `exit`).
[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0

herdr=${HERDR_BIN_PATH:-herdr}
id=(--source custom:zcode --agent zcode --seq "$(date +%s%N)")

case "${1:-$(jq -r .hook_event_name)}" in
  start | SessionStart) state=idle ;;
  Stop) state=idle sound=done ;;
  PermissionRequest) state=blocked sound=request ;;
  exit) exec "$herdr" pane release-agent "$HERDR_PANE_ID" "${id[@]}" >/dev/null ;;
  *) state=working ;;
esac
"$herdr" pane report-agent "$HERDR_PANE_ID" "${id[@]}" --state "$state" >/dev/null
[ "${sound:-}" ] && "$HOME/.claude/hooks/agent-sound.sh" "$sound"
exit 0
