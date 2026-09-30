# Brief templates

A brief is: Header, then the Task part for its kind, then Rules, then Report. Fill every `<...>`; drop lines that don't apply.

- Don't widen the ask. Extras you'd like become a follow-up note to the captain, not part of the brief.
- No plan file, no examples you invented: the worker should think for itself. Examples from the captain (a bug report, an expected output) go in word for word.

## Header (every brief)

```
# Brief: <task>

This session is run by an orchestrator agent. It works for the captain, the person who asked for this; every message you get here comes from the orchestrator.

## The captain's request, word for word
<the captain's words>

## The orchestrator's additions
<what the orchestrator adds: context, why it matters. The captain didn't write this part, so question it if it looks wrong.>
```

## Task: work

```
## Task
- Goal: <the change, and why>
- You're in the worktree <path>, on branch <task>.
- Start from: <files>. These are hints, not a fence.
- Done when: <check>
- Out of scope: <what not to touch>
```

## Task: research

```
## Task
- Question: <what to find out>
- You're in a scratch worktree <path>: run and try anything, nothing is kept.
- Start from: <files>. These are hints, not a fence.
- Done when: the report answers the question.
- Don't fix anything. If the fix is obvious, describe it in the report.
```

## Task: review

```
## Task
Review the change on branch <task> in <path>: `git -C <path> diff <base>...<task>`. You didn't write it.
<Or, for a plan: review <plan path>.>
Also read <~/agent-docs/<repo>/work/<feature>/decisions.md>. You may question those decisions too.

Look for: bugs (pick a concrete input and trace it), inconsistencies, AI slop, duplicated or useless code, anything that isn't simple and easy to read. Only real findings: skip style and naming taste.
Fix nothing: don't edit any file except your report.

List each finding in the report:
- must-fix | should-fix | minor · `file:line` · one line of why
```

## Rules (every brief; reviewers skip the ones about committing)

```
## Rules
- If you think the goal or approach is wrong, say so with your reasons before you start: write the report with Status: needs-decision and stop.
- Bugs: show the bug happening (a failing test or a command) before fixing it.
- Run only the tests for your change, plus fast checks (lint, types). Not the full suite.
- Commit on your branch. Don't merge, push or rebase unless the orchestrator asks.
- Never create or remove worktrees or switch branches. If `git -C <path> branch --show-current` isn't <task>, stop and report.
- Stuck on the same obstacle twice: stop and report. A question only the captain can answer: stop and ask in the report.
- The task turns out much bigger than this brief: stop and report before going on.
```

## Report (every brief)

```
## Report
Whenever you stop (done, a question, stuck), overwrite <~/agent-docs/<repo>/work/<feature>/reports/<task>.md>:

    Status: done|needs-decision|blocked|failed: <one line>
    <research: the answer first, in a sentence or two>
    ## Changes: what and where
    ## Checks: each command and its result, one line each
    ## Skipped or unsure
    ## Questions: numbered, each with your suggested answer

Then reply "report written" and stop. Messages from the orchestrator may follow; after each, overwrite the report again when you stop.
```
