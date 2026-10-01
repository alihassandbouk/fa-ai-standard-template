# UI Rules

**Function:** Describes the design system this project uses and the UI rules
every screen must satisfy. Loaded every session; `/fa:imprint` verifies new UI
against this file. Present-tense only.

---

## Design system

DGA Platforms Code, the Saudi national design system, through its React
adapter `platformscode-new-react`. `/fa:dga` sets it up on the first UI
session and holds the how-to; lint rejects a raw `button`, `input`,
`select`, `table` or `dialog` in product code.

## Rules

Edit to match the project. These are the FA defaults.

- Every visual element is a DGA component. Tailwind arranges them (layout,
  spacing, responsive behaviour) and styles nothing that has a colour.
- A job DGA has no component for is built in the project with DGA's CSS
  variables and recorded in `context/ui-patterns.md`, so it is built once.
- Every colour, spacing, type, radius, shadow and motion value in product
  code is a DGA variable, including inline styles and computed values.
- Logical CSS properties and utilities only (`ms-*`, `pe-*`, `start-*`).
- Arabic is the primary language and `dir="rtl"` the default direction.
  Every user-facing string goes through the translation layer, Arabic and
  English both present.
- Order, icons and directionality behave in RTL and LTR; a component with
  its own direction prop gets it from the locale.
- Dates show Hijri (Umm al-Qura) alongside Gregorian. Counts and amounts use
  Arabic-Indic numerals in Arabic; IDs, IBANs and phone numbers stay Latin.
- The right component for the job per `context/ui-patterns.md`: inline
  alert for something to act on, toast for a transient confirmation,
  notification for a page-wide notice, modal for a blocking decision, tag
  for a read-only label, chip for a selectable one.

## Consistency enforcement

Run `/fa:imprint` after building any UI. It verifies the screen against the
rules above and records its composition in `context/ui-patterns.md`.
