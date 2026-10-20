# What every storefront has

The starter gives every storefront the same frame around its pages and the same wiring underneath, and most of it is driven by the merchant's admin. A change keeps it, and a new page sits inside it. Before you add anything of these kinds — a banner, a bar, a pop-up, a form, a script, a cookie notice — look here first: it most likely exists, and it already follows the merchant's settings, the visitor's consent and the page cache.

## Around every page

`AppShell` in `app/root.tsx` and `app/components/PageLayout.tsx` put these around every page, the error page included:

| Part | Where | Driven by |
|---|---|---|
| The header: the logo, the main menu with its mega-menu panels, the search, account and cart icons | `app/components/Header.tsx`, `MegaMenu.tsx` | The admin's `main` menu and the shop (the root's `HEADER_QUERY`, `CacheSettings()`); a menu item's collection gives its panel products (`app/routes/menu-products.tsx`) |
| The announcement bar | `app/components/AnnouncementBar.tsx` | The messages in `app/lib/announcements.ts`, their words in `app/locales/`; an empty list hides it |
| The search | `SearchModal` in `PageLayout.tsx`, `app/components/PredictiveSearch.tsx` | The search route (`app/routes/search.tsx`), and `app/routes/search-start.tsx` for what it opens with |
| The cart drawer | `CartAside` in `PageLayout.tsx`, `app/components/CartMain.tsx` | The cart (`references/tracking.md` for `cart_viewed`) |
| The phone's menu | `MobileMenuAside` in `PageLayout.tsx`, with the header's `HeaderMenu` | The same `main` menu |
| The footer: the footer menu, the policies, the store's contact, the privacy request form's link (when the store takes requests), the embedded subscribe form, "Cookie settings" (when the store asks for consent) | `app/components/Footer.tsx`, `StoreContact.tsx` | The admin's `footer` menu, the policies, the contact and `gdprRequestTypes` (the root's `FOOTER_QUERY`, `CacheSettings()`), the subscribe forms |
| The progress bar, the skip link, the waiting pages | `PageLayout.tsx`, `app/components/PageTransition.tsx`, `PendingPage.tsx` | `references/speed.md` |
| The error page and the missing page | `RouteErrorBoundary` (`app/components/RouteError.tsx`), `app/components/NotFound.tsx` | A 404 first follows the merchant's redirects (`storefrontRedirect` in `server.ts`) |
| The store's words | `app/locales/`, `useValidityMessages` with `app/lib/validity.ts` (the browser's "fill in this field" in the store's language) | The store's language (`localization`) |
| The focus ring on a frame | `useFrameFocusVisible()` | — |

A new page renders only its own content: the frame comes with the root. Never add a second header, footer, banner or drawer inside a page.

## Analytics and its events

Nitrogen reports what visitors do; a page only says what it is. In short (all of it in `references/tracking.md`):

- `<Analytics.Provider>` in the root, with the shop, the cart, the wishlist, the consent, the merchant's pixels and the signed-in customer's e-mail hash, never the e-mail.
- `page_viewed` once per page by itself; each page renders the one view for its kind (`<Analytics.ProductView>`, `<Analytics.CollectionView>`, `<Analytics.SearchView>`, …), a page of another kind none.
- The cart, the wishlist and the sign-in report by themselves; the cart drawer publishes `cart_viewed`, the fast order its two events.
- A page whose address is a key to someone's data (the return pages, `app/routes/withdrawal.tsx` and `withdrawal_.$reference.tsx`) marks itself private: `handle = {analytics: {private: true}}`.
- Every event goes to the Storefront API, which records it in CloudCart Analytics without waiting for consent and forwards it server side where the merchant set that up; the merchant's pixels in the browser wait for consent.

## Cookie consent (the merchant's GDPR app)

The wiring, not the law: what the store asks and says is the merchant's, set in the admin's GDPR app.

- **The banner:** `<PrivacyBanner>` in the root — the bar, or a wall that blocks the store until the visitor chooses, and the preference center — with its groups, defaults and texts from the GDPR app (`getCookieConsent`, the root's critical data). The starter's look for it: `app/lib/privacy-banner.ts`. While the GDPR app is not active the store asks for no consent, and there is no banner.
- **In the first HTML:** the root reads the visitor's stored choice from the cookie (`getConsentFromCookieHeader`), so the bar paints with the page for a visitor who has not chosen and never for one who has; on a page from the page cache, `<PrivacyBannerScript>` hides it before it paints for one who has. The choice is kept in the platform storefront's own cookie.
- **Google first:** `<GoogleConsentMode>` in `<head>`, before any Google tag, tells Google the visitor's choice.
- **"Cookie settings"** in the footer opens the preference center (`showPreferences()` of the banner).
- **Your own code asks the visitor's consent** with `useCustomerPrivacy({consent})`: `customerPrivacy.isAccepted(group)`, or `analyticsProcessingAllowed()`, `marketingAllowed()`, `preferencesProcessingAllowed()`. The groups: analytics is `performance`, marketing and sale of data are `targeting`, preferences are `functional`. A group the merchant made accepted by default counts as accepted until the visitor declines it.

## The visitor's data requests

- **The pages:** `/gdpr` (what a visitor can do about the data the store keeps), `/gdpr/request/{type}` (a question, a copy, its deletion, an end to marketing: the types the store takes, `gdprRequestTypes`), `/gdpr/download/{kind}` (a signed-in customer's copy of their personal information, addresses or orders), and in the account the policies they accepted (`/account/gdpr`, each at `/account/gdpr/{id}`) and the requests they sent (`/account/gdpr-requests`). A store without the GDPR app answers 404 on them.
- **After sign-in,** the store's request to accept its policies: `<PolicyConsentRequest>` in the root, shown when the API has one (`Customer.policyConsentRequest`).
- A page filled with a customer's data (a request's form for a signed-in customer) sends `privatePageHeaders`.

## Scripts from outside

- **The merchant's pixels** — Google Analytics, Google Ads, Google Tag Manager, Meta, TikTok — come from the admin and run only through `<Analytics.Provider>`, after consent, once the page is idle. Never add their scripts or call `gtag`, `fbq` or `ttq` yourself (`references/tracking.md`).
- **The Content Security Policy** (`app/entry.server.tsx`): scripts from the storefront itself with the request's nonce, and from the hosts of the pixels this store runs (`marketingPixelScriptSources(pixels)`); images, media, frames and fonts from any HTTPS address, for the merchant's own embeds in descriptions and pages.
- **Another third-party script** the merchant asks for (a chat, a reviews widget): ask the user first, as it costs the page's speed. Load it with `<Script>` (it carries the nonce) or `useLoadScript` (a large script, loaded when needed, with its state), only once its consent group allows it (`useCustomerPrivacy`), never in `<head>` before `<GoogleConsentMode>`. Add its host alone to `scriptSrc` — never `'unsafe-inline'` or a whole scheme — and check the console for a CSP violation.

## Pop-ups and forms

- **The merchant's pop-up subscribe forms:** `<SubscribePopups>` in the root, opened by the merchant's rules and drawn as they designed them in the form builder (Marketing Suite → Subscribers → Forms). With a cookie banner, a form that waits for marketing consent waits for it. Their views and answers post to `/subscribe-forms` (`app/routes/subscribe-forms.tsx`); a visitor who sends one becomes a subscriber in the merchant's Marketing Suite. The starter adds only the states their design lacks (`SUBSCRIBE_POPUP_CLASSES` in `app/lib/subscribe-forms.ts`). Never build a sign-up pop-up of your own.
- **The embedded subscribe form** in the footer: `<SubscribeForm>`, the merchant's form in the page's look.
- **The store's other forms:** the contact form (`/contacts`), the product's (`app/components/ProductRequestForms.tsx`: "Let me know when it is back", "Ask about this product" for products sold on request, the fast order), the return (`/withdrawal`). Each posts through a route action to the API, shows its `userErrors`, and is real: a subscriber, a message to the merchant, an order. Send one only with the user's word (SKILL.md, "What reaches the live store").

## The visitor's own data and the cache

- **Shared pages** come from the page cache, and the visitor's own parts from `/visitor` in the browser (`references/speed.md`, "The page cache").
- **A signed-in customer's** wishlist and policy consent request come with the root's deferred data, in one query (`SIGNED_IN_CUSTOMER_QUERY`); their pages are never cached.
- **Private pages** send `privatePageHeaders` (`Cache-Control: private, no-store`): the account, the cart, a data request's form, the return pages.
- **Lists kept in the browser:** the recently viewed products and the comparison (`app/lib/product-lists.ts`, in `localStorage`), sent to the store only when a page asks for those products. The comparison is off by default (`COMPARE_ENABLED` in `app/lib/features.ts`): turn it on only for a store whose products have properties to compare. The wishlist is the signed-in customer's, kept by the store.

## SEO and security underneath

- `robots.txt` and `/llms.txt` routes, `noindex` on every host but the store's domain (`storeDomain` in `server.ts`), the platform's sitemap: `references/seo.md`.
- The session cookie written by `server.ts`, the CSP's nonce on every inline script, redirect targets through `localRedirectPath`: `references/quality.md`, "Security".
