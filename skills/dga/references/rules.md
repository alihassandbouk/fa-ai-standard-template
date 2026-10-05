# Rules: direction, dates, numerals, accessibility, composition, gaps

The rules themselves are in `context/ui-rules.md`. This file is how each
one is applied in code.

## Direction props

These components take their own direction and are passed it from the
current locale: `DgaDatepicker RTL`, `DgaRadialStepper RTL`,
`DgaLinearProgressBar RTL`, `DgaCircularProgressBar RTL`, `DgaStatusTag RTL`,
`FloatingButton RTL`, `DgaCarousel Dir`, `DgaRating direction`,
`DgaTableOfContent rtl`, `DgaSearchBox speechLang`, `DgaDigitalSignature language`.
Every other component follows `document.documentElement.dir`.

## Direction in product code

- Logical Tailwind utilities: `ms-*` `me-*` `ps-*` `pe-*` `start-*` `end-*`
  `text-start` `text-end` `border-s` `border-e` `rounded-s-*` `rounded-e-*`,
  and `gap-*` in place of `space-x-*`.
- Icons that mean "next in reading order" (chevrons in pagination,
  breadcrumbs, back and next) get `flipRtl` on `DgaIcon`. Icons that mean a
  physical direction or are a brand mark keep their orientation.
- An input that always holds left-to-right data (email, URL, IBAN, phone)
  gets `dir="ltr"` on the field; its label inherits the page direction.
- Content of unknown direction (user text, search results) gets `dir="auto"`.
- A flex or grid column holding an Arabic and an English string of the same
  value gets `items-start`, or the two strings fly to opposite edges.

## Dates

`DgaDateField` and `DgaDatepicker` are Gregorian, so the Hijri form is
rendered next to the field or in the display text:

```ts
new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura', { dateStyle: 'long' }).format(date)
// ٢٠ ذو القعدة ١٤٤٧ هـ
new Intl.DateTimeFormat('ar-SA', { dateStyle: 'long' }).format(date)
// ٢٤ أبريل ٢٠٢٦
```

Display pattern: `٢٠ ذو القعدة ١٤٤٧ هـ (٢٤ أبريل ٢٠٢٦ م)`. `islamic-umalqura`
is the Saudi government calendar; it is the only Hijri conversion to use.

## Numerals

- Counts, amounts and dates in the Arabic locale:
  `new Intl.NumberFormat('ar-SA-u-nu-arab').format(n)`.
- IBANs, national IDs, phone numbers, version numbers and codes:
  `new Intl.NumberFormat('ar-SA-u-nu-latn')`, or the raw string with
  `dir="ltr"`.
- Numbers in table columns: `tabular-nums`.

## Accessibility (WCAG 2.1 AA, both languages)

- Colour is never the only signal: an error carries an icon and text, a
  success carries a check and text. `feedbackIcon` + `feedbackIconType` on
  inputs, `type` on alerts.
- Touch targets are 44×44px or larger. An icon-only `DgaButton` gets its
  accessible name from `label`, which it renders as the inner `aria-label`.
- Tab order is DOM order: author the DOM in reading order and leave CSS
  `order` alone.
- `DgaLink` for navigation, `DgaButton` for actions.

## Composition

- One primary action per area (`variant="primary-brand"`), at the end of
  the action group; its companion is `secondary-outline`.
- A standing note, a counter, a save confirmation or "this draft is not
  finished" is plain text; `DgaInlineAlert` is for something the reader
  must act on now.

## Gaps

A component DGA lacks is built in the project with the DGA variables, all
on `:root` from the DGA stylesheet (`--colors-…`, `--spacing-…`,
`--radius-…`, `--shadow-…`), listed by:

```bash
grep -o -- '--[a-z][a-z0-9-]*' node_modules/@platformscode/core/dist/core/core.css | sort -u
```

It is recorded in `context/ui-patterns.md` so the next screen reuses it.
