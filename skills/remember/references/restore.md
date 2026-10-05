# Restore

1. **Find the newest day.** Take the newest date among the files in
   `diary/repo/` and read the last three entries of every file with that
   date (one file per author). That is the whole read: the diary is an
   archive, and older work is searched (grep on `diary/repo/`, or
   `diary search` in the personal diary) only when the developer's question
   concerns it. `diary/repo/` missing or empty:

   ```
   No diary entries found in this repo.
   Either this is the first session, or nothing was saved.
   To save at the end of a session, run /fa:remember save.
   ```

2. **Read the essentials.** Those entries, plus `CLAUDE.md` if not already
   loaded. Nothing else.
3. **Confirm before building.** Summarise so the developer can verify:

   ```
   Restored from diary/repo/YYYY-MM-DD.<author>.md (HH:MM entry):

   **Last session:** [what changed]
   **Open threads:** [what is unresolved]
   **Next up:** [what the entry says to start with]

   Is this correct? Say yes to continue, or correct anything first.
   ```

   The session continues after confirmation. An incomplete entry: say so,
   name what is missing, and let the developer decide whether to fill the gap
   or continue.
