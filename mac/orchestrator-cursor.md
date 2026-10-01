# Cursor workers on the Mac

A worker or reviewer can also be a Cursor agent (`cursor-agent`), when the captain names one. Default model `gpt-5.6-terra-medium`; check a name with `cursor-agent --list-models`. "Authentication required" there: ask the captain to run `! cursor-agent login`. Cursor doesn't use Claude limits: skip `agent-usage` for it. The plan's handle is `cursor <session_id>`.

## Start

A background Bash command with the sandbox off (Cursor needs the keychain and the network):

    cursor-agent -p --output-format json --trust --force --model <model> --workspace <worktree> "<prompt>" > <F>/reports/<task>.cursor.json

Prompt: the same line as a subagent's. Add to the brief's Rules:

- Don't start helper agents or subagents: search and read files yourself.
- Pipe long command output through `tail -30`.
- Don't stop for a status update: finish, or stop on a question or blocker.

The JSON's `session_id` is the handle. Its `usage.cacheReadTokens` is the cost: tell the captain when a run passes 10M.

## Later messages

The same command with `--resume <session_id>` and the message as the prompt. Only that task's session: a new task gets a new session, or its context (and cost) keeps growing.

At most one message back per worker or reviewer, and none when you can avoid it: every resume re-reads the whole session. Put everything in that one message (all findings, all questions). The brief's "done" names every check up front, integration tests included, so nothing is found later.

## See what it's doing

Nothing until it stops: `git -C <worktree> status` and the report file.

## Close

Nothing to close; stop a running one with TaskStop.

## After a restart

Cursor keeps its sessions: resume each `running` task by its session_id.
