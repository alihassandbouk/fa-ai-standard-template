---
name: to-spec
description: Turn a settled grill plan into the Jira ticket the work is tracked under. Use when /fa:grill-with-docs ends with no ticket.
---

# to-spec

Work that starts from a developer, not from a business ticket, has no key for
commits, the PR and `/fa:sync` to name. This skill creates that ticket from
the grill session; the business path starts with a ticket and skips it.

## Inputs

The plan from `/fa:grill-with-docs` in this conversation, `context/glossary.md`,
and the ADRs grill wrote. Synthesis only: every line of the ticket is
something the developer already said, and a line they cannot remember
deciding is a defect.

## Steps

1. **Issue type.** Ask one question: Story (user-visible behaviour) or Task
   (technical work), with your recommendation.
2. **Draft** the body below in the glossary's vocabulary and show it. The
   developer edits or approves; nothing is published before that.
3. **Publish** to the Jira project named under *Work tracking* in
   `context/project-overview.md`, through the Atlassian MCP server
   (`createJiraIssue`). Server not connected: stop and ask the developer to
   sign in with `/mcp`. The ticket lives in Jira only.
4. **Report the key.** From here it is the ticket: commits, the PR title and
   `/fa:sync` name it.

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

The body is prose: file paths and code snippets go stale. Exception: a
snippet that encodes a decision more precisely than prose (a state machine, a
schema, a type shape), trimmed to the decision.
