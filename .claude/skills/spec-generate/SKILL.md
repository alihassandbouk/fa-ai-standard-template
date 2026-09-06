---
name: spec-generate
description: Turn a business document (BRD, HLR, or both) into draft spec files in specs/ — one file per capability, every requirement with an ID, EARS wording, priority, phase, and Given/When/Then done criteria. Produces drafts for human review; the PR that lands them is Gate A. Run /spec-review on the output before asking for sign-off.
---

A business document says what the business wants. A spec says it in a form a test can be written from. This skill does the translation — and refuses to invent anything the source doesn't say.

## What This Skill Does Not Do

It does not decide scope. Where the source is silent, it writes an open question — never a guess dressed as a requirement. And it does not approve anything: the output is a draft, and the PR that lands it is Gate A.

---

## How to Invoke

```
/spec-generate                     # uses the BRD/HLR in project knowledge or context
/spec-generate [path or paste]     # explicit source
/spec-generate --capability "X"    # regenerate or add one capability only
```

---

## Step 1 — Read Everything First

Before writing a single requirement:

- The source documents — BRD and HLR, in full (in a project chat these are usually already in project knowledge)
- The non-negotiables — already loaded via `CLAUDE.md` when running in the repo; read the file only if running outside it
- `docs/adr/` — accepted decisions (titles are enough); not loaded by default, so read it
- `specs/` — what already exists, so IDs are continued, never reused, and existing requirements are never silently rewritten

If both a BRD and an HLR exist and they disagree, stop and list the disagreements before generating. Do not pick a winner silently.

## Step 2 — Propose the Capability Split

A spec file per capability, not one giant file. Propose the split before writing:

```
From the source documents I see [N] capabilities:

1. payment-feedback — [one line: what it covers, which BRD/HLR sections feed it]
2. survey-builder — [...]
3. dashboards — [...]

Sizing rule: a capability should be reviewable in one sitting —
roughly 10–25 requirements. Bigger than that, I split it.

Generate all, or start with one? (all / name)
```

Wait for the developer's choice. Existing spec files keep their boundaries unless the developer says otherwise.

## Step 3 — Generate the Spec

One file per capability: `specs/<capability>.md`, in this exact shape:

```markdown
# Spec — [Capability Name]

Source: BRD §[x], HLR-0XX–0YY · Generated: [date] · Status: draft (pre-Gate A)

## Scope
[2–4 sentences: what this capability covers, and the nearest things it
deliberately does NOT cover.]

## Requirements

### HLR-046 — Invitation on payment
WHEN a payment is completed, the system SHALL send exactly one
evaluation invitation.

Priority: Must · Phase: MVP · Source: BR-004, HLR-046

**Done means:**
GIVEN a payment event is received twice with the same event ID
WHEN the consumer processes both
THEN only one invitation is sent

### HLR-0XX — [next requirement]
...

## Open questions
- [Anything the source is silent or ambiguous on — phrased as a question
  for the product owner, with the requirement ID it blocks]

## Unmapped source content
- BRD §[x] "[quoted sentence]" — [why it did not become a requirement:
  out of scope for this capability / architecture, not behaviour /
  duplicate of HLR-0XX / too vague to translate — needs an answer]
```

Rules while writing:

- **IDs carry over.** A requirement that exists in the source HLR keeps its ID. New requirements continue the numbering — never renumber, never reuse.
- **EARS shape, one behaviour per requirement.** An "and" joining two behaviours becomes two requirements.
- **Priority and phase come from the source.** If the source doesn't say, the requirement gets an open question, not a default.
- **Every Must gets done criteria** — at least one Given/When/Then, edge case included where the requirement implies one (the duplicate event, the expired token, the second submission, the empty state).
- **User-facing requirements state Arabic and English behaviour explicitly.**
- **What, never how.** If the source mandates technology ("must use RabbitMQ"), that is a constraint reference pointing at the non-negotiable/ADR — not a designed solution inside the spec.
- **Nothing invented.** Every requirement lists its source. A requirement with no source is an open question by definition.

## Step 4 — Account for Everything

The Unmapped section is not optional — it is the proof of coverage. Every functional statement in the source must appear in exactly one place: as a requirement, as an open question, or in Unmapped with a reason. If the developer reads the BRD and finds a sentence that appears nowhere, the generation failed.

## Step 5 — Hand Off, Don't Approve

```
Generated specs/<capability>.md:
[N] requirements ([X] Must/MVP) · [Y] open questions · [Z] unmapped items

Next:
1. Run /spec-review on it
2. Resolve open questions with the product owner
3. Open the PR — that review is Gate A
```

Never mark the spec approved. Never create Jira tickets from an unapproved spec.

---

## The Standard

The measure of a generated spec is not that it reads well. It is that the product owner can answer every open question in one meeting, and that a test can be written from every Must requirement without asking anything at all.

Silence in the source is a question, never a guess.