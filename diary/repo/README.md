# Repo Diary

**Function:** Committed, teammate-facing, append-only session log. One
entry per session, date-partitioned. Never edited after being written — if
something recorded here turns out to be wrong or outdated, note that in a
new entry rather than changing the old one.

This is what makes handovers fast: a new teammate or a new AI session can
read recent entries and reconstruct what happened without asking around.

Saved/restored with `/remember`. Older history is searched, not fully
re-read — `/remember` restores from the latest entry by default.
