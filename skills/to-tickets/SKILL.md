---
name: to-tickets
description: Break a grill plan into Jira sub-tasks of its ticket, each a tracer bullet that fits one session and names the sub-tasks that block it. Use when /fa:grill-with-docs ends with a plan larger than one session.
---

# to-tickets

A plan that outlives the conversation has to live in the tracker, cut into
pieces a fresh session can finish alone. A plan that fits one session skips
this and goes straight to `/fa:implement`.

## Inputs

The plan in this conversation and its ticket key, from the business or from
`/fa:to-spec`. Given a key as the argument, fetch the ticket and its comments
(`getJiraIssue`). Use `context/glossary.md` vocabulary throughout.

## Draft the slices

Start from the plan's *Steps*; each is already meant to be a vertical slice.

- A slice cuts one complete path through every layer: schema, API, UI, tests.
  Done, it is demoable on its own.
- A slice fits one fresh context window.
- *Blocked by* names the slices that must finish first. None means it can
  start now.
- A **wide refactor**, one mechanical change whose blast radius spans the
  codebase, is the exception: sequence it as expand (add the new form beside
  the old), migrate (call sites in batches sized by blast radius, each blocked
  by expand), contract (delete the old form, blocked by every migrate).
- Prose only, with the same snippet exception as `/fa:to-spec`.

Test every slice with one question: *what can I demo when this is done?* No
answer means a horizontal slice. Re-cut it.

## Quiz the developer

Present a numbered list, each entry: **Title**, **Blocked by**, **What it
delivers**. Ask whether the granularity is right, whether every edge is a real
gate, and what should merge or split. Iterate until approved. Nothing is
published before that.

## Publish

Through the Atlassian MCP server, blockers first so every link names a real
key: `createJiraIssue` as a Sub-task of the parent with the body below, then
`createIssueLink` of type *Blocks* for each edge. Server not connected: stop
and ask the developer to sign in with `/mcp`. The parent stays as it is.

```markdown
## What to build
<the end-to-end behaviour this sub-task makes work, from the user's perspective>

## Acceptance criteria
- [ ] <false at the commit the implementer starts from, true when done>

## Seams
- <the plan's seams this slice tests at>

## Blocked by
- KEY-12, or "none, can start now"
```

Report the keys and the **frontier**: every sub-task whose blockers are Done.
Each is one fresh session of `/fa:implement <key>`.
