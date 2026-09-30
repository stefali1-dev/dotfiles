# Claude workers on the Mac: subagents

No herdr here (the company's Falcon blocks it). Claude workers are Claude Code subagents. The plan's handle is the subagent's name (`agent <task>`).

## Start

Spawn a subagent with the Agent tool: name `<task>`, model `sonnet` or `opus`, prompt:

    Your brief: <F>/briefs/<task>.md. Read it and follow it. Work only in <worktree>: cd there first and pass it as the path to every tool.

It runs in the background; you're notified when it finishes. It shares your permission mode: run the orchestrator in a mode that lets workers edit and run tests, or their prompts land on the captain's screen.

A reviewer starts the same way, in the worker's worktree.

## Later messages

SendMessage to `<task>`; you're notified again when it stops.

## See what it's doing

Its last message, and the report file.

## Close

Nothing to close once it finished; stop a running one with TaskStop.

## After a restart

Subagents end with your session. For each `running` task: if its report is current, handle it as in "When a worker stops"; otherwise start a new subagent with the same brief, adding "Continue from the worktree's current state."
