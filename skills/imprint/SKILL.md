---
name: imprint
description: Verify a built UI against context/ui-rules.md and record its composition pattern in context/ui-patterns.md. Use after any screen or component is built.
---

UI consistency does not happen by accident. It happens because every screen is built with awareness of what already exists.

The design system solved half the problem: the atoms are fixed. Tokens, components, RTL, focus states — enforced by the package and its lint rules. What is NOT enforced is one level up: **how screens assemble those components.** An agent can import only from the design-system package and still build a Modal for one create-flow and a full page for the next, configure the same Table three different ways, or hand-roll an empty `<div>` where `EmptyState` exists. That is where drift lives now.

This skill guards that level. Run it after building any UI. It verifies the new screen against the system and the established patterns, then records the pattern so the next screen matches.

One command. Run it every time. That is the whole system.

---

## How to Invoke

After building any UI, run:

```
/fa:imprint
```

To target a specific file:

```
/fa:imprint [filepath]
```

To audit the existing product UI for pattern conflicts:

```
/fa:imprint audit
```

If no filepath is given, identify the screen or component files created or modified in this session and work from those. If it is unclear, ask.

---

## Step 1 — Verify Against the System

The rules are in `context/ui-rules.md`, already in context. Read the new UI code and check every rule there, in this order: imports (the design-system package, or a local build recorded in `context/ui-patterns.md`), values (no hard-coded tokens), language (translation layer, RTL and LTR), role fit (the right component per `context/ui-patterns.md`). A component the design system lacks is built locally with its variables and recorded in `context/ui-patterns.md`; a local build with no entry there is a finding. When existing patterns answer a question and the new screen deviates, that is a finding, not a preference.

Report findings before capturing anything:

```
## Imprint check — [screen/feature]

[PASS — follows the system and existing patterns]
[or]
Findings:
- [file:line] — [what deviates, and what the pattern says]
- Unrecorded local build: [component built locally with no ui-patterns entry]

Fix these first, capture after? Or capture as-is? (fix / capture)
```

Do not fix anything yourself. The developer decides.

## Step 2 — Capture the Pattern

Open `context/ui-patterns.md` (create it if missing). Determine which case this is:

**The screen follows an existing pattern** → add or update its one-line entry in that pattern's "Used by" list. Done.

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

**The screen conflicts with an existing pattern** → do not record the conflict as a second pattern. Flag it:

```
This screen does [X]; the [pattern name] pattern says [Y].
Either the screen should change, or the pattern has evolved.
Which is it? (fix screen / update pattern)
```

If the pattern evolved, update the entry — `context/` files are rewritten, not appended — and list the screens now out of date so they can be fixed as they are touched.

### Registry hygiene

- **One line per fact.** No stories, no history, no "we used to". How a pattern changed goes in the diary; a decision with reasoning goes in an ADR.
- **Reference is a path, never pasted code.** The real screen is the example; a snippet is a copy that rots.
- **No status.** Not "done", not "needs migration" — Jira holds that.
- **Patterns describe composition, not visuals.** If an entry starts naming colors or spacing values, it is reaching below its level — the design system owns that.

## Step 3 — Confirm

```
Imprinted [screen] → context/ui-patterns.md

- Verification: [PASS / N findings, developer chose …]
- Pattern: [followed "List screen" / added "Wizard flow" / updated "…"]
- Local builds recorded: [none / component → ui-patterns entry]
```

---

## Audit Mode — /fa:imprint audit

Run when product UI already exists and pattern consistency is uncertain, or before establishing `context/ui-patterns.md` for the first time.

1. **Scan** every screen in the product. Group them by what they do: lists, detail views, create/edit flows, dashboards, empty/error handling.
2. **Extract the dominant pattern per group** — the composition most screens already share — and every deviation from it: same job, different shape.
3. **Report** patterns and conflicts. For each conflict, recommend which shape should win, based on what the majority does and what the design system intends. Also list every local build with no entry in `context/ui-patterns.md`, and every raw element doing a component's job.
4. **Wait.** Do not write the registry, do not fix screens. Present, ask, and only after the developer confirms the baseline, write `context/ui-patterns.md` and produce the fix list of deviating screens.

---

## How context/ui-patterns.md Gets Used

The registry is not just a record. It is the consistency enforcer for every future session.

Before writing any UI, read `context/ui-patterns.md`. Building a list screen? Check the List screen pattern and its reference path, open that real screen, and match its shape. Building something with no pattern yet? Build it well — it becomes the pattern when you imprint it.

Capture without consumption is a write-only file. The loop is: read the patterns → build to match → imprint what's new.

---

## The Rule

Build a screen. Run `/fa:imprint`. Move on.

The design system makes components consistent. This skill makes **screens** consistent. A registry of ten patterns answers the question every future session starts with: "how do we build this kind of page here?"

Consistency is a habit, not a feature.