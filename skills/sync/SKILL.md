---
name: sync
description: After review and before the PR: rewrite the context/*.md and AGENTS.md lines the branch made false, and flag decisions with no ADR.
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
---

# sync — keep the context current

Context files describe the present. A merged change that leaves them
describing the past misleads every later session.

## Steps

1. **Change set.** On a branch: `git diff --name-status $(git merge-base main HEAD)`.
   On main: `git diff --name-status HEAD`. Add untracked files from
   `git ls-files --others --exclude-standard`. Drop docs, tests and lockfiles.
   Nothing left → say so and stop.
2. **Map** each changed source file to the context it affects:
   - files under an area → that area's `AGENTS.md`
   - stack, dependencies, folders, deployment → `context/architecture.md`
   - a convention the change introduces or breaks → `context/code-standards.md`
   - a new external system → `context/architecture.md` under *System Boundaries*
   - UI → `context/ui-rules.md` and `context/ui-patterns.md`
   - EF Core entities, configurations or migrations → `docs/schema.d2` is stale: flag "regenerate with `/fa:efcore-d2-db-diagram`"
3. **Edit surgically.** Rewrite the one line that is now false; add the one
   line that is now missing. Never append "previously X, now Y". Never rewrite
   a paragraph. A brand-new area with real conventions gets an `AGENTS.md` in
   the `/fa:audit` shape and a line in `context/architecture.md`.
4. **Flag, do not fix:**
   - a decision that is hard to reverse, surprising without context, and the
     result of a real trade-off, with no ADR in `docs/adr/` → *needs ADR, run
     `/fa:grill-with-docs`*
   - a ticket (named in the diff or commits) whose ask changed while its tests
     did not → *non-negotiable violation*
   - curated prose the code now contradicts → list it, leave it
5. **Report:** edited (`file:line`), created, flagged. Then remind the
   developer to run `/fa:remember save`, commit, then `/fa:pr`.
