# FA AI Coding Standard — Repo Template

This is a starting scaffold for any FA project adopting the AI Development
Standard. Every file has a header explaining its function — fill in the
`_TODO_` sections with project-specific content, then delete this note.

Start with `CLAUDE.md` — it explains the three gates and points to
everything else in this repo.

## Structure

```
.
├── CLAUDE.md                    # Non-negotiables + the three gates
├── context/                     # Present-tense source of truth
│   ├── architecture.md
│   ├── code-standards.md
│   ├── project-overview.md
│   ├── ui-rules.md
│   └── integrations/            # One file per external integration
├── docs/
│   └── adr/                     # Append-only architecture decisions
│       └── 0000-template.md
├── specs/                       # Future-tense: what's being built (Gate A)
├── diary/
│   ├── repo/                    # Committed, teammate-facing session log
│   └── personal/                # Gitignored, individual session log
├── scripts/
│   └── check_traceability.py    # Gate C mechanical enforcement
└── .claude/
    └── commands/                # Skills (/architect, /review, /recover,
                                  # /imprint, /spec-review, /spec-generate,
                                  # /remember)
```
