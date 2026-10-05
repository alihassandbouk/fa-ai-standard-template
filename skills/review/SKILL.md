---
name: review
description: Review a built feature against its plan, the architecture and production readiness; the developer picks what to fix. Use after /fa:implement, or when asked to review a branch.
---

# review

Verify a built feature before the next one starts. Report what you find; the
developer decides what to fix.

## Step 1 — The benchmark

Read, in this order: the implementation plan from `/fa:grill-with-docs` if
one exists, the ticket or task that was given, and the ADRs and `AGENTS.md`
of the areas touched. No plan and no ticket: ask the developer what the
feature was supposed to do before reviewing. Correct needs a definition.

## Step 2 — Three layers, in parallel

Pin the diff first: `git diff $(git merge-base main HEAD)...HEAD` on a
branch, `git diff HEAD` on main; confirm it is non-empty. Then run each layer
as its own read-only subagent with the diff, the sources it needs, and a
brief of under 400 words, so a long review never pollutes the main context.
Every layer skips anything a linter, formatter, type checker or CI already
enforces. Findings are reported per layer and never merged or re-ranked
across layers: a change can pass one layer and fail another, and one must
not mask the other.

### Layer 1 — Does it match the plan?

Compare what was built against what was planned:

- Every part of the feature description — is it all there?
- The decisions made during planning — are they reflected in the code?
- The scope — did the implementation stay within bounds or add things that
  were not asked for?
- UI — matches the Figma frame the ticket links (Figma MCP screenshot next
  to the built screen)
- The tests — one at every seam the plan names and none elsewhere, and none
  of the three shapes `/fa:implement` bans (implementation-coupled,
  tautological, horizontal)

Flag anything that was planned but missing. Flag anything that was built but
not planned.

### Layer 2 — Does it respect the system?

- **Architecture boundaries** — does code in the right place own the right
  responsibilities? No UI logic in API routes. No DB calls in components.
  Whatever the project's boundaries are — are they respected?
- **Design system** — are the correct tokens, classes, and patterns used? Any
  hardcoded values that should be variables? Any raw color classes that
  should use the design system?
- **Code standards** — naming conventions, file organisation, TypeScript
  strictness, error handling patterns — do they match what the project
  established?
- **Existing patterns** — does this feature introduce a new pattern when an
  existing one should have been used?
- **Smell baseline** (always a judgement call, and a documented project
  standard overrides it): mysterious name, duplicated code, feature envy,
  data clumps, primitive obsession, repeated switches, shotgun surgery,
  divergent change, speculative generality, message chains, middle man,
  refused bequest. Name the smell, quote the hunk, say the fix.
- **.NET repos** — also run the Review Checklist and the skinny-controller
  validation procedure from `/fa:tfa-development-guard`, and report its
  "Skinny controller check" block.

### Layer 3 — Is it production ready?

- Error handling — what happens when things go wrong? Are errors caught and
  handled or does the feature silently fail?
- Edge cases — empty states, loading states, missing data — are these handled?
- Console errors — any errors or warnings in the browser or terminal?
- Obvious bugs — anything that would clearly break for a real user?

## Step 3 — Report

Every issue goes in the report at its real severity (guide below), so the
developer can make informed decisions.

```
## Review — [Feature Name]

### Layer 1 — Plan alignment
[PASS / ISSUES FOUND]
[List any gaps between what was planned and what was built, including untested seams and banned test shapes]

### Layer 2 — System integrity
[PASS / ISSUES FOUND]
[List any architecture, design, or code standard violations]

### Layer 3 — Production readiness
[PASS / ISSUES FOUND]
[List any error handling gaps, edge cases, or obvious bugs]

### Summary
Per layer: <count>, worst: <one line>. No single winner across layers.

[If no issues: "No issues found. This feature is ready to ship."]
[If issues: "Resolve the above before moving to the next feature."]
```

## Step 4 — The developer decides

After the report, stop and wait for the developer to ask for a specific fix,
mark an issue intentional, or confirm everything is resolved. Suggest a fix
only when asked. The developer owns the quality decision; the report informs
it.

## Severity guide

**Critical — fix before moving on**

- Architecture boundary violations that will break future features
- Missing error handling that causes silent failures
- Functionality that was planned but completely missing

**Important — fix soon**

- Design system drift that will cause UI inconsistency
- Code standard violations that will compound across the codebase
- Edge cases that a real user will encounter

**Minor — fix when convenient**

- Naming inconsistencies that do not affect behaviour
- Missing optimisations
- Style issues that do not affect the design system
