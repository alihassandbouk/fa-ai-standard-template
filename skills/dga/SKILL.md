---
name: dga
description: Build and review UI in a React project from the official DGA Platforms Code components; sets the package up on the first UI session. Use for any UI work in a React project.
allowed-tools: Read
---

# dga

FA React UI is built from the official DGA component set, the npm package
`platformscode-new-react`. The rules every screen must satisfy are in
`context/ui-rules.md`, already in context. This skill is the how-to.

## Which branch

- No `platformscode-new-react` in `package.json`: `references/setup.md`.
  Done when every step's check passes.
- Building a screen: the steps below.
- Reviewing a screen: the checklist below.

## Build a screen

1. Read `references/rules.md`. Done when the direction props and the date
   and numeral formats are in context.
2. Read `context/ui-patterns.md`. Done when the pattern that matches the
   screen's job is chosen, or its absence noted.
3. Map every element of the design to a component with
   `references/catalogue.md`. Done when every element has a component name
   or is marked a gap.
4. Build each part from the usage in its group reference:
   `references/forms.md`, `actions.md`, `navigation.md`, `data-display.md`,
   `feedback.md`, `layout.md`. A prop the reference does not show is in the
   component's interface in
   `node_modules/@platformscode/core/dist/types/components.d.ts`. Done when
   every component on the screen uses only prop and event names from those
   two sources.
5. Done when lint passes, every string is translated in both languages, the
   screen renders with `dir="rtl"` and `dir="ltr"`, and `/fa:imprint` has
   recorded it.

## Review a screen

Apply every rule in `context/ui-rules.md` and `references/rules.md` to
every file of the screen, and check each component's props against
`components.d.ts`. Done when each rule has been checked against each file
and every finding is reported as `file:line`, the rule, and what the code
does instead.

## Sources

- Storybook, props tables and live rendering of every component:
  https://dga-nds-story-book-695z8.ondigitalocean.app
- Figma, the visual truth; a frame screenshot comes through the Figma MCP:
  https://www.figma.com/community/file/1392264328585493958/components-library-platforms-code
- Design system site: https://design.dga.gov.sa
