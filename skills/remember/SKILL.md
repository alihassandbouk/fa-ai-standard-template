---
name: remember
description: Save what matters at the end of a session so the next session picks up exactly where you left off, or restore context at the start of a new session. Saves to the repo diary (diary/repo/YYYY-MM-DD.<author>.md, committed) — append-only session history with the handoff built in. Personal or cross-repo learnings go to the global diary instead (see the diary skill).
---

AI has no memory between sessions. Every new session starts blank. This skill fixes that.

Run it at the end of a session to save. Run it at the start of a new session to restore.

## Security Boundary

This skill must never persist secrets. If any sensitive value appears in the conversation or context, do not copy it into a diary entry.

Sensitive data includes (non-exhaustive): API keys, access tokens, refresh tokens, session tokens, passwords, passphrases, one-time codes, private keys, certificates, cookies, auth headers, connection strings, webhook secrets, or any credential-like value.

If a detail is useful but sensitive, refer to it by name (`GHCR_PAT`, `DATABASE_URL`) or store a redacted placeholder (`[REDACTED_API_KEY]`). If unsure whether something is sensitive, treat it as sensitive.

## How to Invoke

**To save at end of session:** `/fa:remember save`
**To restore at start of new session:** `/fa:remember restore`

If the developer runs `/fa:remember` without specifying — ask which one they need.

---

## Save Mode

### Where it goes

Append an entry to `diary/repo/YYYY-MM-DD.<author>.md`, where `<author>` is `git config user.name` lower-cased with runs of non-alphanumerics replaced by `-` (create the file and folder if needed). One file per day per author, so branches never conflict on the diary; multiple sessions on the same day append under their own time heading. **Never edit or delete an existing entry** — the diary is append-only.

This file is committed to git. Write for a teammate: terse, factual, no stream-of-consciousness.

**Routing rule:** this entry is for teammates and stays about the project. The developer's **personal diary** (`diary log ...`, see the diary skill) gets its own session entry, written for someone with no access to this repo; decisions and non-obvious fixes go there as they happen, not at the end.

### What to capture

Only what a colleague — equally skilled, knowing nothing about today — would need to continue without losing anything. Not a transcript.

- **What changed** — specific files, features, migrations. "Created `consumers/payment_completed.py`, retry queue wired, DLQ tested" — not "worked on messaging".
- **Decisions made** — choices future work depends on, with the reasoning. These are ADR candidates (see promotion check below).
- **Problems solved** — the symptom, the actual cause, the fix. Symptom wording matters: it is what gets searched for later.
- **Open threads** — anything unresolved, unverified, or blocked.
- **Next session starts with** — the very first action, specific enough to begin immediately.

### What not to capture

- Implementation details visible in the code
- Anything already documented in context files, or ADRs
- The process of how something was built — only what was built and what was decided
- Status that belongs in Jira (ticket states, sprint progress)
- Secrets or credential-like values

### Entry format

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

### Promotion check — run this before writing

Review the draft entry and ask, for each item:

1. **Is this a decision that is hard to reverse, surprising without context, and the result of a real trade-off?** → It needs an ADR. Offer to draft one in `docs/adr/` now (numbered, never edited, superseded only).
2. **Is this a convention the agent should follow every session?** → It belongs in a context file or `CLAUDE.md`.
3. **Did a term get defined or redefined?** → `context/glossary.md`.
4. **Retro: did anything happen this session that a lint rule, a CI check, a test, or one line of context would have prevented?** → Propose that fix. Mechanical rules go to tooling, never to `CLAUDE.md`; navigation facts go to the nearest `AGENTS.md`.

Tell the developer what you found:

```
This entry contains [N] promotion candidates:
- "Chose per-invoice rate over per-container" → ADR
- "Always decrement both weight and pieces on sale" → context/code-standards.md

Draft them now? (yes / pick / skip)
```

The diary keeps the narrative either way; promotion copies the durable fact to its proper home. **A diary you depend on for everyday work is a sign something failed to get promoted.**

### After writing

Run a final pass for secrets, then confirm:

```
Session saved to diary/repo/YYYY-MM-DD.<author>.md.
[Promoted: ADR-007 drafted / nothing promoted]

Next session: run /fa:remember restore to pick up from here.
```

---

## Restore Mode

### Step 1 — Find the latest entry

Find the newest date among the files in `diary/repo/` and read the **last three entries of every file with that date** (one file per author). The SessionStart hook already printed the last entry of each; read the files only for what it did not show. Do not read the whole diary — it is an archive, not a context file. If `diary/repo/` is missing or empty:

```
No diary entries found in this repo.
Either this is the first session, or nothing was saved.
To save at the end of a session, run /fa:remember save.
```

### Step 2 — Read the essentials

The latest entries, plus `CLAUDE.md` if not already loaded. Nothing else. If the developer's question concerns older work ("why did we change the retry policy"), **search** the repo diary (grep) or the global diary (`diary search ...`) for that topic and read the matching entries only.

### Step 3 — Confirm what was restored

Do not start building. Summarise so the developer can verify:

```
Restored from diary/repo/YYYY-MM-DD.<author>.md (HH:MM entry):

**Last session:** [what changed]
**Open threads:** [what is unresolved]
**Next up:** [what the entry says to start with]

Is this correct? Say yes to continue, or correct anything first.
```

Only after confirmation does the session continue.

### If the entry is incomplete

Say so honestly, name what is missing, and let the developer decide whether to fill the gap or continue. Do not guess.

---

## The Rule

Every session ends with `/fa:remember save`.
Every session starts with `/fa:remember restore`.
Restore reads one entry. History is searched, never loaded.
Durable facts get promoted; the diary keeps the story.
