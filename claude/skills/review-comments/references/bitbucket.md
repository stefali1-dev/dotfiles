# Bitbucket PR reviews

Use `bkt`, not `gh`. It needs the keychain, so run it outside the sandbox.

## Fetch

`bkt pr view <PR>` for context; `bkt pr comments <PR> --json` for the threads.

Keep a thread only when:
- it is unresolved and so is its root comment (follow `parent.id`), and
- its last comment is not the PR author's; if it is, it's waiting on the reviewer.

Say in the file header how many threads were dropped as waiting on the reviewer.

Per thread:
- Heading `### <n> · <inline.path>:<inline.to>`; comments with no path go under `## General`.
- `<!-- thread: <root comment id> -->` under the heading. Replying and posting need it.
- Code excerpt from the PR's source branch: `git show <branch>:<path>`, ±3 lines, numbered, → on the commented line.
- The thread quoted as written, inside the `<details>`: `> **<name>** · <local time>`, then the body. Only normalise what the UI renders: `@{id}` → `@name`, drop backslash escapes and the trailing `‌`.
- For triage, the Finding line is the reviewer's claim in one line, in your words.

## Replies (address pass)

Under each thread:

```
Reply:
"
<text>
"
```

It goes out under the author's name. Write it like them:
- Outcome first, lowercase: `done.` A partial fix says partial.
- One change per line, past tense, no subject: "made lint depend on it".
- Name the file or identifier. Paste the changed code in a fence instead of describing it.
- Extra changes start with "also".
- Disagreeing: normal case, the blocking fact first, then what was done instead. Bring the number you measured.
- No em or en dashes. No thanks, no "let me know", no restating the comment.

```
Reply:
"
done.
removed the AWSLambdaBasicExecutionRole policy and added this statement:
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

also added `dead_letter_config` to the target in `eventbridge.tf`
"
```

```
Reply:
"
`prevent_destroy` cannot take a variable, and a literal would also block `task destroy ENVIRONMENT=dev`, which dev relies on.

So `tf-guard` now refuses a destroy outside dev unless `CONFIRM_DESTROY=<env>` names it back.
"
```

## `/review-comments post <PR#>`

Only threads with `- [x] Addressed`. None ticked: stop and say so.

One thread at a time, checking each call before the next:

`bkt pr comment <PR> --text "<reply>" --parent <thread id> --pending`

Both flags, always: without `--parent` it's a new top-level comment, and without `--pending` the reviewer sees it at once. Post the text as written; if one reads badly, stop and name it.

End with a table: #, thread id, posted or skipped and why. Never submit the review or resolve a thread; the drafts wait in the Bitbucket UI.
