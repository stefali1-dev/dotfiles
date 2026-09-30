#!/bin/bash
# Plays herdr's done/request sound for agents that talk to you: agent-sound.sh done|request.
# herdr's own sound is off in omarchy/herdr/config.toml because it also rang for every orchestrator worker.
# Called by Claude Code's hooks.
[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0
# Orchestrator workers report to the orchestrator, not to you.
[ "${ORCH_WORKER:-}" = 1 ] && exit 0
# Where herdr still rings by itself (Omarchy's default config), don't ring twice.
awk '/^\[/ { in_sound = ($0 == "[ui.sound]") } in_sound && /^enabled *= *false/ { off = 1 } END { exit !off }' \
  "$HOME/.config/herdr/config.toml" || exit 0

herdr=${HERDR_BIN_PATH:-herdr}
# Like herdr's own sound: quiet for the pane you're looking at.
[ "$("$herdr" pane get "$HERDR_PANE_ID" | jq -r .result.pane.focused)" = true ] && exit 0

tab=$("$herdr" tab get "$HERDR_TAB_ID" | jq -r '.result.tab.label // "agent"')
body=$([ "$1" = request ] && echo "needs you" || echo "done")
"$herdr" notification show "$tab" --body "$body" --sound "$1" >/dev/null
