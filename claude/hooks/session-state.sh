#!/bin/sh
# Runs herdr's SessionStart hook only inside herdr, where it does anything. On the work Mac, Falcon
# kills any process whose command line names herdr, so calling it directly raised an alert per session.
[ "${HERDR_ENV:-}" = 1 ] || exit 0
exec bash "$(dirname "$0")/herdr-agent-state.sh" "$@"
