# Repo Diary

**Function:** Committed, teammate-facing, append-only session log. One
entry per session, date-partitioned. Never edited after being written — if
something recorded here turns out to be wrong or outdated, note that in a
new entry rather than changing the old one.

This is what makes handovers fast: a new teammate or a new AI session can
read recent entries and reconstruct what happened without asking around.

Saved/restored with `/fa:remember`. One file per day **per author** (`YYYY-MM-DD.<author>.md`), so two branches never edit the same diary file and merges stay clean. Older history is searched, not fully
re-read — `/fa:remember` restores from the latest entry by default.
