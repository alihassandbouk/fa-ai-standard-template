# Catalogue: which DGA component for which job

Every component is a named export of `platformscode-new-react`. The group
reference has its usage; the full prop list is the component's interface in
`node_modules/@platformscode/core/dist/types/components.d.ts` and the
Storybook page `Components/<name>`.

## Forms, in `forms.md`

Every form component calls its handler props unguarded; pass each one.

- **DgaTextInput** — one-line text, password or number entry.
- **DgaTextarea** — multi-line text.
- **DgaNumberInput** — a number with stepper buttons.
- **DgaSearchBox** — a search field with its own icon and voice input.
- **DgaDropdown** — one or many choices from a list.
- **DgaCheckbox** — one boolean, or one of many.
- **DgaRadioButton** — one of a few choices, all visible.
- **DgaSwitch** — a setting that applies at once.
- **DgaDateField** — a date input with a calendar popup.
- **DgaDatepicker** — the calendar alone, inline.
- **DgaFileUpload** — a drop zone with a file list.
- **DgaSlider** — a number or range by dragging.
- **DgaRating** — stars.
- **DgaLabel**, **DgaHelperText** — a label or helper line for a control that has none.

## Actions, in `actions.md`

- **DgaButton** — an action.
- **DgaLink** — navigation to a URL.
- **FloatingButton** — one prominent action floating over the page.
- **DgaChip** — a selectable pill, for filters.
- **DgaMenuList** > **DgaMenuGroup** > **DgaMenuItem** — a list of actions.
- **DgaMenu**, **DgaActionMenu** — the popover that holds a menu list.
- **DgaIcon** — an icon from the DGA set.
- **DgaFeaturedIcon** — an icon in a coloured tile, for modal and card headers.

## Navigation, in `navigation.md`

- **DgaNavHeader** and its parts — the site header.
- **DgaSecondNavHeader** — a second bar under the header, for the current section.
- **DgaFooter** — the site footer.
- **DgaBreadcrumbs** — the path to the current page.
- **DgaTabs** — switch between views of one thing.
- **DgaContentSwitcher** > **DgaContentSwitcherItem** — a segmented control for a few short views.
- **DgaPagination** — page through a long list.
- **DgaDrawer** — a side navigation tree.
- **DgaSlideoutMenu** and its parts — a panel that slides in from the edge.
- **DgaTableOfContent** — in-page section links.
- **DgaProgressIndicator** > **DgaProgressIndicatorStep** — the steps of a wizard.
- **DgaRadialStepper** — the same as a ring.

## Data display, in `data-display.md`

- **DgaDataTable** — rows and columns with sort, filter and row selection.
- **DgaStructuredList** — a read-only table without the table chrome.
- **DgaFilteration** — a filter panel with blocks of options and a result event.
- **DgaListV2** > **DgaListItem** — ordered, unordered or icon-led lists.
- **DgaCard** — a titled block with an optional image, icon and two actions.
- **DgaCardV2** — a card shell for arbitrary content.
- **DgaAccordion** — a collapsible section with its own header.
- **DgaCollapse** — a collapsible region the project toggles.
- **DgaTag** — a read-only label.
- **DgaStatusTag** — the state of a record.
- **DgaAvatar**, **DgaAvatarGroup** — a person, or several.
- **DgaMetric** — one KPI with trend and sparkline.
- **DgaChart** — line, bar, pie and the rest, over ApexCharts.
- **DgaQuote** — a pull quote.
- **DgaCodesnippet** — code with a copy button.
- **DgaCarousel** > **DgaCarouselItem** — slides.
- **DgaDigitalSignature** — the digital stamp block.

## Feedback, in `feedback.md`

- **DgaModal**, **DgaModalV2** — a dialog that blocks the page.
- **DgaInlineAlert** — a message inside the page that the reader must act on.
- **DgaNotification** — a banner across the page.
- **DgaNotificationToast** — a transient message in a corner.
- **DgaTooltip** — a hint on hover or focus.
- **DgaLoading** — a spinner.
- **DgaLinearProgressBar**, **DgaCircularProgressBar** — determinate progress.
- **DgaLineSkeleton**, **DgaRectangleSkeleton**, **DgaCircleSkeleton**, **DgaSquareSkeleton** — placeholders while loading.

## Layout, in `layout.md`

- **DgaGridContainer** > **DgaGridItem** — the 12-column grid.
- **DgaFlex** — a row or column with spacing.
- **DgaDivider** — a line between sections.

## Not in the set

Toggle group, stepper input with units, colour picker, rich-text editor,
map, calendar view, tree view, timeline, kanban: the gap rule in `rules.md`.
