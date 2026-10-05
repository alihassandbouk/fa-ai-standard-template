# CLAUDE.md

This repo is the **FA AI Development Standard** packaged as a Claude Code
plugin (`fa`) plus the scaffold it installs into projects.

- `skills/<name>/SKILL.md` — the skills; detail goes in `references/`.
- `template/` — what `/fa:init` copies into a project. `template/CLAUDE.md`
  is the process file every project gets; it should rarely change.
- `.claude-plugin/plugin.json` — bump `version` on every release; installed
  copies only update when that string changes.

Test locally with `claude --plugin-dir .` and `claude plugin validate .`.
Skill bodies are read on invoke only, so a skill that must be honoured every
session belongs in `template/CLAUDE.md`, not in a skill.

Writing rules for skills, `template/CLAUDE.md` and context files are the
`writing-for-agents` skill, vendored unchanged from Matt Pocock; it fires on
its own when one of those files is edited. The seven skills a developer types
by hand (init, audit, grill-with-docs, implement, sync, pr, recover) are
user-invoked; the rest are model-invoked, so no skill can fire one of the seven.
