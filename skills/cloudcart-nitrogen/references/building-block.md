# A building block Nitrogen lacks

Stage 2 of the skill, when Nitrogen and the project lack a piece. First make sure the piece really is missing: search both packages' `EXPORTS.md`, the project's `app/components/` and `app/building-blocks/`. Then build it the way Nitrogen builds its own components, so that it can move into Nitrogen as it is.

## Where it lives

```
app/building-blocks/
  LowStockNotice.tsx        the block, its props, and the fragment it reads
  LowStockNotice.test.tsx   its test
```

- One file per block, named after the block in PascalCase, with a named export (no default export).
- Everything the block needs stays in its file: its props type (`<Name>Props`), its parts type, and the fragment for its data. Nothing in the block imports from a route.
- The page imports it from `~/building-blocks/<Name>` and styles it there.

## How it is written

- **Unstyled, with class hooks.** The block renders plain markup with stable classes: `cc-<block>` on its root, and `cc-<block>-<part>` on each part (`cc-low-stock-notice-count`). It takes `classNames`, one class per part, which it adds after its own; a block with only a root may take a plain `className` instead. No Tailwind classes, colours or sizes inside the block: the page passes them in.
- **Data through props,** typed from its fragment: the generated `<FragmentName>Fragment` type in `storefrontapi.generated`. The page's query spreads the fragment. The block never fetches, and never calls the API.
- **Links through props.** A block that links takes the address as a prop (`href: (item) => string`, the page passing `vendorPath`), so it imports nothing from the project; its test renders it inside a `MemoryRouter`.
- **Pictures through `<Image>`,** which sets an inline `width: 100%`: give the picture a box of fixed size and size it with `size-full object-contain`, so a logo or a photo of any shape fits without shifting the layout.
- **Text through props.** The block shows no words of its own: the page passes them from its translations (a render function or `children`). The starter's lint fails on literal text in JSX.
- **Documented.** A doc comment on every export, with its first sentence saying what it is. A prop whose meaning is not obvious from its name gets its own comment.
- **Accessible.** Real elements for their roles (a `<button>` for an action, a list for a list), a label for every control, and keyboard use. Motion respects `prefers-reduced-motion`.

```tsx
import type {LowStockNoticeFragment} from 'storefrontapi.generated';

/** The variant's fields `<LowStockNotice>` reads. Spread it into the query of the page that renders it. */
export const LOW_STOCK_NOTICE_FRAGMENT = `#graphql
  fragment LowStockNotice on ProductVariant {
    quantityAvailable
  }
` as const;

/** The parts of `<LowStockNotice>`, each with its own `cc-low-stock-notice-*` class. */
export type LowStockNoticePart = 'root' | 'count';

/** Props of `<LowStockNotice>`. */
export interface LowStockNoticeProps {
  variant: LowStockNoticeFragment;
  /** Shown at this many left or fewer; nothing above it. */
  threshold?: number;
  /** The text, from the project's translations; it gets the count, to show only when the merchant wants it shown. */
  children: (count: number) => React.ReactNode;
  /** Classes added to each part's `cc-*` class. */
  classNames?: Partial<Record<LowStockNoticePart, string>>;
}

/** Says how few of a variant are left, once the stock falls to `threshold`. */
export function LowStockNotice({variant, threshold = 5, children, classNames}: LowStockNoticeProps) {
  const count = variant.quantityAvailable;
  if (count == null || count < 1 || count > threshold) return null;
  return (
    <p className={['cc-low-stock-notice', classNames?.root].filter(Boolean).join(' ')}>
      <span className={['cc-low-stock-notice-count', classNames?.count].filter(Boolean).join(' ')}>
        {children(count)}
      </span>
    </p>
  );
}
```

Run `npm run codegen` after adding the fragment: it generates `LowStockNoticeFragment`.

## The test

Each block has a test beside it, run with vitest. If the project has no `test` script, add vitest first:

```sh
npm install -D vitest jsdom
```

Then, in `package.json`, add `"test": "vitest run"` to `scripts`, and add `npm test` to `check` (`npm run codegen && npm run typecheck && npm run lint && npm test && npm run build`), so that the pre-commit hook runs the tests too. No vitest config file is needed.

A test renders the block and compares the markup, including what it renders nothing for:

```tsx
import {renderToStaticMarkup} from 'react-dom/server';
import {describe, expect, it} from 'vitest';
import {LowStockNotice} from './LowStockNotice';

describe('LowStockNotice', () => {
  it('says how many are left at the threshold', () => {
    const html = renderToStaticMarkup(
      <LowStockNotice variant={{quantityAvailable: 3}} classNames={{root: 'theme'}}>
        {(count) => `${count} left`}
      </LowStockNotice>,
    );
    expect(html).toBe('<p class="cc-low-stock-notice theme"><span class="cc-low-stock-notice-count">3 left</span></p>');
  });

  it('shows nothing above the threshold, when sold out, or when the store does not say', () => {
    for (const quantityAvailable of [6, 0, null]) {
      expect(renderToStaticMarkup(<LowStockNotice variant={{quantityAvailable}}>{() => 'left'}</LowStockNotice>)).toBe('');
    }
  });
});
```

A block that reacts to clicks or typing needs a DOM: start its test file with `// @vitest-environment jsdom`, render it into a container with `react-dom/client`, and dispatch the events.

Check that the test can fail: change the behaviour it covers (here, the default threshold), see the test fail, and change it back.

## Using it on a page

```tsx
import {LowStockNotice, LOW_STOCK_NOTICE_FRAGMENT} from '~/building-blocks/LowStockNotice';

<LowStockNotice variant={selectedVariant} classNames={{root: 'mt-2 text-small text-warning'}}>
  {() => t('product.fewLeft')}
</LowStockNotice>
```

Whether shoppers see how many are left is the merchant's choice: the platform's own storefront shows a quantity only when the merchant's theme setting says so, and the storefront cannot read that setting. Ask the user; without a yes, the text names no number ("Only a few left"), as above. With it: `{(count) => t('product.lowStock', {count})}`.

The page's query spreads `...LowStockNotice` on the variant and interpolates `${LOW_STOCK_NOTICE_FRAGMENT}`. The text's key (`product.fewLeft`) goes into every file in `app/locales/` first: the keys are typed, so a missing one fails the typecheck. The classes come from the project's design tokens, as the rest of the page's do.

## Ready to move into Nitrogen

When it is done, tell the user that the block exists, what it does, and that it is a candidate for Nitrogen, so CloudCart can add it for every storefront. Keep it in `app/building-blocks/`: if a later Nitrogen version ships the same piece, the block is replaced by Nitrogen's and deleted.
