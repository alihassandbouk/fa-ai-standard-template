# CLAUDE.md

**Function:** The entry point for any AI agent working in this repo. States the
non-negotiable rules and the session rhythm. This file should rarely
change — it describes the *process*, not the project.

---

## Always-loaded context

The files below are imported into every session. Keep them present-tense and
short; everything else is read on demand.

@context/project-overview.md
@context/architecture.md
@context/code-standards.md
@context/ui-rules.md

Before touching an area, also read that area's `AGENTS.md` if one exists
(`/fa:audit` writes them). `docs/adr/`, `diary/` and `context/integrations/`
are read when the task needs them, not every session.

## Non-negotiables

- No ticket without a requirement ID.
- Never edit an accepted ADR — supersede it.
- Changing a requirement means changing its tests.
- Reference files (`context/*.md`, `AGENTS.md`) are rewritten to reflect the
  current state, never appended with "previously X, now Y."
- Diary entries and ADRs are append-only once written.
- No PII in logs.

## Session rhythm

- Start: `/fa:remember restore`. End: `/fa:remember save`.
- Change landed: `/fa:sync` keeps the context files true.
- Built UI: `/fa:imprint`. Stuck: `/fa:recover`.
