---
name: grill-with-docs
description: Before building a feature, interview the developer relentlessly until every design decision is settled, writing the glossary and ADRs as terms and decisions crystallise. Ends with an implementation plan that names the seams to test, then hands off to /fa:implement. Use before any feature; trigger phrases "grill me", "let's design", "before we build".
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit
---

# grill-with-docs

Adapted from Matt Pocock's `grilling` and `domain-modeling` skills (MIT).

Interview the developer until you share one understanding of what is being
built, and leave the vocabulary and the decisions written down where the next
session finds them. Then produce the plan `/fa:implement` builds from.

## Before the first question

Read, do not ask about: the requirement (the Jira story or the spec file),
`context/glossary.md`, `docs/adr/`, and the `AGENTS.md` of the areas the
feature touches. Never write to Jira. Anything already answered there is not
a question.

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

Done when the frontier is empty and nothing is silently assumed. Say
`Blueprint ready.` and do not act until the developer confirms.

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
- **Offer an ADR only when all three hold:** hard to reverse, surprising
  without context, the result of a real trade-off. Otherwise it is a plan
  detail. Write it in `docs/adr/`, numbered after the highest, in the
  template there, status Proposed. Never edit an accepted ADR; supersede it.

## The plan

After confirmation, write it in the conversation (it is ephemeral; the
glossary and ADRs are the artifacts):

```
## Implementation Plan — <feature>

### What we are building
<one paragraph>

### Requirements covered
- <ticket keys or requirement IDs; name any Must not covered and why>

### Decisions
- <decision → reasoning → rejected; ADR-00X where one was written>

### Seams to test
- <the public boundaries where tests will live; nothing is tested elsewhere>

### Steps
1. <ordered, each a vertical slice>
```

Then: `Run /fa:implement to build this.`

## What this is not

Not an interrogation to prove the developer wrong. Not a spec session, the
requirement exists. Not endless: ask what changes the build, settle it, write
it down, hand off.
