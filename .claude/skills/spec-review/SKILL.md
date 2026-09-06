---
name: spec-review
description: Critique a spec before it goes to Gate A. Checks every requirement for EARS wording, testable done criteria, unique IDs, and clean scope — then reports what would block approval. Run it on any file in specs/ before asking the product owner to sign off.
---

A spec is the cheapest place to catch a problem. The same ambiguity that costs one sentence to fix here costs a rework cycle after implementation. This skill reads a spec the way a hostile-but-fair reviewer would — before a human spends approval on it.

## What This Skill Does Not Do

It does not rewrite the spec. It reports what it finds, ranked by severity, and lets the developer decide. It can draft fixes — but only when asked, and one requirement at a time.

---

## How to Invoke

```
/spec-review specs/<capability>.md
```

If no file is given, list the files in `specs/` and ask which one to review.

---

## Step 1 — Load the Benchmark

Before reading the spec, know what the spec must answer to:

- **The non-negotiables in `CLAUDE.md` are already loaded** — use them; do not re-read the file.
- **Read `docs/adr/`** — this is not loaded by default. Titles and status lines are enough.
- The source document reference the spec claims (BRD / HLR IDs), if available and not already in context.

Do not review a spec in a vacuum. A requirement can be perfectly worded and still contradict an accepted ADR or a non-negotiable — that is a blocking finding.

## Step 2 — Check Every Requirement

Go requirement by requirement. For each one, check:

**Identity**
- Has an ID in the agreed format (`HLR-###`), unique within the spec
- Carries Priority (Must / Should / Could) and Phase (MVP / Phase 2)
- Traces to a source (BRD/HLR ID) where one exists

**Wording — EARS shape**
- Fits one of: `WHEN … the system SHALL …` / `IF … THEN the system SHALL …` / `WHILE … the system SHALL …` / `The system SHALL …`
- One requirement per sentence. An "and" joining two behaviours is two requirements.
- No vague words. Flag every instance of: *fast, easy, simple, user-friendly, appropriate, properly, seamless, robust, flexible, etc., and so on, as needed, if necessary.*
- Measurable where a number is implied. "Quickly" is a finding; "within 5 minutes" is a requirement.

**Done criteria**
- Every **Must** requirement has at least one Given / When / Then scenario
- Each scenario is executable in principle — a test could be written from it without asking anyone anything
- Edge behaviour is covered where the requirement implies it: the duplicate event, the expired token, the second submission, the empty result
- For anything user-facing: Arabic and English behaviour is stated, not assumed

**Scope discipline**
- The spec says **what**, never **how**. Any mention of a library, framework, queue, or table design is architecture leaking in — it belongs in an ADR or the plan. (Naming a non-negotiable as a constraint reference is fine; designing with it is not.)
- No status. "Already built" / "in progress" belongs in Jira.
- No history. "Previously this worked differently" belongs in an ADR.

**Consistency**
- No requirement contradicts another requirement, an accepted ADR, or a non-negotiable
- Terms are used consistently — if "respondent" and "participant" both appear, either they are two defined roles or one of them is wrong

## Step 3 — Report

```
## Spec Review — specs/<file>.md

Requirements: [N] total · [X] Must/MVP
Done criteria coverage: [X of Y] Must requirements covered

### Blocking (fix before Gate A)
- HLR-0XX — [finding, one line, with the exact wording quoted]

### Should fix
- HLR-0XX — [finding]

### Minor
- [finding]

### Verdict
[READY FOR GATE A — no blocking findings]
[NOT READY — [N] blocking findings above]
```

Severity guide:

- **Blocking** — a Must without done criteria, vague wording in a Must, a contradiction with an ADR or non-negotiable, a missing or duplicate ID, architecture in the spec.
- **Should fix** — vague wording in a Should/Could, missing edge-case scenario, missing AR/EN statement on a user-facing requirement, inconsistent terms.
- **Minor** — style, ordering, formatting.

Quote the exact words you are flagging. "HLR-052 is vague" helps nobody; "HLR-052 says *'the system responds appropriately'* — appropriate is not testable" fixes itself.

## Step 4 — Let the Developer Decide

Stop after the report. Do not rewrite anything.

If the developer asks for fixes, draft them **one requirement at a time**, showing before and after:

```
HLR-052 — before:
  The system responds appropriately to invalid tokens.

HLR-052 — proposed:
  IF an evaluation token is expired, invalid, or already used,
  THEN the system SHALL show the link-expired page and SHALL NOT
  reveal whether the token ever existed.

  Done means:
  GIVEN a token that was already used
  WHEN the respondent opens the link
  THEN the expired page is shown and no survey data is returned
```

The developer accepts, edits, or rejects each one. Accepted changes go into the spec through its normal PR — this skill never edits `specs/` directly.

---

## The Standard

Gate A spends a human's attention. This skill exists so that attention goes to judging intent — *is this what the business wants?* — not to catching missing done criteria that a checklist would have found.

A spec passes when a test could be written from every Must requirement without asking a single question. That is the bar.