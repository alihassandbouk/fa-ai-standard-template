# FA AI Development Standard — plugin

One Claude Code plugin (`fa`) that carries the process skills, the repo
scaffold, and the TFA .NET skills, installed and updated from this repo.

## Install

```bash
claude plugin marketplace add alihassandbouk/fa-ai-standard-template
claude plugin install fa@fa-ai
```

Then in any project:

```
/fa:init      # scaffold CLAUDE.md, context/, docs/adr/, diary/
/fa:audit     # fill the context files from an existing codebase
```

Private repo: the marketplace is fetched with the machine's git credentials
(SSH key or credential helper). Nothing else to configure.

## Update

```bash
claude plugin marketplace update fa-ai
claude plugin update fa@fa-ai
```

A release is a bump of `version` in `.claude-plugin/plugin.json` plus a push.
Installed copies stay pinned until that string changes.

## Enterprise rollout

Drop this into the managed settings file (`/etc/claude-code/managed-settings.json`
on Linux, `/Library/Application Support/ClaudeCode/managed-settings.json` on
macOS, `C:\ProgramData\ClaudeCode\managed-settings.json` on Windows, or the
equivalent MDM policy). Every developer then gets the plugin, kept current,
and cannot add marketplaces outside the org:

```json
{
  "extraKnownMarketplaces": {
    "fa-ai": {
      "source": { "source": "github", "repo": "alihassandbouk/fa-ai-standard-template" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "fa@fa-ai": true },
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "alihassandbouk/*" }
  ]
}
```

For a single team without MDM, the same `extraKnownMarketplaces` and
`enabledPlugins` keys go in the project's `.claude/settings.json`; teammates
are offered the plugin when they trust the folder.

## What is in it

| Skill | When |
|---|---|
| `/fa:init` | Once per repo. Scaffolds the standard from `template/`. |
| `/fa:audit` | Context files still have `_TODO_`s, or one area needs an `AGENTS.md`. |
| `/fa:architect` | Before building. Decisions → ADRs. |
| `/fa:review` | After building. Plan, system, production readiness. |
| `/fa:sync` | Before merge. Keeps `context/*.md` and `AGENTS.md` true. |
| `/fa:remember` | `restore` at session start, `save` at session end. |
| `/fa:imprint` | After building UI. Records the composition pattern. |
| `/fa:recover` | Something went wrong. Diagnose before fixing. |
| `/fa:diary` | The developer's personal diary, across all repos. Claude logs decisions and research as they happen. |
| `/fa:tfa-development-guard` | Any .NET/C# work: Clean Architecture + EF Core standard. |
| `/fa:tfa-integration-fast-core` | Integrating with FAST Core: REST, SSO, or DB views. |

The scaffold a project receives:

```
CLAUDE.md            # non-negotiables, @imports of context/*.md
context/             # present-tense source of truth, imported every session
docs/adr/            # append-only decisions
diary/repo/          # committed session log, one file per day per author
```

## Hooks the plugin ships

- **SessionStart**: prints the last entry of `diary/repo/` into context, so
  every session starts with the previous handoff. Nothing to type.
- **Stop**: once per session, if the repo diary is older than the work done,
  reminds Claude to run `/fa:remember save`. Silent in repos without
  `diary/repo/`.

- **Stop** (second): once per session, if nothing was logged to the personal
  diary, reminds Claude to write a session entry.

The repo-diary hooks are plain bash; the personal diary is `bin/diary`,
Python 3 with no dependencies.

## The personal diary

Every developer gets a private, append-only journal at `~/.claude/diary`,
written by Claude through the `diary` CLI: one entry per session, plus one
after each decision, heavy research or non-obvious fix. It works locally from
the first session. To keep it across machines or backed up, set a private git
remote once:

```bash
python3 ~/.claude/plugins/cache/fa-ai/fa/<version>/bin/diary sync --remote git@github.com:<you>/diary.git
```

After that `diary sync` at the end of a session commits and exchanges
entries. Each machine writes only its own day files, so nothing conflicts.

## Recommended companions

- [playwright-cli](https://github.com/microsoft/playwright-cli):
  `npm install -g @playwright/cli@latest && playwright-cli install --skills`
- [Impeccable](https://impeccable.style): `npx skills add pbakaus/impeccable`

## Developing the plugin

```bash
claude plugin validate .        # manifests
claude --plugin-dir . # run a session with the working copy loaded
```
