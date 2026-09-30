---
name: zcode
description: "Delegate work to GLM (Z.ai) through the ZCode desktop app with the `zbridge` CLI: reviews, second opinions, plans, tasks. Use when the user asks to run, spawn or delegate work to zcode, ZCode or GLM."
---

# GLM through zbridge

`zbridge` drives the ZCode desktop app. Each task is a chat there. Output is JSON.

```bash
zbridge send "<prompt>"                  # new chat, returns at once → {"chat": "c4", "status": "running"}
zbridge wait --chat c4                   # → {"status": "done", "reply": "..."}
zbridge send --chat c4 "<follow-up>"     # same chat, keeps its context
zbridge stop --chat c4                   # then send again to redirect it
```

- Run `wait` as a background command and keep working; you're notified when it exits.
- `"status": "running"` from `wait` means its timeout (default 30 min) passed first: wait again.
- Use the chat id `send` returned. There is no "latest": another agent's chat could be newer.
- Chats run outside any repo: give absolute paths, and `git -C <repo> …` for git. They have full access: for a review, say "only read".
- New chats use GLM-5.3-Flash on the free bundle. For harder work: `--model glm-5.3` (paid plan). `agent-usage zcode` shows the plan's limits.
- A command fails: run `zbridge doctor`. If it says the control socket is off, run `zbridge doctor --restart` (relaunches the app; it refuses while a chat is active).
- `zbridge --help` for the rest.

## If you are a ZCode agent

`zbridge` drives the window you run in. `send` switches the visible chat; yours keeps running. Never `stop`, `click` or `type` in your own chat.
