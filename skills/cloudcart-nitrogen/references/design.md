# The store and its design

Stage 1: what the storefront looks like and holds, decided before the code. Start from the store's niche (`references/store-kinds.md`), design for a phone first, follow a store's UX practice, and keep the colours to one accent and one or two complementary ones.

## Mobile first

- **Design at 360–390 px first.** Write a component's classes for the phone, then add what a wider screen allows with `md:` and `lg:`: Tailwind's breakpoints are minimum widths, so the unprefixed classes are the phone's. Check every page at 390 px and at 1280 px.
- **The main action within the thumb's reach.** On the product page, the starter's sticky add-to-cart bar keeps the purchase at hand while the visitor scrolls; the cart's checkout button is visible without scrolling.
- **Touch targets** at least 44 × 44 px for the main controls (the size Apple's guidelines give; WCAG 2.2 sets 24 × 24 as the minimum), with space between neighbours.
- **Nothing only on hover.** What a pointer reveals (a second photo, a quick action) is reachable by a tap and the keyboard too, or is not needed.
- **Fields a phone can fill:** text at least 16 px (smaller, and Safari on iOS zooms into the field), and the right `type`, `inputMode` and `autoComplete` (`email`, `tel`, `postal-code`, …), so the phone shows the right keyboard and fills what it knows.
- **Menus and filters in a drawer.** The starter opens the menu, the search, the cart and, below the desktop layout, the filters in a drawer along one side of the page (`Aside`); the filter drawer's button shows how many products the choice leaves ("View 24 products"). Keep that pattern for a new panel.
- **Speed is part of the phone's design:** fewer and smaller pictures above the fold, no carousel that loads every slide, nothing that shifts as the page loads (stage 5).

## UX practice for a store

- **Search** in the header on every page, with results as the visitor types (products, categories, pages: the starter's `PredictiveSearch`) and a results page with the listing's filters. An empty result says so and offers a way on.
- **Listings:** the number of products, the merchant's filters (the facets the API returns with the products) and sorting; two products a row on a phone, three or four wider; more on demand ("load more"). A filter shows what it applies and how to clear it.
- **Product cards:** the picture, the title, the price with its discount, and whether it can be bought; the whole card is one link. Add only what helps to choose in that niche (`references/store-kinds.md`), so a card stays light.
- **The product page:** on a phone's first screen, the gallery, the title, the price, the choice of variant and the add to cart; then the details, delivery and returns, and the reviews. A sold-out or unavailable variant says so where the visitor chooses it.
- **The cart:** the totals the API gives, a clear way to change a line, and one checkout button to the platform's checkout.
- **Feedback on every action:** a cart change shows at once (`useOptimisticCart`), a form shows it is sending, and an error says what to do, next to its field.
- **Trust:** the store's contact, company and policies in the footer (the starter's `StoreContact`), and the merchant's own words for delivery and returns.

## The colours

- **One accent colour** for what the visitor acts on: the main button, links in text, the focus ring, the chosen option.
- **One or two complementary colours** that mark products: a discount, "new", a highlight band.
- **Everything else neutral:** the background, the text, borders and quiet surfaces.
- **The meaning colours stay as they are:** error, success and warning are not the brand's.
- **In the starter** they are design tokens in `app/styles/app.css`: `--color-accent` and `--color-accent-foreground` (the text on it), `--color-highlight` and `--color-highlight-foreground`. Set them from the merchant's brand (ask the user for it, or read the logo's colours with them); the defaults are black and white. Never a colour outside the tokens: the lint fails on one.
- **Contrast:** at least 4.5 : 1 between each colour and the text on it, 3 : 1 for large text and controls (WCAG 2.1 AA). Check each pair you set.

## The structure by niche

What the search, the listings, the cards and the product page show for each kind of store is in `references/store-kinds.md`. Decide it before stage 2: it decides which fields each page's query selects, and nothing else should be selected.
