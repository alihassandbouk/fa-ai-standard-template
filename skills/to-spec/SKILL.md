---
name: to-spec
description: Turn a settled grill plan into the Jira ticket the work is tracked under. Use when /fa:grill-with-docs ends with no ticket.
---

# to-spec

Adapted from Matt Pocock's `to-spec` (MIT).

Work that starts from a developer, not from a business ticket, has no key for
commits, the PR and `/fa:sync` to name. This skill creates that ticket from
the grill session. Run it only when no ticket exists; the business path never
needs it.

## Inputs

The plan from `/fa:grill-with-docs` in this conversation, `context/glossary.md`,
and the ADRs grill wrote. Do not interview. Every line of the ticket is
something the developer already said; a line they cannot remember deciding is
a defect.

## Steps

1. **Issue type.** Ask one question: Story (user-visible behaviour) or Task
   (technical work), with your recommendation.
2. **Draft** the body below in the glossary's vocabulary and show it. The
   developer edits or approves; nothing is published before that.
3. **Publish** to the Jira project named under *Work tracking* in
   `context/project-overview.md`, through the Atlassian MCP server
   (`createJiraIssue`). Server not connected: stop and ask the developer to
   sign in with `/mcp`. Do not write a copy to disk.
4. **Report the key.** From here it is the ticket: `/fa:implement` names it in
   commits, `/fa:pr` in the title.

```markdown
## Problem
<what is wrong or missing today, from the user's or the team's perspective>

## Solution
<what changes once this ships, one paragraph>

## Decisions
- <decision → reasoning → rejected; ADR-00X where one was written>

## Seams to test
- <the public boundaries from the plan; nothing is tested elsewhere>

## Out of scope
- <what was deliberately refused; usually the most useful lines on the page>

## Arabic and English
<user-facing behaviour only: what each language shows; omit for technical work>
```

No file paths or code snippets in the body, they go stale. Exception: a
snippet that encodes a decision more precisely than prose (a state machine, a
schema, a type shape), trimmed to the decision.

Then: plan bigger than one session → `/fa:to-tickets`. Otherwise
`/fa:implement`.
