---
name: remember
description: Carry a session's handoff through the committed repo diary: `save` at the end of a session, `restore` at the start of one.
allowed-tools: Read, Bash, Write, Edit
---

# remember

The repo diary, `diary/repo/YYYY-MM-DD.<author>.md`, is the committed handoff
between sessions: written for a teammate, about this project only. The
developer's personal diary belongs to the `diary` skill, whose entry-writing
advice and secrets rule apply here too; decisions and non-obvious fixes go
there as they happen, not at the end.

Argument `save` → read `references/save.md`. Argument `restore` → read
`references/restore.md`. No argument → ask which one.

Restore reads one day; history is searched, never loaded. Durable facts get
promoted; the diary keeps the story.
