# Save

## Where it goes

Append an entry to `diary/repo/YYYY-MM-DD.<author>.md`, where `<author>` is
`git config user.name` lower-cased with runs of non-alphanumerics replaced by
`-`; create the file and folder if needed. One file per day per author, so
branches never conflict on the diary; several sessions on one day append
under their own time heading. The file is append-only: an existing entry
stays as written.

## What to capture

Only what a colleague, equally skilled and knowing nothing about today, needs
to continue without losing anything. Terse and factual.

- **What changed**: specific files, features, migrations. "Created
  `consumers/payment_completed.py`, retry queue wired, DLQ tested", not
  "worked on messaging".
- **Decisions made**: choices future work depends on, with the reasoning.
  These are the promotion candidates below.
- **Problems solved**: the symptom, the actual cause, the fix. Symptom
  wording matters: it is what gets searched for later.
- **Open threads**: anything unresolved, unverified, or blocked.
- **Next session starts with**: the very first action, specific enough to
  begin immediately.

Leave out: implementation detail visible in the code, anything a context
file or ADR already states, how it was built as opposed to what, status that
belongs in Jira, and credential-like values.

## Entry format

```markdown
## HH:MM — [short session title]

Tickets: RL-45

### What changed
- ...

### Decisions
- ... (why, and what was rejected)

### Problems solved
- Symptom → cause → fix

### Open threads
- ...

### Next session starts with
- ...
```

Omit empty sections. Half a screen is usually right.

## Promotion check, before writing

Review the draft entry and ask, for each item:

1. **ADR-worthy** (`docs/adr/README.md`)? → Offer to draft the ADR now.
2. **A convention the agent should follow every session?** → It belongs in a
   context file or `CLAUDE.md`.
3. **A term defined or redefined?** → `context/glossary.md`.
4. **Retro: would a lint rule, a CI check, a test, or one line of context
   have prevented something that happened this session?** → Propose that
   fix. Mechanical rules go to tooling; navigation facts go to the nearest
   `AGENTS.md`.

Tell the developer what you found:

```
This entry contains [N] promotion candidates:
- "Chose per-invoice rate over per-container" → ADR
- "Always decrement both weight and pieces on sale" → context/code-standards.md

Draft them now? (yes / pick / skip)
```

The diary keeps the narrative either way; promotion copies the durable fact
to its proper home. A diary you depend on for everyday work is a sign
something failed to get promoted.

## After writing

Run a final pass for secrets, then confirm:

```
Session saved to diary/repo/YYYY-MM-DD.<author>.md.
[Promoted: ADR-007 drafted / nothing promoted]

Next session: run /fa:remember restore to pick up from here.
```
