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





-  Read All the context files AGENT.md files across the Repo