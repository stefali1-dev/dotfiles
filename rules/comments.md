---
paths:
  - "**/*.{ts,tsx}"
---

# Comments

Short, blunt, only high-value. Default to none: write a comment only when a competent reader can't
get the fact from the code, and then as the shortest clause that carries it.

## Form

- `/** */` on any declaration, exported or not: functions, private methods, local types, object properties.
- `//` on statements inside a function or test body.
- In a package other apps import, a `/** */` on an export is what they see on hover.

## Write

- A cloud service's behaviour, limit or error.
- A constraint the service enforces that the code can't show.
- A cost that justified the design.
- A security property.
- A decision that looks like an oversight. "On purpose" and "deliberately" are facts; keep them.

## Don't write

1. A summary of the declaration below: `/** Creates a skill. */` on `createSkill`.
2. What the next line does.
3. An explanatory tail or a reassuring second half. One clause.
4. History: "used to", "was a 503 before the restructure". State what holds now.
5. Attestation, like "verified against the service". Quote the error string instead.
6. Emphasis or meta: "worth noting", "stated here so it survives a refactor".
7. `@param` / `@returns`.
8. Request or response examples next to a handler. The schema is the source.
9. A fact recorded elsewhere. Write it once, at the decision; `git grep` before adding a second copy.
10. Anything on DI wiring or re-export files.
11. Anything in a test, except a setup fact the reader would get wrong or the reason behind a bare
    negative assertion.

Banners only in a file over 200 lines with more than two sections: one line, `// ---------- Constants ----------`.
