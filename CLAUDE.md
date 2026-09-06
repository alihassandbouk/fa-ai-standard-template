# CLAUDE.md

**Function:** The entry point for any AI agent working in this repo. States the
non-negotiable rules and the three pipeline gates. This file should rarely
change — it describes the *process*, not the project.

---

## Non-negotiables

- No ticket without a requirement ID.
- Never edit an accepted ADR — supersede it.
- Changing a requirement means changing its tests.
- Reference files (`context/*.md`) are rewritten to reflect the current
  state, never appended with "previously X, now Y."
- Diary entries and ADRs are append-only once written.
- No PII in logs.

## The three gates

**Gate A — Spec approval.**
Business requirements are translated into a spec (see `specs/`) with an
explicit requirement, Given/When/Then done criteria, and a test plan, keyed
to the source HLR ID. Generated/checked with `/spec-generate` and
`/spec-review`. Nothing is built before Gate A passes.

**Gate B — Architecture lock.**
Key technical decisions are recorded as an ADR (see `docs/adr/`) before
implementation begins, using `/architect`. Each ADR records what was
decided, why, and when. If a decision conflicts with a Must-have
requirement, that conflict is flagged explicitly, not silently patched.

**Gate C — CI green, self-review, human merge.**
Before code ships: automated tests pass in CI, the traceability check
(`scripts/check_traceability.py`) passes, the AI agent reviews its own
output against the spec, and a human approves the pull request.

## When requirements change

| What changed | Where you start | Gate to re-run |
|---|---|---|
| New feature or scope | Add a new requirement ID to the spec (PR) | Gate A |
| Existing requirement changed | Edit the requirement + its done criteria (PR) | Gate A |
| Architecture decision affected | Write a **new** ADR that supersedes the old one | Gate B |
| Bug, copy fix, no requirement impact | Normal ticket | Gate C only |

Log every mid-sprint requirement change in the repo diary — which
requirement, and why.
