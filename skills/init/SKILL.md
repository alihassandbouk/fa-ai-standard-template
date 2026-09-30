---
name: init
description: Scaffold the FA AI Development Standard into the current repo — CLAUDE.md with the non-negotiables, the context/ reference files, docs/adr/, diary/ and .gitignore entries. Run once in a new or existing project; never overwrites a file that already exists. Use when the user says "init the standard", "set up this repo for AI", "bootstrap the context", or when a repo has no CLAUDE.md.
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
---

# init — scaffold the standard

The scaffold ships with this plugin at `${CLAUDE_PLUGIN_ROOT}/template/`. If
that variable is unset, it is `../../template/` relative to this SKILL.md.

## Steps

1. Resolve the template directory. If it does not exist, stop and say so.
2. Copy it into the repo root without overwriting anything:

   ```bash
   cd "$(git rev-parse --show-toplevel)" && cp -rn "$CLAUDE_PLUGIN_ROOT/template/." .
   ```

   `.gitignore` is the one exception: if the repo already has one, append the
   template lines that are missing instead of skipping the file.
3. Decide what happens to the `_TODO_` sections:
   - **Existing code** (source files and commit history): tell the user to run
     `/fa:audit`, which fills them from the codebase.
   - **Greenfield**: ask one question, "In one paragraph, what is this project
     and who is it for?", and write the answer into
     `context/project-overview.md` under *What this project is*. Leave the
     rest as `_TODO_`.
4. **.NET repo** (a `*.sln` or `*.csproj` exists): append the contents of
   `${CLAUDE_PLUGIN_ROOT}/skills/tfa-development-guard/references/standards.md`
   to `context/code-standards.md` under a `## .NET standard` heading, so the
   rules are in context every session.
5. Report: files created, files skipped because they existed, and the next
   step (`/fa:audit`, or filling the remaining `_TODO_`s).

Do not commit. Do not touch files outside the template's paths.
