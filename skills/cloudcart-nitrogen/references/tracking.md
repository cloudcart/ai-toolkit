# Tracking: CloudCart Analytics and the merchant's pixels

How a Nitrogen storefront reports what visitors do, and what a page must add. Nitrogen does the reporting; a page only says what it is.

## How it works

- **Every event goes to the Storefront API** (`analyticsEventPublish`). The API records it in CloudCart Analytics, the merchant's reports. Where the merchant set up the server side, the API also forwards it to Meta's Conversions API, TikTok's Events API and Google Analytics 4. The forwarding runs after the response, so it never slows the page.
- **In the browser, `Analytics.Provider` runs the merchant's pixels:** Google Analytics 4, Google Ads, Google Tag Manager, Meta and TikTok. Each one loads only after the visitor accepts its consent group. Every event goes to them under the same event id as the server's report, so a vendor counts it once.
- **CloudCart Analytics does not wait for consent,** as on the platform's own storefront; the vendors' pixels do.
- **Everything comes from the admin:** the pixels and their ids, the server-side tokens, the consent banner and its groups. The storefront's code adds no vendor and holds no vendor secret.

## The wiring (the root)

The starter does this in `app/root.tsx`; keep it when you change the root.

```tsx
// The root loader
shop: getShopAnalytics({storefront}),
consent: {storefrontAccessToken: env.PUBLIC_STOREFRONT_API_TOKEN, storefrontApiUrl: storefront.getApiUrl()},
pixels: getMarketingPixels({storefront}).catch(() => null), // never fail the page for it
customerEmailHash: customerAccount.getEmailHash() ?? null,  // a SHA-256 hash, never the e-mail

// The layout
<Analytics.Provider cart={data.cart} shop={data.shop} consent={data.consent} wishlist={data.wishlist}
                    pixels={data.pixels} customerEmailHash={data.customerEmailHash}>
  …the page…
  <PrivacyBanner consent={data.cookieConsent} storedChoice={data.consentChoice} />
</Analytics.Provider>
```

- `<GoogleConsentMode consent={cookieConsent}>` goes in `<head>`, before any Google tag: it tells Google the visitor's choice first.
- The CSP in `app/entry.server.tsx` allows the vendors' scripts with `MARKETING_PIXEL_SCRIPT_SOURCES` in `scriptSrc`. Do not drop it, and do not open the CSP wider for a pixel.

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

`products` on a listing are the products it shows; the starter builds them with `listedProducts()` in `app/lib/analytics.ts`. A new page of one of these kinds renders its view; a page of another kind renders none.

## What Nitrogen reports by itself

- **The cart:** `cart_updated`, `product_added_to_cart` and `product_removed_from_cart`, from the difference between two states of the provider's `cart`. Change the cart through `<CartForm>` or `<AddToCartButton>`, and the events follow.
- **The wishlist:** `product_added_to_wishlist` and `product_removed_from_wishlist`, from the provider's `wishlist` (the product ids).
- **The sign-in:** `customerAccount` links the visitor to the customer when they sign in.

Never publish these yourself: they would be counted twice.

## What a page publishes

- **The fast order:** `publish('fast_order_started', …)` when the form opens and `publish('fast_order_completed', …)` once the order is placed, with the event names the merchant chose (`FastOrderSettings.trackingEvents`). The server side of the purchase comes from the API: the action passes `analyticsInputFromRequest(request, {pixels, customerEmailHash})` to `fastOrderSubmit` as `analytics`, and the browser's event reuses the `analyticsEventId` the API answers with. The starter's product page (`app/routes/product.$handle.tsx`) and `app/components/ProductRequestForms.tsx` do this; copy their pattern.
- **Your own events:** `publish('custom_<name>', payload)` from `useAnalytics()`, or `<Analytics.CustomView type="custom_<name>" data={…} />`. They reach only the subscribers you add (`useAnalytics().subscribe`): CloudCart Analytics and the pixels do not receive them.

## Never

- Never load a vendor's script or call `gtag`, `fbq` or `ttq` yourself. The pixels the merchant set up run through the provider, after consent, with the shared event id. A script added by hand runs without consent, and counts every event twice.
- Never add a vendor the merchant has not set up in the admin. Glami, Skroutz, Profitshare and Retargeting, which the platform's own storefront runs, are not in Nitrogen 2.0 yet: tell the user, and do not add them by hand.
- Never send personal data to a vendor or into an event: no e-mail, phone or name. The customer is matched by `customerEmailHash` only.
- Never render a view twice, or in a component that renders more than once on a page.

## How to check it

In the dev server, open the browser's network panel:

1. Each page sends `analyticsEventPublish` to `/api/sf` once for its page view (`PAGE_VIEW`, with the page's kind); a product page also sends a product view (`VIEW_CONTENT`), and a search page a search (`SEARCH`).
2. Before the visitor chooses in the banner, no request goes to the vendors (`google-analytics.com`, `googletagmanager.com`, `facebook.com/tr`, `analytics.tiktok.com`). After they accept a group, the vendors of that group load and receive the page's events.
3. An add to cart sends `product_added_to_cart` once.

Report what you saw. If you could not open a browser, say so: the reporting is then not verified.
