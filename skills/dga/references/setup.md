# Setup: DGA in a React project

Run once per project, on the first `/fa:dga` call. Each step ends with a
check; stop at the first that fails. Vite and Next.js differ only where a
step says so.

## 1. Install

```bash
npm install platformscode-new-react
npm install -D eslint typescript-eslint
```

Check: `node_modules/@platformscode/core` and `node_modules/@platformscode/icons`
exist.

## 2. Register once, before the first render

The base URL for assets is the site root: components request
`assets/svg/<name>-<variant>.svg` relative to it. (DGA's own guide says
`/assets/`, which doubles the segment and leaves every icon blank.) The
adapter imports the DGA stylesheet and registers each element on first
render, so this is the whole bootstrap.

Vite, in `src/main.tsx` above the render call:

```tsx
import { setAssetPath } from '@platformscode/core/dist/components/index.js';

setAssetPath(`${window.location.origin}/`);
```

Next.js, a client module rendered once from `app/layout.tsx`; the guard
keeps the server pass away from `window`:

```tsx
// app/dga-setup.tsx
'use client';
import { setAssetPath } from '@platformscode/core/dist/components/index.js';

if (typeof window !== 'undefined') setAssetPath(`${window.location.origin}/`);

export default function DgaSetup() { return null; }
```

Every DGA component is client-only (`'use client'`, no server rendering),
so each one renders inside a client component; where the boundary sits is
the project's choice.

Check: `grep -rn setAssetPath src app` prints exactly one call.

## 3. Serve the icons

Icons are fetched at runtime from `/assets/svg/<name>-<variant>.svg`, so
the package's assets are copied into the folder the app serves at `/`
(`public/` in Vite and Next.js). `scripts/copy-dga-assets.mjs`:

```js
import { cpSync } from 'node:fs';
cpSync('node_modules/@platformscode/core/dist/collection/assets', 'public/assets', { recursive: true });
cpSync('node_modules/@platformscode/icons/dist/svg', 'public/assets/svg', { recursive: true });
```

In `package.json`:

```json
"copy-dga-assets": "node scripts/copy-dga-assets.mjs",
"postinstall": "npm run copy-dga-assets"
```

Then once now, `npm run copy-dga-assets`, and `public/assets/` goes in
`.gitignore`. A CI job that installs with `--ignore-scripts` runs
`npm run copy-dga-assets` as its own step, or icons are blank with only a
404 in the network tab. The svg folder is 36 MB; once the app's icon names
are known, copy those files instead of the folder.

Check: `ls public/assets/sprite.svg public/assets/svg | head -3` prints the
sprite and svg files.

## 4. Vite only

In `vite.config.ts`:

```ts
optimizeDeps: { exclude: ['@platformscode/core'] },
```

Without it Vite pre-bundles the component entry files and the browser
requests them from a cache path that does not exist. After adding it:
`rm -rf node_modules/.vite`. Next.js needs no equivalent.

Check: `npm run dev` serves a page with a `<DgaButton label="…" />` drawn
as a filled, rounded DGA button, not an unstyled label.

## 5. Document direction

`<html lang="ar" dir="rtl">` in `index.html` (Vite) or on the `<html>`
element in `app/layout.tsx` (Next.js). Arabic is the primary language. A
language switch sets both attributes on `document.documentElement`; the
components follow the document direction, except the ones listed under
*Direction props* in `rules.md`.

Check: the DGA button's label and icon read right to left.

## 6. Tailwind

Tailwind v4 with `@tailwindcss/vite` or `@tailwindcss/postcss`, and this as
the entry CSS:

```css
@import "tailwindcss" important;

/* DGA sets html { font-size: 62.5% }; its CSS is px-based, Tailwind's is rem-based. */
:root { font-size: 100%; }
```

The `important` flag is required: the DGA stylesheet carries an unlayered
reset, and unlayered CSS beats Tailwind's layered utilities whatever the
specificity. Tailwind v3: `important: true` in `tailwind.config.js` and the
same `:root` rule. Component internals live in shadow DOM; neither
stylesheet reaches them.

Check: `<main className="mx-auto max-w-md p-6">` is centred with 24px of
padding. Failing looks like a full-width block hugging the start edge with
no padding, and `max-w-md` measuring 280px instead of 448px.

## 7. Lint

`eslint.config.js`, a flat config; a project that already has one adds the
two objects to its array:

```js
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { files: ['src/**/*.tsx'], languageOptions: { parser: tseslint.parser, parserOptions: { ecmaFeatures: { jsx: true } } } },
  {
    files: ['src/**/*.tsx'],
    rules: {
      'no-restricted-syntax': [
        'error',
        {
          selector: 'JSXOpeningElement[name.name=/^(button|input|select|table|dialog)$/]',
          message: 'Use the DGA component from platformscode-new-react (see /fa:dga).',
        },
      ],
    },
  },
);
```

`"lint": "eslint src"` in `package.json`. The Vite template's oxlint script
ignores selector rules, so the lint script runs ESLint. A legacy
`.eslintrc.*` takes the same rule under `overrides` for `*.tsx` with
`@typescript-eslint/parser`.

Check: a file containing `<button />` makes `npm run lint` fail with the
message above.

## Bundle

The adapter is one module that registers all 161 components as a side
effect, so the DGA code is one 4.1 MB chunk (660 kB gzip) however few
components a page imports, and route-level code splitting leaves it whole.
Budget for it in the bundle check; a public page that cannot carry it is a
gap to raise with DGA.
