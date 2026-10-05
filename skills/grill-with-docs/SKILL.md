---
name: grill-with-docs
description: Interview the developer until every design decision is settled, writing ADRs as decisions land, then hand a plan to /fa:implement. Argument: the ticket key, if there is one.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit
---

# grill-with-docs

Interview the developer until you share one understanding of what is being
built, and leave the vocabulary and the decisions written down where the next
session finds them. Then produce the plan `/fa:implement` builds from.

## Before the first question

The argument is the ticket key. No argument means no ticket exists yet;
`/fa:to-spec` creates one at the end.

Read first, so none of it becomes a question: the Jira ticket when one
exists, the Figma design it links (Figma MCP: design context and a
screenshot), `context/glossary.md`, `docs/adr/`, and the `AGENTS.md` of the
areas the feature touches. Jira is written by `/fa:to-spec` and
`/fa:to-tickets` only, after approval.

## The interview

Map the design as a **tree**: every decision branches into the decisions
that hang off it. Work it in **rounds**. The **frontier** is every decision
whose prerequisites are settled, so it can be asked now without guessing at
answers not yet heard. Ask the whole frontier in one round, numbered, each
with your recommended answer:

```
❓ Q1 - <title>: <question, with the choices>
➡️ <your recommended answer, and why>
```

Each round of answers reshapes the tree: settled decisions push the frontier
outward. A question whose answer depends on another still open in this round
belongs to a later round. Finding **facts** is your job, never the developer's:
when a question needs a fact from the codebase, dispatch a read-only agent
and ask the rest of the frontier meanwhile. **Decisions** are the developer's.

The last round always holds one more question: **does the build fit one
session?** Recommend from the step count and the layers each step crosses.

Done when the frontier is empty and nothing is silently assumed. Say
`Blueprint ready.` and wait for the developer to confirm.

## While interviewing: keep the domain model sharp

- **Challenge against the glossary.** A term used in a way `context/glossary.md`
  does not define it: "The glossary says cancellation is X, you seem to mean Y.
  Which is it?"
- **Sharpen fuzzy language.** "Account: do you mean the Customer or the User?
  Those are different things." Propose the canonical term.
- **Invent scenarios.** When concepts relate, stress-test the boundary with a
  concrete case that forces precision.
- **Cross-reference the code.** When the developer states how something works,
  check. Surface any contradiction.
- **Write the glossary inline.** The moment a term is resolved, add or rewrite
  its line in `context/glossary.md`. Vocabulary only, no implementation detail.
  Format: `- **Term** — definition. Not: <what it is confused with>.`
- **Offer an ADR for every ADR-worthy decision** (`docs/adr/README.md`: the
  test, the numbering, the status) and write it the moment the developer
  agrees. Anything short of ADR-worthy is a plan detail.

## The plan

After confirmation, write it in the conversation (it is ephemeral; the
glossary and ADRs are the artifacts):

```
## Implementation Plan — <feature>

### What we are building
<one paragraph>

### Ticket
- <key, and anything in it not covered and why; or "none yet">

### Decisions
- <decision → reasoning → rejected; ADR-00X where one was written>

### Seams to test
- <the public boundaries where tests will live; nothing is tested elsewhere>

### Steps
1. <ordered, each a vertical slice>
```

## The handoff, enforced here

Run the next steps yourself, in this order, with the Skill tool:

1. No ticket → `/fa:to-spec`. It creates the ticket and returns the key.
2. Does not fit one session → `/fa:to-tickets`. It creates the sub-tasks.
3. Then stop with one line: `Run /fa:implement` (or `/fa:implement <first
   unblocked sub-task>`), ideally in a fresh session so the build starts with
   a clean context.

Ask what changes the build, settle it, write it down, hand off. The ticket is
the spec; the questions serve the build, never a point against the developer.
