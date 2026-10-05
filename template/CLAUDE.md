# CLAUDE.md

The entry point for any agent working in this repo: the non-negotiables and
the session rhythm. It describes the process, not the project, so it rarely
changes.

## Always-loaded context

The files below are imported into every session. Keep them present-tense and
short; everything else is read on demand.

@context/project-overview.md
@context/architecture.md
@context/code-standards.md
@context/ui-rules.md
@context/glossary.md

Before touching an area, also read that area's `AGENTS.md` if one exists
(`/fa:audit` writes them). `docs/adr/` and `diary/` are read when the task
needs them.

## Non-negotiables

- Every ADR-worthy decision gets an ADR, and a changed decision is a new ADR
  that supersedes the old one: `docs/adr/README.md`.
- Changing what a ticket asks for means changing its tests.
- Reference files (`context/*.md`, `AGENTS.md`) describe the present: a
  change rewrites the line that is now false.
- Diary entries and ADRs are append-only once written.
- Logs name records by id and carry no personal data.

## Session rhythm

- Start: `/fa:remember restore`, and confirm what it found.
- Feature: `/fa:grill-with-docs <ticket key, if any>` (design, glossary,
  ADRs; creates the ticket and splits the plan when needed) → `/fa:implement`
  (test-first at the agreed seams) → `/fa:review` → `/fa:sync` →
  `/fa:remember save` → commit (the message names the ticket) → `/fa:pr`, so
  the context files and the diary entry are in the branch the PR covers.
- End of any session: `/fa:remember save`. Built UI: `/fa:imprint`. Stuck:
  `/fa:recover`.
