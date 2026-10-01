# Feedback

## Modal

```tsx
<DgaModal
  name="confirm-delete"
  open={open}
  modalTitle={t('delete.title')}
  featuredIconProps={{ size: 'md', color: 'error', variant: 'light', icon: { name: 'alert-02', variant: 'stroke', size: 20 } }}
  buttonsList={[
    { id: 'cancel', label: t('actions.cancel'), onClick: close },
    { id: 'delete', label: t('actions.delete'), onClick: remove },
  ]}
  onClose={close}
  position="center"
>
  {t('delete.body', { name })}
</DgaModal>
```

- `name` is required and unique on the page. The body is the children.
- `staticModal` keeps it open on backdrop click. `position` `start` or
  `end` makes it a side sheet.
- `DgaModalV2` is the same composed from `DgaModalHeader` (a
  `DgaFeaturedIcon` and a `DgaModalTitle`), `DgaModalBody` and
  `DgaModalActions` holding `DgaButtonV2` children (`label`, `variant`,
  click as `onOnClick`), for a body that is more than text.
- Test each modal once with the keyboard: focus lands inside on open and
  returns to the trigger on close.

## Inline alert

```tsx
<DgaInlineAlert
  type="error"
  leadText={t('publish.refused')}
  helperText={t('publish.refusedHelp')}
  isactionButtons
  buttonsList={[{ label: t('actions.fix'), onClick: goToErrors }]}
  isCloseButton={false}
/>
```

`type`: `neutral`, `info`, `error`, `success`, `warning`. `isactionButtons`
and `isCloseButton` default to true; turn them off for a message with no
action.

## Notification and toast

```tsx
<DgaNotification variant="warning" leadText={t('maint.title')} content={t('maint.body')} dismissable link textLink={t('maint.more')} navigateTo={(url) => navigate(url)} />

<DgaNotificationToast type="success" open={saved} leadText={t('saved')} vPostion="top" hPostion="right" closeButton onClose={() => setSaved(false)} />
```

`DgaNotification` variants: `critical`, `warning`, `success`, `info`,
`neutral`. The toast's `hPostion` is physical (`left`, `right`), so pick it
from the locale: `right` in RTL means the reading-start corner.

## Tooltip

```tsx
<DgaTooltip tooltipTitle={t('help.id')} helperText={t('help.idBody')} direction="top">
  <DgaButton iconOnly iconType="help-circle" label={t('help.id')} variant="transparent" />
</DgaTooltip>
```

The trigger is the child.

## Loading and progress

- `DgaLoading` with `size` (`tiny`, `xs`, `sm`, `md`, `lg`, `xl`, `huge`)
  and `variant` (`neutral`, `brand`, `on-color`) while a region loads.
- Skeletons where the shape of the content is known, each with `type`
  `'1'` or `'2'`: `DgaLineSkeleton` (`size` `sm` or `lg`),
  `DgaRectangleSkeleton` (`size`, `width` `short` or `long`),
  `DgaCircleSkeleton` and `DgaSquareSkeleton` (`width` as a pixel token
  from `24px` to `240px`).
- `DgaLinearProgressBar` with `percentage`, `label`, `helperText`,
  `progressStyle`, `size`, `RTL` from the locale.
- `DgaCircularProgressBar` with `percentage`, `text`, `variant`, `size`
  (`64px` to `200px`), `RTL` from the locale.
