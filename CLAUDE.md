# How I work

## Simple
- Simple and easy to read: no more code, files or concepts than the task needs.
- Typical misses:
  - guards for states that can't happen
  - the same rule written twice, which drifts
  - the reverse: a shared helper or factory that makes each caller harder to read
  - comments that restate the code

## Effort
- Scale effort to the task: a quick question gets a quick answer.
- Working through a plan or a list (review comments, findings): one todo per item; finish all, including the small ones.

## Ask before
- adding an abstraction, file or folder the existing code has no counterpart for
- adding a dependency
- the task turning out much bigger than asked
- going against the plan or a recorded decision
- writing to cloud resources outside this project's stack
- weakening or deleting a test to make it pass

Ask in a sentence or two, with a recommendation. Everything else the task needs is yours to decide, including changes to shared types or contracts that touch several places. Name those decisions in your report.

- When making technical decisions, do not give much weight to development cost.

## Done means checked
- Check that it runs, not only that it compiles: tests, then the real thing where the project allows it.
- Pick the checks that fit the change; say what you checked and what you skipped.

## Git
- Commit only when asked. The request covers the changes made so far; later changes wait for a new one.
- Stage files by name, only the ones this task changed.
- When writing commit messages, NEVER auto-add your agent name as co-author.

## Plans and notes
- Plans live in `~/agent-docs/<repo>/work/<feature>/plan.md`, where `<repo>` is the main checkout's folder name, also inside a worktree.
- Write there by that full path. The `agent-docs` link in a checkout is for reading.
- A plan starts with a `**Status:**` line (`active`, `done` or `dropped`); keep it current.
- After a compaction, re-read the plan you are working from.
- When a plan is done, move its lasting decisions to `~/agent-docs/<repo>/decisions.md` and open follow-ups to `todos.md` beside it. Deleting the work folder is my call.

## Parallel work
- Before a change across many files, check for other sessions in this checkout (ListAgents). If one is editing, suggest a worktree. Reviews and research share the checkout.
- A worktree isolates files only. Deployed stacks, fixed ports, local containers and shared temp dirs still collide.
- In a new worktree, install dependencies before running anything.
