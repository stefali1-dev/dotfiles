---
name: review-comments
description: Review code with a fresh reviewer subagent, or take in review comments from a Bitbucket PR or another agent; triage them, then address them. Invoked with /review-comments.
disable-model-invocation: true
argument-hint: "[range] | <PR#> | <review file> | address | post <PR#>"
---

# Review comments

One file per review round. Each command does one pass and stops; the user reads the file between passes.

When spawning `reviewer`, the prompt is the listed fields only; its own file says how to review or audit.

## The file

`~/agent-docs/<repo>/work/<feature>/review-<n>.md`, next to the plan you are working from; `<n>` is the next number there. No plan: ask which feature folder.

```
# Review <n>: <feature>
Source: reviewer | Bitbucket PR #<N> | <file>   ·   Range: <base>..<head> + uncommitted   ·   Plan: <path>

### <n> · <path>:<line>
- [ ] Addressed
**Severity:** …
**Finding:** …
**Remedy:** …
<details><summary>code</summary> excerpt </details>
```

Triage and address add lines under each finding; they never rewrite the finding or the excerpt.

## `/review-comments [range]`: review

- Range: default is everything not on the default branch, plus uncommitted and untracked files.
- Spawn the `reviewer` subagent (not a fork) with: task "review", the range, the plan path, the paths of earlier `review-*.md` in the folder.
- Write its findings into a new file, then triage.

## `/review-comments <PR#>` or `<file>`: someone else's review

- PR number: follow `references/bitbucket.md` to build the file.
- A file or pasted text from another agent: one block per finding in the format above. Keep every finding; add the code excerpt yourself; quote only what you received.
- Then triage.

## Triage

One todo per finding, in file order. Judge against the current code, not the excerpt.

- Every finding is a claim. Agent reviews are often wrong; humans misread code too.
- Read the code it points at and what calls it. Verify claims about services and libraries: docs, or read-only CLI calls with the project's credentials. Ask before anything that writes or costs money.
- Before rejecting, state the reviewer's strongest version of the point, and answer that.

Verdicts:
- `address`: right, and worth changing.
- `reject`: wrong, already handled, or against a recorded decision. Say which.
- `ask`: partly right; right problem, wrong fix; or the fix extends the change or goes against the plan. The user decides.
- Add `(unsure)` when the evidence doesn't settle it.

Under each finding, one line each:
```
**Status:** …
**Checked:** what you opened: file:lines, doc URL, command
**Fix:** what to change and where        (address, ask)
**Reason:** why not, against the strong version   (reject)
```

End with a table: #, location, status. Change no code.

## `/review-comments address`

Do `address` findings, and `ask` findings the user answered. Re-read each against the current code first: the Fix line is a proposal.

- Fix only what the finding needs.
- If the code at fault isn't needed by the plan, remove it instead of hardening it.
- Apply all fixes, then one focused check on what you touched. Then run the project's checks once; report failures honestly, including ones you didn't cause.
- No comments explaining a fix.

Under each finding add `**Done:**` with what actually changed, or why nothing did. Tick `- [x] Addressed` once nothing more is owed. Human reviews also get a reply: `references/bitbucket.md`.

Replace the triage table with: #, location, status, what happened. Then list the files touched.

Then audit, without being asked: spawn the `reviewer` subagent (not a fork) with task "audit", the review file and the files touched. Append its report as written, under `## Audit` at the end of the file, and summarise it for the user in a few lines. Act on it only when the user says so.

## Never

Commit, push, resolve threads, or post anything. Posting is `/review-comments post`, in `references/bitbucket.md`.
