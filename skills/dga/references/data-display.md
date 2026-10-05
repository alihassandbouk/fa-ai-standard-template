# Data display

## Table

```tsx
<DgaDataTable
  columns={[{ label: t('table.city') }, { label: t('table.price') }]}
  cells={[
    { title: t('table.city'), propertyName: 'city', type: 'propertyName', isSort: true, isFilter: true, sort: 'up', colSpan: 1 },
    { title: t('table.price'), propertyName: 'price', type: 'propertyName', isSort: true, isFilter: false, colSpan: 1 },
  ]}
  data={rows.map((r) => ({ ...r, selected: false }))}
  showSelectCheckBox
  getSelectedRows={(rows: Row[]) => setSelected(rows)}
  alternate
  rowDivider
  contained
/>
```

- `cells` describes each column: `propertyName` reads the field from each
  row; `type: 'element'` with `El` renders a component in the cell, with
  `elProperties` naming the row fields to pass and `staticProps` the
  constants.
- Every row needs a `selected` field when `showSelectCheckBox` is on.
- Sorting and filtering are signalled, not performed: `sort` marks the
  current state, `pressOnFilter` receives the filter press; the project
  sorts the data and re-renders.
- Numbers in cells: `tabular-nums` and the numeral rules in `rules.md`.
  Page with `DgaPagination` below the table.
- `DgaStructuredList` takes the same `cells` and `data` for a read-only
  key-value or summary list.
- `DgaFilteration` renders a filter panel from `filterBlocks`, with
  `buttonLabel` and `initvalue`, and emits the selection as
  `onOnFilterChange`.

## Cards

```tsx
<DgaCard
  cardTitle={permit.title}
  description={permit.summary}
  showTitle showDescription
  showFeaturedIcon featuredIcon={{ name: 'file-01', variant: 'stroke', size: 24 }}
  showPrimaryAction primaryActionLabel={t('actions.open')} onPrimaryAction={open}
  showSecondaryAction secondaryActionLabel={t('actions.share')} onSecondaryAction={share}
  type="default"
>
  <DgaTag label={t(`status.${permit.status}`)} variant="success" />
</DgaCard>
```

- The named props render the card's own parts; children render below the
  description; the `collapse-content` slot renders behind the expand action
  (`onExpandAction`).
- `isSelected` and `onCheckboxChange` make it a selectable card.
- `DgaCardV2` is the shell for arbitrary content: `card-content` and
  `card-actions` slots, `width`, `minWidth`, `maxWidth`.

## Lists and sections

```tsx
<DgaListV2 type="ordered" color="neutral">
  <DgaListItem type="ordered" level="one" itemNumber="١-" itemText={t('steps.first')} />
  <DgaListItem type="ordered" level="two" itemLetter="أ-" itemText={t('steps.firstA')} />
</DgaListV2>
```

- `type` on the list and on each item: `ordered`, `unordered` or
  `with-icon` (each item then takes `icon`). `level` is `one` or `two`.
  `itemNumber` and `itemLetter` are the printed markers, so they are
  localised strings.
- `DgaAccordion` with `title`, `content`, `defaultExpanded`, `size`,
  `iconAlignment`, `flush`. One per question in an FAQ.
- `DgaCollapse` with `open` for a region the project toggles.

## Labels

```tsx
<DgaTag label={t('tag.new')} variant="info" rounded leadIcon={{ name: 'alert-02', variant: 'stroke' }} />
<DgaStatusTag label={t(`status.${s}`)} color="green" status="subtle" RTL={rtl} />
```

`DgaTag` variants: `neutral`, `success`, `info`, `warning`, `error`,
`on-color`. `DgaStatusTag` colours: `neutral`, `green`, `blue`, `yellow`,
`red`, with `status` `inverted`, `subtle` or `ghost`.

## People

```tsx
<DgaAvatarGroup stacked max={3} total={members.length}>
  {members.map((m) => <DgaAvatar key={m.id} type="image" imgUrl={m.photo} alt={m.name} size={32} />)}
</DgaAvatarGroup>
<DgaAvatar type="initials" text="ع م" size={48} />
<DgaAvatar type="icon" icon={{ name: 'user', variant: 'stroke' }} size={32} />
```

## Numbers and charts

```tsx
<DgaMetric
  label={t('kpi.applications')}
  percentage={formatted}
  trend={{ value: '+٢٥٪', slope: 'positive', description: t('kpi.vsLastMonth') }}
  showChart chartProps={{ data: series, size: 'sm', trend: 'positive', type: 'realistic', showMarker: false }}
/>
<DgaChart type="line" height="320px" width="100%" colors={['var(--colors-primary-sa-flag-600-primary)']}
  series={[{ name: t('chart.applications'), data: [10, 20, 30] }]}
  xaxis={{ categories: months }} />
```

`DgaChart` is ApexCharts: `type`, `series`, `xaxis`, `yaxis`, `labels` for
pie, `options` for anything else ApexCharts accepts. Colours are DGA
variables.

## Content blocks

- `DgaQuote`: `quoteTitle`, `quoteDescription`, `authorName`, `authorDescription`, `avatarSrc`.
- `DgaCodesnippet`: `snippets` as `{ [language]: code }`, `showButton`, `showTabList`.
- `DgaCarousel` with `DgaCarouselItem` children, `arrows`, `showDots`, `Dir` from the locale.
- `DgaDigitalSignature`: `extension`, `language` from the locale, `linkProps`.
