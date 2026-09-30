---
name: audit
description: Fill the project's AI context from the codebase — the context/*.md reference files CLAUDE.md imports every session, plus a nested AGENTS.md for each area with its own conventions. Run /fa:audit on a repo whose context files still have _TODO_ sections, after a change that made them stale, or on one area (/fa:audit src/auth). Adds only what is missing; never overwrites what a human wrote.
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
---

# audit — bootstrap the AI context

`CLAUDE.md` imports `context/*.md` into every session, so what this skill
writes is what every future session knows. Write present-tense facts about the
code as it is. No history, no plans.

## What it writes

| Target | Content | Rule |
|---|---|---|
| `context/project-overview.md` | what it is, problem, pages, roles, features by page | replace `_TODO_` only |
| `context/project-overview.md`, `context/code-standards.md` | target user, stakeholders, source documents, engineering mindset | the code cannot answer these: ask the developer, one question per heading, then write the answer |
| `context/architecture.md` | stack, folder structure, boundaries, data model, deployment | replace `_TODO_` only |
| `context/code-standards.md` | conventions observed in the code: naming, tests, errors, logging | replace `_TODO_` only |
| `context/code-standards.md`, `## .NET standard` | the TFA rules from `${CLAUDE_PLUGIN_ROOT}/skills/tfa-development-guard/references/standards.md` | append if the repo is .NET and the heading is missing |
| `docs/schema.d2` | the database diagram, generated with `/fa:efcore-d2-db-diagram` and linked from `context/architecture.md` under *Data & domain model* | .NET repos with a `DbContext`; create if missing |
| `context/glossary.md` | the domain terms the code uses, one line each, vocabulary only | add missing terms; never redefine an existing one, flag it |
| `context/ui-rules.md` | design system package, RTL and i18n, accessibility | replace `_TODO_`; skip if no UI |
| `<area>/AGENTS.md` | overview, key files, conventions, gotchas of one area | create only where the area has conventions the root files do not state |

Never rewrite a line a human wrote. If the code contradicts curated content,
list it under **Contradictions** in the report and leave the file alone.

## Steps

1. **Scope.** An argument path means that area only: its `AGENTS.md` and the
   integration file it touches. No argument means the whole repo.
2. **Scan.** Manifests, entry points, folder tree, config, CI, tests. For a
   large repo, spawn one read-only Explore agent on `haiku` per top-level area
   to return a compact map of files, conventions and gotchas; write on the main
   thread.
3. **Write** the targets above. A nested `AGENTS.md` follows this shape and is
   then listed in `context/architecture.md` under *Folder Structure*:

   ```markdown
   # <Area>

   ## Overview
   <2–3 sentences: what it does and why it exists>

   ## Key files
   | File | Owns |
   |---|---|

   ## Conventions
   - ...

   ## Gotchas
   - ...
   ```

4. **Ask** the developer for each remaining `_TODO_` the code cannot answer and
   write the answers. A `_TODO_` the developer defers stays as it is.
5. **Report:** what was written, what was skipped because it was curated,
   contradictions, and the `_TODO_`s still open.

## Not this skill

Tickets (`/fa:grill-with-docs` reads them), ADRs (it writes them), upkeep after a change (`/fa:sync`). A repo with no `context/` at all
needs `/fa:init` first.
