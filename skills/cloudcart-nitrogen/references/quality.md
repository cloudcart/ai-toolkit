# The quality checklist

The industry's good practice for a storefront page, as CloudCart sets it for Nitrogen storefronts. Go through it before you call a change done, for every page the change touches. Say which items you checked and how, and which you could not check (most often: a real phone, or a browser at all).

## Speed

- [ ] **Within the request budget,** measured in the profiler on a first and a second load (`references/verification.md`).
- [ ] **Core Web Vitals "good" on a phone:** LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 for the home, category and product pages. Measure them in a browser with a throttled phone profile when you can; if you cannot, say so.
- [ ] **Every picture from the API through `<Image>`:** it asks the store's image CDN for the widths it needs, with `srcset`. Give a fluid image `sizes`. Never put an API image URL in a raw `<img>`.
- [ ] **The first screen's largest picture** (a hero, a product's first photo) loads at once: `<Image loading="eager" fetchPriority="high">`. Every other picture keeps `<Image>`'s default, `loading="lazy"`.
- [ ] **No layout shift:** images have their size or `aspectRatio`, and a loading placeholder takes the size of what replaces it.
- [ ] **Instant feedback:** a cart change shows at once (`useOptimisticCart`), and a form shows that it is sending.
- [ ] **Nothing heavy at module load,** because a Worker has 1 s to start; no large client library for a small job; a third-party script through `<Script>`, and only after its consent (below).

## Accessibility and devices (WCAG 2.1 AA)

- [ ] **Keyboard:** every link, button and control can be reached with Tab and used with the keyboard, in a sensible order.
- [ ] **Visible focus** on everything that can take it.
- [ ] **Dialogs:** use the project's `Dialog` (`app/components/Dialog.tsx` in the starter), a native `<dialog>` opened with `showModal()`: focus moves in, stays inside, and Escape closes it. Without one, use a native `<dialog>` the same way.
- [ ] **Reduced motion:** animation and transitions respect `prefers-reduced-motion`.
- [ ] **Semantics:** one `h1` and headings in order; landmarks (`header`, `nav`, `main`, `footer`); a label for every control; a real `<button>` for an action and a link for navigation.
- [ ] **Text alternatives:** `<Image>` takes the merchant's alt text; a decorative picture has an empty `alt`; an icon-only button has a label from the translations.
- [ ] **Contrast:** colours from the design tokens only, so text meets 4.5:1 (3:1 for large text and controls).
- [ ] **Phone and desktop:** the page works at 390 px and 1280 px wide, with no horizontal scroll and touch targets large enough to hit.
- [ ] **An automated check** (axe, for example) reports no serious or critical violation on the page.

## SEO

- [ ] **Rendered on the server:** what a search engine should read comes from the loader, not from the browser after the page loads.
- [ ] **Meta tags** from the route's `meta` export with `seoMeta` (`app/lib/meta.ts`): title, description, and the canonical URL on the platform's address for the page (`app/lib/urls.ts`); `privateMeta` on a private or form page. The details: `references/seo.md`.
- [ ] **Structured data (JSON-LD)** with Nitrogen's helpers: `generateProductJsonLd`, `generateBreadcrumbJsonLd` (through the starter's `breadcrumbJsonLd` and `crumbsJsonLd`), `generateCollectionJsonLd`, `generateArticleJsonLd` and `generateOrganizationJsonLd`.
- [ ] **Not found is a 404:** a loader that finds nothing throws `new Response(null, {status: 404})`. `server.ts` passes every 404 through `storefrontRedirect`, which applies the merchant's 301 redirects.
- [ ] **The platform's addresses** for existing pages. `robots.txt` and `llms.txt` are routes of the starter. The sitemap is the platform's, so the storefront has no sitemap route.

## Consent and analytics

- [ ] **Each event once per page view:** the page renders Nitrogen's analytics view for its kind (`<Analytics.ProductView>`, `<Analytics.CollectionView>`, …) inside `<Analytics.Provider>`, and nothing else publishes the same event.
- [ ] **The merchant's consent decides:** the banner (`<PrivacyBanner>`), the visitor's choice (`useCustomerPrivacy`) and Google's signals (`<GoogleConsentMode>`) come from the merchant's GDPR app. A tracking script loads only after the visitor allows its consent group; `getMarketingPixels` gives each of the merchant's pixels with the group it waits for.
- [ ] **No tracking the merchant did not set up:** pixels and vendors come from the admin, not from the storefront's code. The details: `references/tracking.md`.

## Translations

- [ ] **Every word a visitor reads comes from `app/locales/`** through `t()`. The lint fails on literal text in JSX, and on `alt`, `aria-label`, `title` and `placeholder` written as literals.
- [ ] **Every language file has every key,** with the same `{placeholders}` as `en.json`, and a text that depends on a count has the plural forms its language needs. `npm run lint` checks all three.
- [ ] **Values in the store's format:** money with `<Money>` from `formatted`, dates with `formatDateTime`.

## The states between success and failure

- [ ] **Loading:** each deferred section has a `<Suspense>` fallback the size of its content.
- [ ] **Empty:** a list with nothing in it says so and offers a way on (the project's `EmptyState`), never an empty box.
- [ ] **Failed:** a deferred section that fails renders its `errorElement` or nothing, and the page still works. A route's error boundary (`RouteErrorBoundary` in the starter) catches what is left. A mutation's `userErrors` show next to their field.
- [ ] **Signed out:** a customer page sends a signed-out visitor to sign in; `customerAccount` does this when the token is missing or refused.
- [ ] **Sold out, unavailable, not delivered there:** the page shows what the API says (`availableForSale`, the cart's `warnings`), and never hides it.

## Design

- [ ] **Colours, spacing, type and breakpoints from the design tokens** in `app/styles/app.css`. The lint fails on a colour, font size or breakpoint outside them.
- [ ] **No dependence on the merchant's theme:** nothing reads theme settings or widget slots, because they change when the merchant changes theme.
