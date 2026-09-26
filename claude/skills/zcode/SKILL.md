---
name: zcode
description: "Spawn and drive ZCode (Z.ai's GLM coding agent TUI, the `zcode` command) in Herdr panes as a helper agent. Use when the user asks to run, spawn or delegate work to zcode, ZCode or GLM. Load the herdr skill too; requires HERDR_ENV=1."
---

# ZCode in Herdr panes

`zcode` is the ZCode TUI (setup: `~/dotfiles/omarchy/zcode/README.md`). Herdr doesn't know it as an agent kind, so `herdr agent ...` commands don't work on it: drive it with `herdr pane ...` and read the screen. Follow the herdr skill's rules on layout and focus.

## Start, prompt, wait

```bash
pane=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$pane" zcode
herdr pane wait-output "$pane" --match "Type a prompt" --timeout 30000

herdr pane send-text "$pane" "<task>"
herdr pane send-keys "$pane" enter
sleep 2
while herdr pane read "$pane" --source visible | grep -q 'esc to interrupt'; do sleep 2; done
herdr pane read "$pane" --source visible
```

- The turn is over when `esc to interrupt` is gone. It is also gone while an approval dialog waits, so check for `Approval required` next.
- The whole prompt can go in one `send-text`; send Enter separately.
- It starts in Build mode: edits and non-read-only commands ask for approval. Read-only commands run without asking.

## Approvals

The dialog (`Approval required: <Tool>`) starts on Deny. Options: Allow once, Always allow in this project, Deny.

- Allow once: `up`, `up`, `enter`, each its own `send-keys` call with `sleep 0.5` between. Sent faster, the dialog acts on a stale selection: Enter gets lost, or it denies.
- Deny: `esc`.
- Approve only what the user's task covers. When unsure, show the user the dialog text and ask.

## Rules

- Stop a running turn with `esc`. Never send `ctrl+c` except to quit: one Ctrl+C quits at once, even mid-task.
- Only the visible screen is readable (alternate screen, no scrollback). For long results, ask zcode to write them to a file and read the file.
- Keep the pane at least 50 columns; below about 45 the right edge is cut off.
- `zcode -c` resumes the folder's last session but shows a blank transcript; wait for `Type a prompt`, not the account footer.
- Done: `herdr pane send-keys "$pane" ctrl+c`, then `herdr pane close "$pane"` if you created it. Closing the pane also ends zcode cleanly.
- One-shot questions need no pane: `zcode -p "..." --mode plan` prints only the answer on stdout. Always pass `--mode`: headless defaults to yolo.
- Never run `zcode logout` or `/logout`: it signs out the desktop app too.
