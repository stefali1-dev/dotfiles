# ~/.claude

Personal Claude Code setup, versioned in place. `.gitignore` allows only the hand-written files.

| Path | What |
|---|---|
| `CLAUDE.md` | How I work: loaded in every project |
| `settings.json` | Hooks, `@` file suggestions, worktree base, allowed dirs, permissions |
| `hooks/agent-docs.sh` | SessionStart: links `~/agent-docs/<repo>` into the checkout and lists open work |
| `file-suggestion.sh` | `@` picker: tracked files plus ignored `agent-docs/`, `CLAUDE.local.md`, `.git/info/exclude` paths |
| `skills/` | `review-comments`, `decision-questions`, `caveman` |
| `agents/reviewer.md` | Fresh-context reviewer used by `review-comments` |
| `commands/q.md` | `/q`: queue a follow-up |
| `git-ignore-global` | Global git ignore; `~/.config/git/ignore` is a symlink to it |

New machine: clone into `~/.claude`, then `ln -s ~/.claude/git-ignore-global ~/.config/git/ignore`.
`settings.json` has absolute paths under `/Users/stefan.leustean/`; adjust them for another user.
