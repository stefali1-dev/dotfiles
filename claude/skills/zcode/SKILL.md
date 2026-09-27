---
name: zcode
description: "Spawn and drive ZCode (Z.ai's GLM coding agent TUI, the `zcode` command) in Herdr panes as a helper agent. Use when the user asks to run, spawn or delegate work to zcode, ZCode or GLM. Load the herdr skill too; requires HERDR_ENV=1."
---

# ZCode in Herdr panes

`zcode` is the ZCode TUI (setup: `~/dotfiles/zcode/README.md`). Its hooks report its state to herdr (`omarchy/zcode/herdr-agent-state.sh`), so `herdr agent wait|get|read` work on it: idle, working, blocked (approval dialog), done. `herdr agent prompt` and `agent start` don't (herdr doesn't know it as an agent kind): type into it with `herdr pane ...`. Follow the herdr skill's rules on layout and focus.

## Usage left

`agent-usage zcode --json`: the plan's 5-hour and weekly limits (`usedPercent`, `resetsAt`). Check it before handing zcode a big task.

## Start, prompt, wait

```bash
pane=$(herdr pane split --current --direction right --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr pane run "$pane" zcode
herdr pane wait-output "$pane" --match "Type a prompt" --timeout 30000

herdr pane send-text "$pane" "<task>"
herdr pane send-keys "$pane" enter
herdr agent wait "$pane" --until working --timeout 10000
herdr agent wait "$pane" --timeout 600000   # returns done, idle or blocked
herdr agent read "$pane" --source visible
```

- Send the prompt with `send-text`, then Enter separately. `pane run` submits but leaves the text in the prompt box, and the next prompt gets appended to it.
- Wait for `working` first: right after Enter the state is still the previous `done`, so a plain `agent wait` returns at once.
- `blocked` means an approval dialog (`Approval required: <Tool>`).
- It starts in Build mode: edits and non-read-only commands ask for approval. Read-only commands run without asking.

## Approvals

The dialog (`Approval required: <Tool>`) starts on Deny. Options: Allow once, Always allow in this project, Deny.

- Allow once: `up`, `up`, `enter`, each its own `send-keys` call with `sleep 0.5` between. Sent faster, the dialog acts on a stale selection: Enter gets lost, or it denies.
- Deny: `esc`.
- Approve only what the user's task covers. When unsure, show the user the dialog text and ask.

## Rules

- Stop a running turn with `esc`. zcode fires no hook on an interrupt, so the state stays `working`: reset it with `HERDR_PANE_ID="$pane" zcode-herdr-agent-state start`. Never send `ctrl+c` except to quit: one Ctrl+C quits at once, even mid-task.
- Clear the prompt box with `ctrl+u`.
- Model: `/model` lists them (a picker: Enter selects the highlighted one, Esc closes it); `/model account:zai-individual-coding-plan/GLM-5.3` switches. Effort: `/effort list`, `/effort low|high|max`. Effort is per model: switching model resets it. Send these like a prompt; they don't change the herdr state. After `/model`, the picker stays open and the command text stays in the box: send `esc`, then `ctrl+u`, before the next prompt.
- Only the visible screen is readable (alternate screen, no scrollback). For long results, ask zcode to write them to a file and read the file.
- Keep the pane at least 50 columns; below about 45 the right edge is cut off.
- `zcode -c` resumes the folder's last session but shows a blank transcript; wait for `Type a prompt`, not the account footer.
- Done: `herdr pane send-keys "$pane" ctrl+c`, then `herdr pane close "$pane"` if you created it. Closing the pane also ends zcode cleanly.
- One-shot questions need no pane: `zcode -p "..." --mode plan` prints only the answer on stdout. Always pass `--mode`: headless defaults to yolo.
- Never run `zcode logout` or `/logout`: it signs out the desktop app too.
