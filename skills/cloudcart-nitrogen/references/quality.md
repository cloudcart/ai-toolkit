# The review of the whole site

Stage 5's checklist: the industry's good practice for a storefront, as CloudCart sets it for Nitrogen storefronts. Go through it before a release, and for every page a change touches. Say which items you checked and how, and which you could not check (most often: a real phone, or a browser at all): an item not checked is reported as not checked, never passed. An item that fails is fixed, or reported to the user with its cause before the release.

How the store should look and be structured is decided in stage 1 (`references/design.md`). This list keeps only what can be checked of it: the widths, the contrast, the tokens and the store's colours.

## Speed

- [ ] **A Lighthouse performance score of at least 90 on a phone** (Lighthouse's default mobile profile) for the home, a category and a product page, on what ships, not on the dev server, which serves unbundled, unminified code. How to measure and what to report: `references/verification.md`.
- [ ] **Core Web Vitals "good" on a phone:** LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 for the home, category and product pages.
- [ ] **Every picture from the API through `<Image>`:** it asks the store's image CDN for the widths it needs, with `srcset`. Give a fluid image `sizes`; a small one (a thumbnail, a search result) offers only small widths (`srcSetOptions`, or a fixed `width`), so no large copy is shrunk by the browser; a product's picture keeps its proportions (`object-contain`). Never put an API image URL in a raw `<img>`. The CDN's parameters: `references/design.md`, "Pictures".
- [ ] **The first screen's largest picture** (a hero, a product's first photo) loads at once: `<Image loading="eager" fetchPriority="high">`. What else the first screen shows loads eagerly too (a listing's first eight cards, the header's logo); a picture below it keeps `<Image>`'s default, `loading="lazy"`.
- [ ] **No layout shift:** images have their size or `aspectRatio`, and a loading placeholder takes the size of what replaces it.
- [ ] **Instant feedback:** a cart change shows at once (`useOptimisticCart`), and a form shows that it is sending.
- [ ] **A page opens at once:** a click on a link to a product, a listing, the search, a merchant's page or an article shows that page's waiting view within a moment, with what the link already showed, and the page's data replaces it in place with no layout shift; a new kind of page has its own view, built from the page's own layout (`references/speed.md`).
- [ ] **The times are measured:** each changed page's data on a click, cached and not, and the time to the waiting view and to the page's content, before and after, reported in a table (`references/speed.md`).
- [ ] **A next page is there before the visitor:** a listing's "Load more" starts loading ahead of the screen (`autoLoadMargin`), and its loader asks only what every page of it needs.
- [ ] **Light JavaScript:** nothing heavy at module load (a Worker has 1 s to start); no large client library for a small job; a third-party script through `<Script>`, and only after its consent (`references/tracking.md`). The merchant's pixels count toward the score: a consent group the merchant set as accepted by default loads its vendors on the first visit.

## Caching

- [ ] **Each query has the strategy its data needs** (the table in `references/graphql.md`): `CacheLong()` only for menus and static lists, `CacheSettings()` for the settings the merchant edits, `CacheShort()` or the default for the catalogue and content, `CacheNone()` for what a visitor must see at once after changing it.
- [ ] **The cache is used:** on a second load, the profiler (`/__nitrogen/subrequests`) shows the shared calls as `HIT`, or `STALE` while they refresh, and none as `NONE` that is the same for every visitor.
- [ ] **A buyer's data stays the buyer's:** a query that passes the buyer is cached under that buyer; the customer's own data goes through `customerAccount.query`, which never caches.
- [ ] **The page cache holds only what is the same for everyone:** a page in it (`handle = SHARED_PAGE`) reads nothing of the visitor's in its loader; their cart, sign-in and forms come from `/visitor` in the browser; on the deployed storefront it answers `MISS`, then `HIT` (`references/speed.md`). Never set a shared `Cache-Control` (`public`, `s-maxage`) yourself.
- [ ] **Private pages are never shared:** a page with one customer's data sends `Cache-Control: private, no-store` (`privatePageHeaders` in the starter's `app/lib/headers.ts`) and has no `SHARED_PAGE`.

## Queries

- [ ] **Within the request budget,** measured in the profiler on a first and a second load (`references/verification.md`), and compared with the page's "before".
- [ ] **No N+1:** no operation repeated once per item.
- [ ] **No REST habit** from the table in `references/graphql.md` ("GraphQL, not REST"): no call per resource, no data fetched by id in a second call, no value written into a document, no query after a mutation, no filtering, sorting or paging in code, no `fetch()` to the API, no anonymous operation.
- [ ] **A list of products inside a list asks only each item's first page** (no `after`, `last` or `filters`, each fetched per item), for an outer list fixed in the document; one item's next page is asked for that item alone (its own page, or a resource route through `useFetcher().load()`).
- [ ] **No field the page does not render,** and each field in the fragment of what renders it.
- [ ] **No call that waits for no reason:** independent calls start together (at most 6 at a time); below the first screen, data comes from the page's deferred query, and a list of products the visitor may never reach is asked for only as they near it.
- [ ] **Where it can be better:** name each call or field that could go, merge or be deferred, even when the page is within its budget.

## Security

- [ ] **No secret in the browser:** neither `PRIVATE_STOREFRONT_API_TOKEN` nor `SESSION_SECRET` is read by a component or a client module, and `build/client/` holds neither their names nor their values (search it by name, and by value without printing it: `grep -rlF`).
- [ ] **No secret in git:** `.env` is ignored, and no token or password is in the code, the tests or the docs.
- [ ] **The customer's access token** only in the signed session cookie: never in a URL, browser storage, client code or an `Authorization` header.
- [ ] **The CSP holds:** every inline script carries the nonce (`<Script>`, `useNonce()`); a new third-party source is named in `app/entry.server.tsx`, and the policy is not widened otherwise; the browser's console shows no CSP violation on the page.
- [ ] **Forms go through route actions** to the API's mutations, and show their `userErrors`; nothing is trusted from the browser alone.
- [ ] **Redirects stay in the store:** a target taken from the request (`?redirect=`, a form's `redirectTo`) is followed only through Nitrogen's `localRedirectPath`, which refuses one that leaves the storefront — `//host`, `/\host`, a tab, and dot segments that collapse into `//` (`/..//host`). Nitrogen's `storefrontRedirect` follows a 404's `?redirect=` through it too.
- [ ] **Dependencies:** `npm audit --omit=dev` reports no high or critical advisory, or each one is reported to the user.

## SEO

- [ ] **Every indexable page passes `references/seo.md`'s list:** rendered on the server; title, description, canonical on the store's domain and image; `privateMeta` on private and form pages; a listing's pages each their own canonical; JSON-LD for its kind; one `h1`; alt text on content images; a 404 for a missing record.
- [ ] **The platform's addresses** for existing pages. The sitemap is the platform's, so the storefront has no sitemap route.
- [ ] **`/llms.txt` and `robots.txt` answer.** `/llms.txt` serves `shop.llmsTxt` — the merchant's text, or the platform's default when they wrote none — and answers 404 when the store publishes none (a trial or an expired plan, or switched off). `robots.txt` names it (`Llms:`) and, on the store's domain, the platform's sitemap (`Sitemap:`). A storefront without the two routes takes them from the starter (`app/routes/[robots.txt].tsx`, `app/routes/[llms.txt].tsx`).
- [ ] **Lighthouse's SEO audits pass** on the home, a category and a product page. Two fail by design: off the store's domain, `is-crawlable` (Nitrogen's request handler sends `X-Robots-Tag: noindex` on every other host, so a preview or a dev server stays out of search results), and `robots-txt`, which does not know the `Llms:` line.

## Consent and analytics

- [ ] **Each event once per page view:** the page renders Nitrogen's analytics view for its kind (`<Analytics.ProductView>`, `<Analytics.CollectionView>`, …; none for a page of another kind) inside `<Analytics.Provider>`, and nothing else publishes the same event.
- [ ] **The merchant's consent decides:** the banner (`<PrivacyBanner>`), the visitor's choice (`useCustomerPrivacy`) and Google's signals (`<GoogleConsentMode>`) come from the merchant's GDPR app; a tracking script loads only when its consent group allows it.
- [ ] **The pixels fire:** checked in the network panel as `references/tracking.md` says, or reported as not checked.
- [ ] **No tracking the merchant did not set up:** pixels and vendors come from the admin, not from the storefront's code.
- [ ] **A script from outside waits for its consent:** loaded with `<Script>` or `useLoadScript` only once `useCustomerPrivacy` allows its group, its host alone added to the CSP (`references/storefront-foundations.md`).
- [ ] **Nothing of the frame rebuilt:** the cookie banner, the pop-up and embedded subscribe forms, the announcement bar, the drawers, the error page and the data requests are the starter's (`references/storefront-foundations.md`), not a page's own copies.

## Accessibility and devices (WCAG 2.1 AA)

- [ ] **Phone and desktop:** the page works at 390 px and 1280 px wide, with no horizontal scroll and touch targets large enough to hit.
- [ ] **Keyboard:** every link, button and control can be reached with Tab and used with the keyboard, in a sensible order.
- [ ] **Visible focus** on everything that can take it. A frame (a map, a video, one in the merchant's HTML) gets no `:focus-visible` in Chrome while its content holds the focus: call `useFrameFocusVisible()` from `@cloudcart/nitrogen-react` once in the root layout and give `iframe[data-focus-visible]` the same ring.
- [ ] **Dialogs:** use the project's `Dialog` (`app/components/Dialog.tsx` in the starter), a native `<dialog>` opened with `showModal()`: focus moves in, stays inside, and Escape closes it.
- [ ] **Reduced motion:** animation and transitions respect `prefers-reduced-motion`.
- [ ] **Semantics:** one `h1` and headings in order — the merchant's HTML under the page's own heading through `<RichText headingStart={2}>` (3 under an `h2`); landmarks (`header`, `nav`, `main`, `footer`); a label for every control; a real `<button>` for an action and a link for navigation.
- [ ] **Text alternatives:** `<Image>` takes the merchant's alt text; a decorative picture has an empty `alt`; an icon-only button has a label from the translations.
- [ ] **Embedded frames are named:** the merchant's HTML goes through `<RichText>`, which titles an untitled `<iframe>` from its source; the merchant is told to give each frame its own `title`.
- [ ] **Contrast:** colours from the design tokens only, and every pair the store set (the accent, the highlight and the text on them) at least 4.5:1, 3:1 for large text; a control whose edge is all that shows it (a text field, a colour swatch) has that edge at 3:1 against the page (the starter's `--color-control`).
- [ ] **An automated check** (axe, or Lighthouse's accessibility audits) reports no serious or critical violation on the page.

## Translations

- [ ] **Every word a visitor reads comes from `app/locales/`** through `t()` (`const {t} = useTranslation()`, from `@cloudcart/nitrogen`). The lint fails on literal text in JSX, and on `alt`, `aria-label`, `title` and `placeholder` written as literals.
- [ ] **A sentence is one message,** never pieces joined in code: a price, a date or a link inside it goes in with `<Translated message="…" values={{date: <DateText … />}} />` (`@cloudcart/nitrogen`), so each language keeps its word order. Separators (`format.list`, `format.separator`, `format.nameValue`) come from the locale too, and the browser's "fill in this field" speaks the store's language through `useValidityMessages` in the root (the starter's `lib/validity.ts`).
- [ ] **Every language file has every key,** with the same `{placeholders}` as `en.json`, and a text that depends on a count has the plural forms its language needs. `npm run lint` checks all three.
- [ ] **Values in the store's format:** money with `<Money>` from `formatted`, dates with `formatDateTime`.

## The states between success and failure

- [ ] **Every element in every state:** the page's elements, listed before you wrote code (SKILL.md, "Before you write code"), each present and right on a phone and a desktop, in each state below that applies; the waiting view has the same elements in the same places, so nothing appears or leaves when the content comes.
- [ ] **Loading:** each deferred section has a `<Suspense>` fallback the size of its content: in the starter `ProductGridPlaceholder` for a row of cards, `TextPlaceholder` for a few lines, and for a section whose most common answer is empty, its `EmptyState` with `*:invisible` (the product's reviews).
- [ ] **Empty:** a list with nothing in it says so and offers a way on (the project's `EmptyState`), never an empty box.
- [ ] **Failed:** a deferred section that fails renders its `errorElement` or nothing, and the page still works. A route's error boundary (`RouteErrorBoundary` in the starter) catches what is left. A mutation's `userErrors` show next to their field.
- [ ] **Signed out:** a customer page sends a signed-out visitor to sign in; `customerAccount` does this when the token is missing or refused.
- [ ] **Sold out, unavailable, not delivered there:** the page shows what the API says (`availableForSale`; the `warnings` of a cart mutation's answer and of each cart line), and never hides it.

## Design

- [ ] **Colours, spacing, type, widths and breakpoints from the design tokens** in `app/styles/app.css`. The lint fails on a colour, font size or breakpoint outside them, on a width, letter spacing or blur of Tailwind's own scale (`max-w-md`: name its role in `app.css`, `max-w-reading`), and on a media query written in the code (`matchMedia` takes `app/lib/breakpoints.ts`).
- [ ] **The store's colours are set:** `--color-accent` and `--color-highlight` carry the merchant's brand, or the user chose to keep the starter's black and white.
- [ ] **No dependence on the merchant's theme:** nothing reads theme settings or widget slots, because they change when the merchant changes theme.
- [ ] **Built on the starter, not over it:** no second component that does an existing one's job, no CSS that overrides a component's own, no copy of a starter file changed beside the original; what a component lacked was added to it.
