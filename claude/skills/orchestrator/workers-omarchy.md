# Claude workers on Omarchy: herdr tabs

Needs `HERDR_ENV=1`; the `herdr` skill has the full CLI. The plan's handle is the pane (`pane w3:p4`).

## Start

1. Tab: `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <worktree> --label <task> --env ORCH_WORKER=1 --no-focus`. The pane is `.result.root_pane.pane_id`. `ORCH_WORKER=1` keeps workers from ringing the captain's notification sound. Always pass `--workspace`: without it the tab lands in whatever workspace the captain has focused.
2. ```
   herdr agent start <task> --kind claude --pane <pane> -- --dangerously-skip-permissions --model sonnet   # or opus
   herdr agent prompt <task> "Your brief: <F>/briefs/<task>.md. Read it and follow it."
   ```
3. `herdr agent wait <pane> --until working --timeout 15000`. Without it, the next wait returns at once on the old state.
4. Run `herdr agent wait <pane>` as a background command (no timeout). When it exits, you wake up.

A reviewer starts the same way, in the worker's worktree.

## Later messages

`herdr agent prompt <task> "<message>"`, then steps 3 and 4 again.

## See what it's doing

`herdr agent read <pane> --source recent-unwrapped --lines 80`. The wait failed with `agent_not_running` or `agent_not_found`: the worker died; read the screen if the pane still exists.

## Close

Quit the worker, then `herdr tab close <tab>`.

## After a restart

`herdr agent get <pane>`: still working → start the background wait again; stopped → handle it as in "When a worker stops".
