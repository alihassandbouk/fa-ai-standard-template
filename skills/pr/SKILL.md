---
name: pr
description: Write a pull request body: one visual that makes the change clear, before-and-after evidence from a real run, and a merge-danger note (one-way or two-way door, blast radius). Use when opening or describing a PR.
---

# pr

Adapted from Matt Pocock's `pr` skill (MIT), itself from Dex Horthy's `show-me`.

Skip preambles. Use the domain language in `context/glossary.md`. Name the
ticket key in the title.

```markdown
## Summary

<one visual: pseudocode for logic, a call tree for runtime flow, a component
tree for UI, a shallow file tree for a refactor, a mermaid sequence for
interactions, or a diff of one of those when the shape already existed>

## Evidence

- **Before:** <screenshot, output, or the failing test run>
  **After:** <screenshot, output, or the passing test run>

## Merge Danger

**Door:** <one-way or two-way> — <why>
**Blast radius:** <one phrase> — <what else this can affect>

## Decisions

- ADR-00X <title>   (omit the section if none)
```

Pick the smallest view that makes the point. Screenshots for visual changes,
a real test invocation and its output otherwise; never a description of
evidence in place of evidence. A change that is cheap to roll back is a
two-way door; a migration, a deleted column, a changed contract is one-way.
