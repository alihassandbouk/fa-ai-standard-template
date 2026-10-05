---
name: recover
description: Diagnose what kind of failure a build hit before choosing a targeted fix, a hard reset or a rethink.
disable-model-invocation: true
allowed-tools: Read
---

# recover

Diagnose the failure first, then respond. The two steps never swap: the right
response depends on the failure mode, and more prompting at the wrong one
makes the code worse.

## Step 1 — What went wrong

Ask, and listen before doing anything else:

```
Describe what is wrong. Be specific:
- What did you expect to happen?
- What happened instead?
- How many times have you tried to fix it already?
```

The number of fix attempts tells you whether this is a fresh problem or a
session that has already gone wrong.

## Step 2 — The failure mode

### Failure Mode 1 — A specific thing is broken

Signs:

- The problem is isolated: one component, one function, one route
- The rest of the project works correctly
- This is the first or second attempt at fixing it
- The error message or wrong behaviour is clear and specific

A normal bug, with a root cause that can be found and fixed precisely.
Response: targeted fix, `references/targeted-fix.md`.

### Failure Mode 2 — The session has gone wrong

Signs:

- Multiple fix attempts have made things worse or created new problems
- The code has become tangled: fixes are patching fixes
- Context in this session is full of failed attempts
- It is no longer clear what the original problem was

The session is polluted, and more prompting compounds the damage; the
feature is rebuilt in a clean context. Response: hard reset,
`references/hard-reset.md`.

### Failure Mode 3 — The foundation is wrong

Signs:

- The code runs but produces fundamentally wrong behaviour
- Claude has been confidently building something that misunderstands a core
  requirement, library API, or architectural pattern
- The implementation itself is wrong, so fixing individual pieces changes
  nothing

The approach is reconsidered before any more code; more implementation in
the wrong direction is harder to untangle. Response: rethink,
`references/rethink.md`.

Tell the developer which failure mode this is, then read that reference and
follow it:

```
This looks like Failure Mode [1/2/3] — [name].

[One sentence explaining why you identified it this way.]

Here is how we handle this:
```
