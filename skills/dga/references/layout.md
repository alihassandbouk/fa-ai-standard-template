# Layout

The DGA grid and flex build the page skeleton; Tailwind utilities arrange
everything inside it, with the logical utilities from `rules.md`.

## Page skeleton

```tsx
<a href="#main" className="sr-only focus-visible:not-sr-only focus-visible:fixed focus-visible:top-2 focus-visible:start-2">{t('a11y.skipToMain')}</a>
<DgaNavHeader …>…</DgaNavHeader>
<main id="main" className="mx-auto max-w-7xl px-4 md:px-8 py-8 flex flex-col gap-8">
  <DgaBreadcrumbs items={crumbs} />
  <h1 className="text-2xl font-semibold">{title}</h1>
  <Outlet />
</main>
<DgaFooter …/>
```

## Grid

```tsx
<DgaGridContainer gap="16px">
  <DgaGridItem xs={12} md={8}><Details /></DgaGridItem>
  <DgaGridItem xs={12} md={4}><Summary /></DgaGridItem>
</DgaGridContainer>
```

Twelve columns; `xs`, `sm`, `md`, `lg`, `xl` set the span per breakpoint,
`order*` the order, `fluid` and `disableGutters` on the container. The grid
follows the document direction.

## Flex

```tsx
<DgaFlex direction="row" spacing={16} align="center" justify="between" wrap>
  …
</DgaFlex>
```

Use `DgaFlex` or Tailwind's `flex` utilities, one of them consistently per
file.

## Tailwind

- Spacing `gap-*`, `p-*`, `m-*`; widths `max-w-*`; responsive prefixes
  `md:`, `lg:`; typography on plain text (`text-sm`, `font-semibold`,
  `leading-*`).
- A colour, radius, shadow or font on a locally built element is a DGA
  variable, as an arbitrary value: `text-[var(--colors-text-…)]`.
- `DgaDivider` between sections, `orientation="vertical"` inside a flex row
  with a height.
