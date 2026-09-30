# CLAUDE.md

This repo is the **FA AI Development Standard** packaged as a Claude Code
plugin (`fa`) plus the scaffold it installs into projects.

- `skills/<name>/SKILL.md` — the skills. Only the frontmatter `description`
  is loaded every session; keep it under ~3 lines and put detail in the body
  or in `references/`.
- `template/` — what `/fa:init` copies into a project. `template/CLAUDE.md`
  is the process file every project gets; it should rarely change.
- `.claude-plugin/plugin.json` — bump `version` on every release; installed
  copies only update when that string changes.

Test locally with `claude --plugin-dir .` and `claude plugin validate .`.
Skill bodies are read on invoke only, so a skill that must be honoured every
session belongs in `template/CLAUDE.md`, not in a skill.
