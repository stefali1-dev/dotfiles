---
name: decision-questions
description: >-
  How to present open decisions that need the user's answer. Use when a plan, design or
  investigation surfaces choices the user must make, and whenever you would otherwise write a
  long prose section weighing options.
---

# Asking for decisions

Never use the interactive question tool for these. Plain markdown in the response.

## Format

One numbered list, most consequential first. Per decision:

1. **A heading naming the choice**, not the topic. "Where traces are stored", not "Storage".
2. A small table: one row per option, one column for the trade-off. Bold the recommended row.
3. One short paragraph: the recommendation and **why** — the reason that actually decides it, not a
   summary of the table.

Then a closing block listing which decisions are settled and which are still open.

## Rules

- **Every option is real.** No straw men to make the recommendation look good.
- **State the cost of your own recommendation.** A breaking env change, a placeholder field, an
  unmet requirement — say it in the recommendation paragraph.
- **Recommend on every one.** "It depends" is not an answer; if it genuinely does, say what it
  depends on and which way you would go absent that.
- **Separate the calls that are not yours.** Data retention, privacy, spend, scope — name them and
  hand them over explicitly rather than folding them in with the technical ones.
- **One screen per decision.** If it needs more, the decision is really two.

## When the user answers

Check each answer against the others. An answer often invalidates a decision already agreed —
say so immediately and reopen it, do not quietly proceed with the contradiction.

Once answered, record the decisions in the plan you're working from, if there is one.

If an answer is "I don't understand the question", drop the format and explain plainly with a
concrete example, then restate the options.
