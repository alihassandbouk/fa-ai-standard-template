# Forms

Controlled inputs: hold the value in React state, feed it back through
`value`, read changes from the handler. Every handler prop a component
declares is passed, even as `() => {}`: `DgaTextInput` calls `onBlur`,
`DgaNumberInput` calls `onBlur` and `onChange`, `DgaDropdown` calls
`onChange`, all unguarded, and throw when the prop is missing.

## Text, number, textarea, search

```tsx
const [name, setName] = useState('');

<DgaTextInput
  label={t('form.name')}
  name="name"
  value={name}
  placeholder={t('form.namePlaceholder')}
  required
  error={!!errors.name}
  helperText={errors.name}
  feedbackIcon={!!errors.name}
  feedbackIconType="error"
  onInput={(e) => setName((e?.target as HTMLInputElement).value)}
  onChange={() => {}}
  onBlur={() => {}}
/>
```

- `onInput` fires per keystroke, `onChange` on commit; both receive the
  native event.
- `size` is `lg` by default; `md` for dense forms. `variant` `lighter` or
  `darker` for tinted surfaces.
- Prefix and suffix content go in the `prefix` and `suffix` slots:
  `<span slot="prefix">+966</span>`.
- `DgaNumberInput` holds a number in `value`. `DgaTextarea` has `rows`,
  `resize`, `error` and the feedback icon props, and no label or helper of
  its own: pair it with `DgaLabel` and `DgaHelperText`.
- `DgaSearchBox` reads typing through `onInput`; its commit and blur are
  events, `onOnChange` and `onOnBlur`. `speechLang` comes from the locale.
- An input that always holds left-to-right data gets `dir="ltr"`.

## Choice

```tsx
<DgaDropdown
  label={t('form.city')}
  placeholder={t('form.pick')}
  options={cities}            // [{ label, value }]
  optionLabel="label"
  trackBy="value"
  value={city}
  onChange={(v) => setCity(v as string)}
/>
```

- `multiSelect` makes `value` and the `onChange` argument `string[]`.
- `DgaCheckbox`: `checked`, `label`, `helperText`, `onChange(e)` with
  `e.target.checked`. `Indeterminate` for a parent of a partly selected group.
- `DgaRadioButton`: one element per option, the same `name` on all,
  `checked={value === option}`, `value={option}`.
- `DgaSwitch`: `checked`, `label`, `onChange`.
- `DgaChip` with `isSelected` and `onChange(isSelected)` for filter toggles.

## Dates

```tsx
<DgaDateField
  label={t('form.date')}
  value={date ? format(date) : ''}
  onChange={(d) => setDate(d)}          // Date | null
  datepickerOptions={{ onSubmit: () => {}, onCancel: () => {}, range: false }}
/>
```

`onSubmit` and `onCancel` inside `datepickerOptions` are required by the
type. The Hijri form goes next to the field per `rules.md` *Dates*.
`DgaDatepicker` is the inline calendar, with `RTL` from the locale.

## Files

`DgaFileUpload` with `accept`, `actionName` (the button label, translated),
`emitDeleteFile`. Upload handling is the project's; the component collects
and lists the files.

## Submit

A button inside the component's shadow DOM is not part of the page's
`<form>`, so `type="submit"` does not submit it. Submit from the handler:

```tsx
<form onSubmit={(e) => { e.preventDefault(); submit(); }}>
  …
  <DgaButton label={t('actions.save')} variant="primary-brand" onOnClick={submit} />
</form>
```

Keep the submit button enabled when the form is invalid; clicking it shows
the errors on the fields. `disabled` is for an action that is impossible.
