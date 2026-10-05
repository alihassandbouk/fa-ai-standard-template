---
name: imprint
description: Verify a built UI against context/ui-rules.md and record its composition pattern in context/ui-patterns.md. Use after any screen or component is built.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# imprint

The design system fixes the atoms: tokens, components, RTL, focus states,
enforced by the package and its lint rules. This skill guards the level
above, how screens assemble those components, and records each screen's
composition in `context/ui-patterns.md` so the next screen matches.

Argument: a file path → that file. `audit` → read `references/audit.md`.
None → the screen or component files created or modified in this session;
unclear → ask.

## Step 1 — Verify against the system

The rules are in `context/ui-rules.md`, already in context. Read the new UI
code and check every rule there, in this order: imports (the design-system
package, or a local build recorded in `context/ui-patterns.md`), values (no
hard-coded tokens), language (translation layer, RTL and LTR), role fit (the
right component per `context/ui-patterns.md`). A component the design system
lacks is built locally with its variables and recorded in
`context/ui-patterns.md`; a local build with no entry there is a finding.
When existing patterns answer a question and the new screen deviates, that
is a finding, not a preference.

Report findings before capturing anything; the developer decides what to fix:

```
## Imprint check — [screen/feature]

[PASS — follows the system and existing patterns]
[or]
Findings:
- [file:line] — [what deviates, and what the pattern says]
- Unrecorded local build: [component built locally with no ui-patterns entry]

Fix these first, capture after? Or capture as-is? (fix / capture)
```

## Step 2 — Capture the pattern

Open `context/ui-patterns.md` (create it if missing). Determine which case
this is:

**The screen follows an existing pattern** → add or update its one-line
entry in that pattern's "Used by" list. Done.

**The screen introduces a new pattern** → add an entry:

```markdown
### [Pattern name — e.g. List screen]

Use when: [one line — the situation this pattern serves]
Shape: [the design-system components composed, in order —
  Section > Container + SearchBox + Table + Pagination + EmptyState]
Conventions: [one line per rule — Typography variant for the page title,
  primary action placement, which tone for which outcome]
Reference: [path to the real screen — the canonical example]
Used by: [paths]
```

**The screen conflicts with an existing pattern** → flag it, instead of
recording a second pattern:

```
This screen does [X]; the [pattern name] pattern says [Y].
Either the screen should change, or the pattern has evolved.
Which is it? (fix screen / update pattern)
```

If the pattern evolved, update the entry (`context/` files are rewritten to
the present) and list the screens now out of date so they can be fixed as
they are touched.

### Registry hygiene

- **One line per fact.** How a pattern changed goes in the diary; a decision
  with reasoning goes in an ADR.
- **Reference is a path.** The real screen is the example; a pasted snippet
  is a copy that rots.
- **Status belongs to Jira**, so an entry carries none.
- **Patterns describe composition.** Colours and spacing values belong to
  the design system, one level below.

## Step 3 — Confirm

```
Imprinted [screen] → context/ui-patterns.md

- Verification: [PASS / N findings, developer chose …]
- Pattern: [followed "List screen" / added "Wizard flow" / updated "…"]
- Local builds recorded: [none / component → ui-patterns entry]
```
