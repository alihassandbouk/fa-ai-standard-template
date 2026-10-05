# FA AI Development Standard — the `fa` plugin

One Claude Code plugin that gives every FA developer the same skills, the same
repo scaffold, the same hooks and the same MCP connections, installed from
this repo and updated from it.

1. [How it works](#how-it-works)
2. [Install](#install)
3. [Update and release](#update-and-release)
4. [Enterprise rollout](#enterprise-rollout)
5. [MCP servers: Jira, Confluence, Notion, Figma](#mcp-servers-jira-confluence-notion-figma)
6. [Tools and skills not in the plugin](#tools-and-skills-not-in-the-plugin)
7. [Skills](#skills)
8. [Hooks](#hooks)
9. [The two diaries](#the-two-diaries)
10. [Repo layout](#repo-layout)
11. [Developing the plugin](#developing-the-plugin)

## How it works

A Claude Code plugin is a folder with a manifest. When it is enabled, Claude
Code loads its `skills/` (as `/fa:<name>`), runs its `hooks/`, connects its
`.mcp.json` servers, and puts nothing else in your session. Only the
one-line descriptions of the model-invoked skills are loaded every session;
a body loads when its skill runs.

What the plugin cannot do is change a project. That is what `/fa:init` is
for: it copies `template/` into the repo. The scaffold's `CLAUDE.md` imports
the five `context/*.md` files, so from then on every session in that repo
starts with the project's overview, architecture, code standards, UI rules
and glossary already in context. Facts live in those files; procedures live in the skills.

The normal life of a project:

```
/fa:init          once, scaffolds the standard
/fa:audit         once, fills the context files from existing code
/fa:remember restore  at the start of every session (a hook reminds you)
/fa:grill-with-docs   before each feature: interview, glossary, ADRs, plan;
                      runs to-spec when there is no ticket and to-tickets when
                      the plan exceeds one session
/fa:implement         build it test-first at the agreed seams
/fa:review            three layers, in parallel
/fa:sync              keeps context/*.md true
/fa:remember save     the repo diary entry (a hook reminds you at any session end)
/fa:pr                the PR body, once the context and diary changes are committed
```

## Install

```bash
claude plugin marketplace add alihassandbouk/fa-ai-standard-template
claude plugin install fa@fa-ai
```

Or inside a session: `/plugin`, add the marketplace, install `fa`. The repo
is fetched with your machine's git credentials, so a private repo needs an
SSH key or a credential helper that can read it. Nothing else to configure.

Then in any project:

```
/fa:init
```

## Update and release

Installed copies are pinned to the `version` in
`.claude-plugin/plugin.json`. A release is a bump of that string and a push.
Developers pick it up with:

```bash
claude plugin marketplace update fa-ai
claude plugin update fa@fa-ai
```

Marketplaces registered through managed settings with `autoUpdate` refresh
on their own.

## Enterprise rollout

Put this in the managed settings file and every developer gets the plugin,
kept current, and cannot add marketplaces outside the organisation:

| OS | Path |
|---|---|
| Linux | `/etc/claude-code/managed-settings.json` |
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Windows | `C:\ProgramData\ClaudeCode\managed-settings.json` |

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

The same file can be delivered as an MDM policy. For one team without MDM,
the `extraKnownMarketplaces` and `enabledPlugins` keys go in the project's
`.claude/settings.json`; teammates are offered the plugin when they trust
the folder.

## MCP servers: Jira, Confluence, Notion, Figma

The plugin declares three remote servers in `.mcp.json`:

| Server | URL | Gives |
|---|---|---|
| `atlassian` | `https://mcp.atlassian.com/v2/mcp` | Jira and Confluence |
| `notion` | `https://mcp.notion.com/mcp` | Notion |
| `figma` | `https://mcp.figma.com/mcp` | Figma: design context, screenshots and variables of the frames a ticket links; its own skills arrive as server resources |

They connect when the plugin is enabled. Each developer signs in once, in a
session, with `/mcp` and the browser OAuth flow; tokens are stored per user
and refreshed automatically. No keys live in this repo. A server you do not
use can be switched off in `/mcp` without touching the plugin.

`/fa:to-spec` and `/fa:to-tickets` create Jira issues through the Atlassian
server and stop with a sign-in prompt when it is not connected. Every other
skill works without them; they are there so a developer can read a ticket,
search Confluence, read the Figma frame a ticket links, or update a Notion
page in the same session as the code.

## Tools and skills not in the plugin

These are installed per machine, not by the plugin. Each line is the install
command and why it is worth having.

| Tool or skill | Install | Why |
|---|---|---|
| [playwright-cli](https://github.com/microsoft/playwright-cli) and its skill | `npm install -g @playwright/cli@latest && playwright-cli install --skills` | Drives a browser to verify UI. The skill must match the CLI version, so it stays with the CLI installer. |
| [Impeccable](https://impeccable.style) | `npx skills add pbakaus/impeccable` | Frontend design, critique and polish. Pairs with `/fa:imprint`. |
| [Vercel React best practices](https://skills.sh/vercel-labs/agent-skills) | `npx skills add vercel-labs/agent-skills@react-best-practices` | React and Next.js performance rules. |
| [Web interface guidelines](https://skills.sh/vercel-labs/agent-skills) | `npx skills add vercel-labs/agent-skills@web-design-guidelines` | Accessibility and UX review. |
| [d2](https://d2lang.com/tour/install) | see the install page for your OS | Renders the `.d2` diagrams `/fa:efcore-d2-db-diagram` produces. |
| dotnet-ef | `dotnet tool install --global dotnet-ef` | Migrations in `/fa:tfa-development-guard`. |
| [GitHub CLI](https://cli.github.com) | package manager, then `gh auth login` | PRs and issues from the terminal. |

Several skills here are adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills)
(MIT): grill-with-docs, to-spec, to-tickets, implement's TDD rules, recover's
bug loop, review's parallel axes and smell baseline, pr (itself from Dex
Horthy's `show-me`), and the git guardrails hook. `writing-for-agents` is vendored unchanged.

Third-party skills install into `~/.claude/skills/` (add `-g` to the
`npx skills add` command for that) or into the project's `.claude/skills/`.
Update them with `npx skills update`.

## Skills

| Skill | When |
|---|---|
| `/fa:init` | Once per repo. Scaffolds the standard from `template/`. In a .NET repo, also copies the TFA rules into `context/code-standards.md`. |
| `/fa:audit` | Context files still have `_TODO_`s, or one area needs an `AGENTS.md`. |
| `/fa:grill-with-docs` | Before building. Interviews until every decision is settled, writes the glossary and ADRs as it goes, ends with a plan naming the seams to test, then runs to-spec and to-tickets when they apply. |
| `/fa:to-spec` | Run by grill when there is no ticket. Turns the grilled plan into a Jira Story or Task through the Atlassian MCP. |
| `/fa:to-tickets` | Run by grill when the plan exceeds one session. Cuts it into Jira sub-tasks with blocking links, one per fresh session. |
| `/fa:implement` | Builds the plan, or one sub-task, test-first at the agreed seams, then hands to review. |
| `/fa:pr` | PR body: one visual, before-and-after evidence, merge danger. |
| `/fa:review` | After building. Plan, system, production readiness. In .NET repos also the TFA review checklist. |
| `/fa:sync` | After review, before the PR. Keeps `context/*.md` and `AGENTS.md` true; flags decisions with no ADR. |
| `/fa:remember` | `restore` at session start, `save` at session end. Repo diary, committed. |
| `/fa:diary` | The developer's personal diary, across all repos. Claude logs decisions and research as they happen. |
| `/fa:imprint` | After building UI. Verifies against `context/ui-rules.md`, records the pattern. |
| `/fa:dga` | Any UI in a React project. Builds from the official DGA Platforms Code components through their React adapter, never a vendored copy; sets the package up on the first UI session, adds the lint rule, and carries the catalogue, the RTL, Hijri and accessibility rules, and the gotchas the package does not document. |
| `/fa:recover` | Something went wrong. Diagnose the failure type; hard bugs get the feedback-loop discipline. |
| `/fa:tfa-development-guard` | Any .NET/C# work: Clean Architecture + EF Core standard, layer templates, refactoring workflow, checklists. |
| `/fa:tfa-integration-fast-core` | Integrating with FAST Core: REST, SSO, or DB views. |
| `/fa:efcore-d2-db-diagram` | Generate a D2 entity-relationship diagram from EF Core models into `docs/schema.d2`. |
| `/fa:writing-for-agents` | Editing a skill, `AGENTS.md` or `CLAUDE.md`. Matt Pocock's writing reference, vendored unchanged. |

Seven skills run only when you type them: `init`, `audit`,
`grill-with-docs`, `implement`, `sync`, `pr` and `recover`. Every other skill
also fires on its own when a request matches its description.

## Hooks

- **SessionStart**: one line reminding you to run `/fa:remember restore`
  (in a repo with a `diary/repo/`) and to search the personal diary before
  touching an area with history.
- **PreToolUse** on Bash: blocks destructive git before it runs (force push,
  `reset --hard`, `clean -f`, `branch -D`, `checkout .`, `restore .`). Plain
  `git push` stays allowed.
- **Stop**, once per session: if the repo diary is older than the work done,
  asks Claude to run `/fa:remember save`; if nothing was logged to the
  personal diary, asks for a session entry. Both are silent when there is
  nothing to save.

The repo-diary hooks are plain bash; the personal diary is `scripts/diary`,
Python 3 with no dependencies.

## The two diaries

| | Repo diary | Personal diary |
|---|---|---|
| Where | `diary/repo/YYYY-MM-DD.<author>.md`, committed | `~/.claude/diary`, per machine |
| For | teammates: what changed, decisions, next step | the developer: decisions, research, fixes across every repo |
| Written by | `/fa:remember save` | Claude, through `scripts/diary`, as things happen |
| Conflicts | one file per author per day, so branches merge clean | one file per machine per day |

The personal diary works locally from the first session. To keep it across
machines or backed up, set a private git remote once:

```bash
python3 ~/.claude/plugins/cache/fa-ai/fa/<version>/scripts/diary sync --remote git@github.com:<you>/diary.git
```

After that `diary sync` at the end of a session commits and exchanges
entries.

## Repo layout

```
.claude-plugin/   plugin.json (name, version) and marketplace.json (source ./)
.mcp.json         Atlassian, Notion and Figma remote servers
skills/           one folder per skill, SKILL.md plus references/
hooks/            hooks.json, session-start.sh, stop.sh, git-guardrails.sh
scripts/diary     personal diary CLI
template/         what /fa:init copies into a project:
                    CLAUDE.md, context/ (incl. glossary), docs/adr/, diary/repo/, .gitignore
```

## Developing the plugin

```bash
claude plugin validate .   # manifests, hooks, MCP entries
claude --plugin-dir .      # a session with the working copy loaded
```

Rules of the repo are in `CLAUDE.md`: skills and context files are written
under `writing-for-agents`, facts go in `template/` context files and
procedures in skills, and `version` is bumped on every release.
