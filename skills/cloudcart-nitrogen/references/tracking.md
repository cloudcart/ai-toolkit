# Tracking: CloudCart Analytics and the merchant's pixels

How a Nitrogen storefront reports what visitors do, and what a page must add. Nitrogen does the reporting; a page only says what it is.

## How it works

- **Every event goes to the Storefront API** (`analyticsEventPublish`), which builds CloudCart Analytics' request from the platform's own formatters; the browser then sends it straight to CloudCart Analytics, the merchant's reports, as the platform's own storefront does. Where the merchant set up the server side, the API also forwards the event to Meta's Conversions API, TikTok's Events API and Google Analytics 4. The forwarding runs after the response, so it never slows the page.
- **In the browser, `Analytics.Provider` runs the merchant's pixels:** Google Analytics 4, Google Ads, Google Tag Manager, Meta and TikTok. Each one loads only when its consent group is accepted. A group the merchant set as accepted by default counts as accepted until the visitor declines it, so its vendors load on the first visit. Nitrogen adds their scripts once the page has loaded and is idle, with the events waiting in each vendor's queue until then. Every event goes to them under the same event id as the server's report, so a vendor counts it once.
- **CloudCart Analytics does not wait for consent,** as on the platform's own storefront; the vendors' pixels do.
- **A dev server and a build on `localhost` report nothing to CloudCart Analytics** (`cloudcart nitrogen dev`, `cloudcart nitrogen preview`): a developer's visits are not the store's. The browser's console shows each event instead (`[nitrogen] CloudCart Analytics: PAGE_VIEW (HOME) — not sent from a dev server or localhost`). Never set `cloudCartAnalyticsUrl` (or `PUBLIC_CLOUDCART_ANALYTICS_URL`) to get around it: it is for the platform's own tests.
- **Everything comes from the admin:** the pixels and their ids, the server-side tokens, the consent banner and its groups. The storefront's code adds no vendor and holds no vendor secret.

## The wiring (the root)

The starter does this in `app/root.tsx`; keep it when you change the root.

```tsx
// The root loader
shop: shopAnalyticsFrom(header), // the header's query asks shop { id } and the localization; else getShopAnalytics({storefront})
consent: {storefrontAccessToken: env.PUBLIC_STOREFRONT_API_TOKEN}, // the browser posts to the storefront's own /api/sf
pixels: getMarketingPixels({storefront}).catch(() => null), // never fail the page for it
customerEmailHash: customerAccount.getEmailHash() ?? null,  // a SHA-256 hash, never the e-mail
cloudCartAnalytics: customerAccount.takeCloudCartAnalytics(), // the sign-in's report, for the browser to send

// The layout
<Analytics.Provider cart={data.cart} shop={data.shop} consent={data.consent} wishlist={data.wishlist}
                    pixels={data.pixels} customerEmailHash={data.customerEmailHash}
                    cloudCartAnalytics={data.cloudCartAnalytics}>
  …the page…
  <PrivacyBanner consent={data.cookieConsent} storedChoice={data.consentChoice} />
</Analytics.Provider>
```

- `<GoogleConsentMode consent={cookieConsent}>` goes in `<head>`, before any Google tag: it tells Google the visitor's choice first.
- The CSP in `app/entry.server.tsx` allows the scripts of the pixels the store runs: `marketingPixelScriptSources(pixels)` in `scriptSrc`, with `getMarketingPixels` (the root loader's call, no request of its own). Do not drop it, and do not open the CSP wider for a pixel.

## Each page says what it is

The provider publishes `page_viewed` once per page by itself. A page adds the one view for its kind, once, and the page view is reported with that kind (`PRODUCT`, `CATEGORY`, `SEARCH`, …); a page without a view is reported as `OTHER`:

| Page | View |
|---|---|
| Home | `<Analytics.HomeView />` |
| Category or selection | `<Analytics.CollectionView data={{collection: {id, handle, title}, products}} />` |
| Product | `<Analytics.ProductView data={{products: [{id, title, price, vendor, variantId, variantTitle, sku, barcode, quantity: 1}]}} />` |
| Search | `<Analytics.SearchView data={{searchTerm, searchResults, products}} />` |
| Cart | `<Analytics.CartView />` |
| Brand (vendor) | `<Analytics.VendorView data={{vendor: {id, handle, title}, products}} />` |
| Tag | `<Analytics.TagView data={{tag: {id, handle, title}, products}} />` |
| Content page | `<Analytics.ContentPageView data={{page: {id, handle}}} />` |

`products` on a listing are the products it shows; the starter builds them with `listedProducts()` in `app/lib/analytics.ts`. A new page of one of these kinds renders its view; a page of another kind renders none — a list of products that is not a collection, brand, tag or search ("new arrivals", say) included. Its page view is reported as `OTHER`.

## What Nitrogen reports by itself

- **The cart:** `cart_updated`, `product_added_to_cart` and `product_removed_from_cart`, from the difference between two states of the provider's `cart`. Change the cart through `<CartForm>` or `<AddToCartButton>`, and the events follow.
- **The wishlist:** `product_added_to_wishlist` and `product_removed_from_wishlist`, from the provider's `wishlist` (the product ids).
- **Speed:** one page load in ten sends its LCP, INP and CLS, as the visitor's browser measured them, to CloudCart Analytics when the page is hidden. Do not add a speed script of your own.
- **The sign-in:** `customerAccount` links the visitor to the customer when they sign in; its report reaches the browser through the root (`takeCloudCartAnalytics()`, above). After the customer adds or edits an address, the action awaits `customerAccount.identifyVisitor()`.

Never publish these yourself: they would be counted twice.

## What a page publishes

- **The fast order:** `publish('fast_order_started', …)` when the form opens and `publish('fast_order_completed', …)` once the order is placed, with the event names the merchant chose (`FastOrderSettings.trackingEvents`). The server side of the purchase comes from the API: the action passes `analyticsInputFromRequest(request, {pixels, customerEmailHash})` to `fastOrderSubmit` as `analytics`, and the browser's event reuses the `analyticsEventId` the API answers with; `fast_order_completed` also takes the answer's `cloudCartAnalytics` (the order's report, which the browser sends). The starter's product page (`app/routes/product.$handle.tsx`) and `app/components/ProductRequestForms.tsx` do this; copy their pattern.
- **The cart drawer:** opening it publishes `cart_viewed` with the cart (`publish('cart_viewed', {cart, prevCart, shop, url})`, as the starter's `app/components/Header.tsx` does on the cart icon): a cart shown without a page of its own is a cart view, not a page view.
- **The search on a store with Aura Search:** its reports and its look, below.
- **Your own events:** `publish('custom_<name>', payload)` from `useAnalytics()`, or `<Analytics.CustomView type="custom_<name>" data={…} />`. They reach only the subscribers you add (`useAnalytics().subscribe`): CloudCart Analytics and the pixels do not receive them.

## The search on a store with Aura Search

Aura Search is CloudCart's search app. The merchant turns it on and sets it up in the admin. It needs a Nitrogen release newer than 2.4.1, which has `useSearchReport` and `searchHighlights`; upgrade an older one first. The starter's `app/components/PredictiveSearch.tsx` (the suggestions) and `app/routes/search.tsx` (the results page) do all of this; copy their pattern.

- **Which search answered:** `predictiveSearch` and `search` answer `engine`: `aura` on a store that runs it, `basic` otherwise. `shop.auraSearch` holds the merchant's settings, and is null without the app. Ask for it with the shop's other settings in the root's query, not on every keystroke, and read it with `useRouteLoaderData('root')`, as the starter's `useSearchLook()` does.
- **The reports** go to the merchant's Aura Search reports, not to CloudCart Analytics: they are a separate record, so they do not count twice beside `<Analytics.SearchView>`. `useSearchReport` follows one answer: `engine` decides whether there is anything to follow (`basic` reports and keeps nothing), and `tracksEvents: false` skips the reports the store would drop (the phrase is still kept):

  ```tsx
  const report = useSearchReport({
    query: term, // the phrase the answer is for, as it was sent
    engine: result.engine,
    tracksEvents: shop.auraSearch?.tracksEvents,
    impression: true, // the results page only; the suggestions leave it out
  });
  <Link to={productUrl} onClick={() => report.click(product.id, index + 1)}>…</Link>;
  ```

  The results page reports one impression each time it shows a phrase's results; the same results loaded again, after a cart change say, are not a new one. `report.click(productId, position)` reports a product opened from the suggestions or the results, with its place in the list as the buyer sees it, from 1; in a list that loads more, the count goes on. Categories, brands, pages and articles in the suggestions are not products, so they report nothing.
- **The phrase reaches the order:** `useSearchReport` keeps the last Aura phrase in the browser for seven days. Nitrogen adds it to the cart's attribution by itself, and `getAttribution()` returns it with the rest. Pass `getAttribution()` to an order placed without a cart, as the starter's fast order does; Nitrogen's express buttons pass it by themselves.
- **The suggestions look as the merchant set them up:** `highlightMatches` marks the searched words in the titles. `searchHighlights(title, query)` returns the pieces (`{text, match}`), and each `match` piece goes in a `<mark>`. `showPrice` shows the price, and `showCompareAtPrice` the price before the discount beside it.
- **The results page:** `showSort` decides whether the sort is offered. The cards stay the listing's.
- **A card's link carries its variant's `selectedOptions`** as the product page's option parameters (the starter's `getVariantUrl()`). The card then opens the variant the words named, the one it shows.
- **Without Aura Search,** `shop.auraSearch` is null and the search stays as it is: the words are not marked, the suggestions show their price, the results page offers the sort, and nothing is reported.

## Never

- Never load a vendor's script or call `gtag`, `fbq` or `ttq` yourself. The pixels the merchant set up run through the provider, after consent, with the shared event id. A script added by hand runs without consent, and counts every event twice.
- Never add a vendor the merchant has not set up in the admin. Glami, Skroutz, Profitshare and Retargeting, which the platform's own storefront runs, are not in Nitrogen 2.1 yet: tell the user, and do not add them by hand.
- Never send personal data to a vendor or into an event: no e-mail, phone or name. The customer is matched by `customerEmailHash` only.
- **A page whose address is a key to someone's data** — a return's status page, opened by its reference with no sign-in — marks itself private: `export const handle = {analytics: {private: true}} satisfies AnalyticsRouteHandle` (as the starter's `app/routes/withdrawal_.$reference.tsx`). Its events then carry the address with each route parameter masked and no title, and the pixels get nothing from it. Link to it with `reloadDocument`, so no vendor's library is running on it; Nitrogen warns when one is. An event the storefront publishes itself passes `analyticsPageUrl()` as the page's address, never `window.location.href`.
- Never render a view twice, or in a component that renders more than once on a page.

## How to check it

In the dev server, open the browser's console and network panel. A dev server reports nothing to CloudCart Analytics or to the API's server-side reporting: the console shows each event Nitrogen would report. The browser's pixels do run, on the live store's accounts: accepting a group in the banner sends the browser's events to the merchant's Meta, TikTok and Google Analytics. Tell the user and ask before you do it.

1. The console shows one `[nitrogen] CloudCart Analytics: PAGE_VIEW (…)` per page view, with the page's kind; a product page also a product view (`VIEW_CONTENT`), a search page a search (`SEARCH`); the cart page's view is its `PAGE_VIEW (CART)`, and opening the cart drawer shows a cart view (`VIEW_CART`).
2. Before the visitor chooses in the banner, no request goes to the vendors (`google-analytics.com`, `googletagmanager.com`, `facebook.com/tr`, `analytics.tiktok.com`). After they accept a group, the vendors of that group load and receive the page's events (with the user's word, above).
3. An add to cart shows `ADD_TO_CART` once.
4. On a store with Aura Search and its click tracking on in the admin (`shop.auraSearch.tracksEvents` is true), the results page logs one `[nitrogen] Aura Search: IMPRESSION`, and opening a product from the suggestions or the results logs one `Aura Search: CLICK`. Like the other events, they are logged, not sent, from a dev server. On a store without Aura Search, neither appears.

Report what you saw. If you could not open a browser, say so: the reporting is then not verified.
