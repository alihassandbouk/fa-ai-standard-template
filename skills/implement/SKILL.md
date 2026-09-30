---
name: implement
description: Build the work described by a plan from /fa:grill-with-docs, a ticket, or a spec, test-first at the pre-agreed seams, then hand to /fa:review. Use when the design is settled and it is time to write the code.
disable-model-invocation: true
---

# implement

TDD rules adapted from Matt Pocock's `tdd` skill (MIT).

## Inputs

The plan from `/fa:grill-with-docs` if one exists in the conversation, else
the ticket or spec. Read `context/glossary.md` so names match the domain, the
ADRs of the area, and the `AGENTS.md` of every area you touch. If the plan
names no seams, ask for them before writing a test: **no test at an
unconfirmed seam.**

## The loop

One vertical slice at a time, each a tracer bullet through every layer:

1. **Red.** Write one failing test at a seam, named as a capability
   ("user can checkout with a valid cart"). Watch it fail.
2. **Green.** Write only enough code to pass it. No speculative features.
3. Typecheck and run that test file. Repeat with the next slice.

Refactoring is not part of the loop; it belongs to review. Run the full suite
once at the end.

Three test shapes are banned:

- **Implementation-coupled**: mocks internals, tests private methods, checks
  through a side channel. Tell: it breaks on a refactor with no behaviour change.
- **Tautological**: the assertion recomputes the expected value the way the
  code does. Expected values come from an independent source: a literal, a
  worked example, the spec.
- **Horizontal**: all tests first, then all code. That tests imagined
  behaviour. Alternate instead.

## When the plan is wrong

If implementation shows a decision was wrong, stop, say so, and go back to
`/fa:grill-with-docs` for that decision. Do not diverge silently from an ADR.

## Closing

Full suite green, then `/fa:review`. Address what the developer picks from
the report. Commit to the current branch with a message that names the
ticket. `/fa:pr` writes the PR body.
