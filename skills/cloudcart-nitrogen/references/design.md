# The store and its design

Stage 1: what the storefront looks like and holds, decided before the code. Start from the store's niche (`references/store-kinds.md`), design for a phone first, follow a store's UX practice, and keep the colours to one accent and one or two complementary ones.

## Mobile first

- **Design at 360–390 px first.** Write a component's classes for the phone, then add what a wider screen allows with `md:` (750 px) and `lg:` (990 px), the starter's only breakpoints (`sm:` and `xl:` do not exist, and its lint refuses them): Tailwind's breakpoints are minimum widths, so the unprefixed classes are the phone's. Check every page at 390 px and at 1280 px.
- **The main action within the thumb's reach.** On the product page, the starter's sticky add-to-cart bar keeps the purchase at hand while the visitor scrolls; on the cart page below 990 px a bar with the subtotal and the checkout comes up once the summary's own button is off the screen. Both bars are the starter's `app/components/ui/StickyBar.tsx`: a new page's main action uses it too. Nothing the keyboard reaches may sit under a bar that stays on the screen (WCAG 2.2's 2.4.11): the starter's `app.css` keeps the header's and the bar's height as the page's `scroll-padding`, and a page with a bar ends with room for it — a new sticky bar gets its own line there.
- **Touch targets** at least 44 × 44 px for the main controls (the size Apple's guidelines give; WCAG 2.2 sets 24 × 24 as the minimum), with space between neighbours.
- **Nothing only on hover.** What a pointer reveals (a second photo, a quick action) is reachable by a tap and the keyboard too, or is not needed.
- **Fields a phone can fill:** text at least 16 px (smaller, and Safari on iOS zooms into the field), and the right `type`, `inputMode` and `autoComplete` (`email`, `tel`, `postal-code`, …), so the phone shows the right keyboard and fills what it knows.
- **Menus and filters in a drawer.** The starter opens the menu, the cart and, below the desktop layout, the filters in a drawer along one side of the page (`Aside`), and the search in a box near the top of the screen, the whole screen on a phone (`Dialog` with `variant="float"`); the filter drawer's button shows how many products the choice leaves ("View 24 products"). Keep that pattern for a new panel.
- **Speed is part of the phone's design:** fewer and smaller pictures above the fold, no carousel that loads every slide, nothing that shifts as the page loads (stage 5).

## UX practice for a store

- **Search** in the header on every page, with results as the visitor types (products, categories, pages: the starter's `PredictiveSearch`) and a results page with the listing's filters. An empty result says so and offers a way on.
- **Listings:** the merchant's filters (the facets the API returns with the products) and sorting, light enough to share one row on a phone — the starter's sort is its chosen order's text with an arrow, no box, and the number of products is on the filter drawer's button and read out to screen readers, not in the row; two products a row on a phone, three or four wider (the starter's density toggle lets the visitor choose one a row on a phone, two wider; two is the default); more on demand ("load more"). A filter shows what it applies and how to clear it. The filters and the sort are GET forms whose fields carry the names the address uses, with the rest of the address in hidden fields and an Apply button in `<noscript>`, so they work before and without JavaScript; with it, a value applies as it changes, a price after a pause in typing, and only the first change adds a history entry — the next replace it, so one step back leaves them all (the starter's `ProductFilters`, `SortSelect` and `useRefinementNavigation`).
- **Product cards:** the picture, the title, the price with its discount, and whether it can be bought; the whole card is one link. Add only what helps to choose in that niche (`references/store-kinds.md`), so a card stays light.
- **The product page:** on a phone's first screen, the gallery, the title, the price, the choice of variant and the add to cart; then the details, delivery and returns, and the reviews. A sold-out or unavailable variant says so where the visitor chooses it. The page opens the variant its address names: by its options (`?Color=Red&Size=M`), or by its id — `?cv=<variant id>`, as the platform's product feeds (Google, Meta, TikTok) and campaign messages link a variant, or `?variant=` — with Nitrogen's `loadAddressVariantOptions` in the loader, its options given to the product query in place of the address's, with no redirect (the starter's `loadSelectedOptions` in `app/lib/product-page.ts`); otherwise an ad lands on the first variant, not the one it priced.
- **The cart:** the totals the API gives, a clear way to change a line, and one checkout button to the platform's checkout.
- **Feedback on every action:** a cart change shows at once (`useOptimisticCart`), a form shows it is sending, and an error says what to do, next to its field.
- **Trust:** the store's contact, company and policies in the footer (the starter's `StoreContact`), and the merchant's own words for delivery and returns.

## Pictures

- **The store's image CDN resizes every picture it serves,** as Shopify's `image_url` does. A picture's URL from the API (`/cdn/img/…` on the store's domain; file-manager images, `/{site}/files/image/…`, go through the same resizer) takes:
  - `width` and `height`: the picture fitted inside that box, never enlarged — one of them keeps the other side in proportion;
  - `crop` (`center`, `top`, `bottom`, `left`, `right`, `top_left`, `top_right`, `bottom_left`, `bottom_right`): the picture fills the `width` × `height` box and loses what overflows, kept from that side;
  - `pad_color` (a hex colour): the picture extended to the box's proportions in that colour instead of cut;
  - `format` (`webp`, `avif`, `jpg`, `png`) and `quality` (1–100).
  On a store's CDN (checked 2026-10-15): `width=200` gave 200 × 200 px and 8 KB, `width=1200` 1200 × 1200 px and 126 KB, `width=300&height=300&crop=center` 300 × 300, `width=300&height=375&pad_color=ffffff` 300 × 375, `format=webp` a WebP.
- **Never let the browser shrink a picture the CDN can shrink.** A 1200-px copy in a 150-px card downloads fifteen times more and looks jagged. `<Image>` (`@cloudcart/nitrogen-react`) asks the CDN for the widths a layout needs, through `cloudcartLoader`, in a `srcset`; give a fluid picture `sizes`, the width it shows at, so the browser takes the smallest that fills it. Work it out from the layout: in the starter's page box (90rem with its gutters) a column of a grid is a fixed width above 1440 px and a `calc()` of the window below, less the gutters and the gaps — a four-column grid's card is `(min-width: 1440px) 328px, (min-width: 990px) calc(25vw - 32px), …`, where `25vw` alone asks a 1876 px window for 469 px.
- **A small picture offers only small widths:** a thumbnail, a search result, a cart line. Cap its `srcset` with `srcSetOptions` — `{intervals: 3, startingWidth: 200, incrementSize: 200, placeholderWidth: 100}` offers 200, 400 and 600 px, 1× to 3× of a picture up to about 200 px wide — or give it a fixed `width` (`<Image width={96}>` offers 96, 192 and 288 px).
- **Keep a product's proportions:** in a card's frame, fit the picture whole with `object-contain`, by its width or its height, as the starter's cards do; fill and crop (`object-cover`, or `aspectRatio` with `crop`) only a picture made to fill, such as a banner.

## The colours

- **One accent colour** for what the visitor acts on: the main button, links in text, the focus ring, the chosen option. In the starter a link in running text takes the `inline-link` utility (the accent, underlined); a link that stands alone as an action keeps the text's colour.
- **One or two complementary colours** that mark products: a discount's percentage on a card, "new", a highlight band. A saving in money (a quantity tier's, the cart's discounts) is in the success colour, a meaning colour.
- **Everything else neutral:** the background, the text, borders and quiet surfaces.
- **The meaning colours stay as they are:** error, success and warning are not the brand's.
- **In the starter** they are design tokens in `app/styles/app.css`: `--color-accent` and `--color-accent-foreground` (the text on it), `--color-highlight` and `--color-highlight-foreground`. Set them from the merchant's brand (ask the user for it, or read the logo's colours with them); the defaults are black and white. Never a colour outside the tokens: the lint fails on a palette colour, and Tailwind's own shadows (`shadow-sm`, `shadow-lg`) are reset, so a shadow comes from the tokens too (`shadow-popover`).
- **Contrast:** at least 4.5 : 1 between each colour and the text on it, 3 : 1 for large text and controls (WCAG 2.1 AA). Check each pair you set.

## The structure by niche

What the search, the listings, the cards and the product page show for each kind of store is in `references/store-kinds.md`. Decide it before stage 2: it decides which fields each page's query selects, and nothing else should be selected.
