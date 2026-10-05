# Navigation

## Site header

```tsx
const [collapsed, setCollapsed] = useState(true);

<DgaNavHeader fullWidth divider sticky>
  <DgaNavHeaderMain collapsed={collapsed} onToggleCollapsed={() => setCollapsed(!collapsed)}>
    <DgaNavHeaderLogos logoSrc={logo} logoLink="/" govSrc={govLogo} govLink="https://my.gov.sa" logoAlt={t('brand')} govAlt={t('gov')} />
    <DgaNavHeaderMenu>
      <DgaNavHeaderLink label={t('nav.services')} active={path.startsWith('/services')} icon="arrow-down-01" subMenuFullWidth subMenuBackground="white">
        <DgaNavHeaderSubMenu background="white">
          <DgaNavHeaderSubMenuColumn label={t('nav.individuals')}>
            <DgaNavHeaderSubMenuLink label={t('nav.permits')} link="/services/permits" icon="document-validation" helperText={t('nav.permitsHelp')} />
          </DgaNavHeaderSubMenuColumn>
        </DgaNavHeaderSubMenu>
      </DgaNavHeaderLink>
      <DgaNavHeaderLink label={t('nav.about')} active={path === '/about'} />
    </DgaNavHeaderMenu>
    <DgaNavHeaderActions>
      <DgaHeaderActionBtn icon="search-01" label={t('actions.search')} onClick={openSearch} />
      <DgaButton label={t('actions.signIn')} variant="primary-brand" size="sm" onOnClick={signIn} />
    </DgaNavHeaderActions>
  </DgaNavHeaderMain>
</DgaNavHeader>
```

- The parts nest in this order. `onToggleCollapsed` is the `toggleCollapsed`
  event; `DgaNavHeaderLink` emits `linkClicked` as `onLinkClicked`.
- `DgaSecondNavHeader` sits under the header for the current section:
  items in the `content` slot, buttons in the `actions` slot,
  `variant`, `hideDivider`.
- `DgaFooter` takes its links as arrays: `basicLinks` of `{ name, target }`,
  `groupLinks`, `socialMediaLinks`, `accessibilityLinks` of
  `{ title, target, icon }`, plus `copyright`, `mainTitle`, `mainDescription`,
  `mainImage`, `bottomImages`.

## Within the page

```tsx
<DgaBreadcrumbs items={[{ label: t('nav.home'), path: '/' }, { label: t('nav.permits'), path: '/permits' }, { label: permit.title, path: location.pathname }]} max={4} />
```

Breadcrumb clicks arrive as `onBreadcrumbClick`.

```tsx
<DgaTabs
  orientation="horizontal"
  size="md"
  tabsList={[
    { label: t('tabs.details'), tabIcon: 'file-01', iconProps: { variant: 'stroke' }, onClick: () => setTab('details') },
    { label: t('tabs.history'), onClick: () => setTab('history') },
  ]}
/>
{tab === 'details' ? <Details /> : <History />}
```

The tabs render the strip; the panel is the project's, switched on the state
the `onClick` sets. `DgaContentSwitcher` with `DgaContentSwitcherItem`
children (`label`, `content`) renders both the control and its panels.

```tsx
<DgaPagination currentPage={page} totalPageCount={pages} siblingCount={1} size="medium" onChange={setPage} />
```

## Side navigation

- `DgaDrawer` with `routes`: `{ name, path, icon: { name, variant, size }, badge, children, disabled }`, `anchor`, `open`, `background`.
- `DgaSlideoutMenu` with `open`, `onClose`, `anchor`: a `DgaSlideoutMenuHeader` (`title`, `description`), a `DgaSlideoutMenuItems` holding `DgaMenuGroup` and `DgaMenuItem`, a `DgaSlideoutMenuActions` holding buttons.
- `DgaTableOfContent` with `sections`, `tocTitle`, `rtl` from the locale, for long reading pages.

## Wizard steps

```tsx
<DgaProgressIndicator activeStep={step} alignment="horizontal">
  <DgaProgressIndicatorStep currentStep={1} title={t('steps.applicant')} description={t('steps.applicantHelp')} />
  <DgaProgressIndicatorStep currentStep={2} title={t('steps.documents')} />
  <DgaProgressIndicatorStep currentStep={3} title={t('steps.review')} />
</DgaProgressIndicator>
```

Each step carries its own number in `currentStep`, counted from 1, and
`activeStep` on the parent names the current one. Step changes arrive as
`onStepChange`. `DgaRadialStepper` shows the same as
a ring with `steps` of `{ text, stepName, stepDescription }` and `RTL`.
