# UI Rules

**Function:** Describes the design system this project uses and the UI rules
every screen must satisfy. Loaded every session; `/fa:imprint` verifies new UI
against this file. Present-tense only.

---

## Design system

_TODO: name/link to the design system package (e.g. `@ds`), and how it's
enforced (lint rules, imports, etc.)._

## Rules

Edit to match the project. These are the FA defaults.

- Everything visual comes from the design system package. No local component
  that duplicates one it has; no raw element doing a component's job (a
  `<button>`, a `<table>`, a hand-built empty state).
- A missing component is a design-system gap: ticket to the design-system
  owner, never a local build.
- No hard-coded colors, spacing, type, radius, shadow or motion, including
  inline styles and computed values.
- Logical CSS properties only; no `left`/`right`.
- No hard-coded user-facing strings. Every string goes through the translation
  layer, Arabic and English both present.
- Order, icons and directionality behave in RTL and LTR.
- The right component for the job per `context/ui-patterns.md`: `Alert` vs
  `Notification` vs `Toast`, `Modal` vs page, `Tag` vs text.

## Consistency enforcement

Run `/fa:imprint` after building any UI. It verifies the screen against the
rules above and records its composition in `context/ui-patterns.md`.
