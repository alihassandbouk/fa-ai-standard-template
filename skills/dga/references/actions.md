# Actions

## Button

```tsx
<DgaButton label={t('actions.submit')} variant="primary-brand" size="md" onOnClick={submit} />
<DgaButton label={t('actions.cancel')} variant="secondary-outline" onOnClick={close} />
<DgaButton
  label={t('actions.create')}
  leadIconType="add-01"
  leadIconProps={{ variant: 'stroke', size: 16 }}
/>
<DgaButton iconOnly iconType="cancel-01" label={t('actions.close')} variant="transparent" />
<DgaButton label={t('actions.delete')} variant="des-primary" />
```

- The label is a prop; the component has no children. With `iconOnly` the
  label is not drawn and becomes the button's accessible name.
- Click is the custom event `onClick`, exposed to React as `onOnClick`.
- `variant`: `primary-brand` for the one primary action of an area,
  `primary-neutral` (default), `secondary`, `secondary-outline`, `subtle`,
  `transparent`; the destructive set is the same list prefixed `des-`.
- `size`: `lg`, `md` (default), `sm`. `onColor` on a brand-filled surface.
- Icons by name: `leadIconType` or `trailIconType` is the icon file name
  without its variant suffix; `leadIconProps` or `trailIconProps` sets
  `variant` (`stroke` or `solid`) and `size`. `leadIcon` and `trailIcon`
  booleans are deprecated.
- `type` is `button` by default, so a button submits a form only through
  its handler; see `forms.md` *Submit*.

## Link

```tsx
<DgaLink label={t('nav.dashboard')} url="/dashboard" variant="primary" size="md" />
<DgaLink label={t('nav.dga')} url="https://dga.gov.sa" target="_blank" />
```

`inline` for a link inside a sentence. For a router, `url` plus `state` and
`preventScrollReset` are forwarded; the link emits `ndsClick` as `onNdsClick`
for intercepting navigation.

## Icon

```tsx
<DgaIcon name="arrow-right-01" variant="stroke" size={20} flipRtl />
```

- `name` is a file in `node_modules/@platformscode/icons/dist/svg/` without
  the `-stroke` or `-solid` suffix; the typed list is
  `node_modules/@platformscode/icons/dist/types/icon-names.d.ts`. The files
  are served from `public/assets/svg/` per `setup.md` step 3; a missing
  copy renders the icon blank.
- `variant` is `stroke` or `solid`; `size` a number of pixels or a token
  from `2xs` to `2xl`. `color` is a CSS colour, so a DGA variable.
- `flipRtl` for icons that point along the reading direction.
- `DgaFeaturedIcon` wraps an icon in a coloured tile for modal and card
  headers: `icon={{ name, variant, size }}`, `color`, `variant` (`light`,
  `dark`, `outlined`), `size`.

## Menu

```tsx
<DgaMenu open={open} anchorEl={anchor} onClose={() => setOpen(false)}>
  <DgaButton slot="trigger" label={t('actions.more')} onOnClick={() => setOpen(true)} />
  <DgaMenuList slot="menu">
    <DgaMenuGroup groupLabel={t('menu.manage')}>
      <DgaMenuItem label={t('actions.edit')} hasLeadIcon onOnClick={edit}>
        <DgaIcon slot="lead-icon" name="edit-02" variant="stroke" size={20} />
      </DgaMenuItem>
    </DgaMenuGroup>
    <DgaDivider />
    <DgaMenuGroup>
      <DgaMenuItem label={t('actions.delete')} onOnClick={remove} />
    </DgaMenuGroup>
  </DgaMenuList>
</DgaMenu>
```

Slots are named with the `slot` attribute on the child. `DgaMenuList` alone
renders an always-open list, for a side panel. `DgaActionMenu` with `open`,
`placement`, `onClose` is the popover for a row's actions.

## Chip and floating button

- `DgaChip` with `label`, `isSelected`, `onChange(isSelected)`, `variant`,
  `size`, icons as `leadIcon` name plus `leadIconProps`.
- `FloatingButton` with `label`, `icon`, `iconOnly`, `RTL` from the locale,
  click as `onButtonClick`. One per page at most.
