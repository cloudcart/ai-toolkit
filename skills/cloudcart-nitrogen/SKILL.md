---
name: cloudcart-nitrogen
description: "Build or change a CloudCart headless storefront made with Nitrogen — a React Router app whose package.json depends on @cloudcart/nitrogen. Use for any change to such a storefront: a new page or route, a component or section, the design, a GraphQL query or mutation, a form, caching, the cart, the customer account, analytics, SEO, speed, or a review of such a change. Five stages in order: the store's niche and a mobile-first design; the build on Nitrogen's building blocks with GraphQL that fetches only what the page renders; SEO and security; the analytics and the merchant's pixels; a whole-site review — caching, queries, SEO, a mobile speed score of 90 or more. Covers Nitrogen 2.3. In Bulgarian: витрина с Nitrogen, headless магазин, нова страница, нов компонент, дизайн, мобилна версия, GraphQL заявка, кеширане, бързодействие, количка, профил на клиента. NOT for the Admin API or a store's own data (use cloudcart-product-management), and NOT for how the platform itself behaves (use cloudcart-platform-expert)."
when_to_use: "Whenever the project in front of you is a Nitrogen storefront (`@cloudcart/nitrogen` in package.json) and you are about to design, write, change or review code in it — before the first line, not after. Also when asked to add a page, section or feature to a CloudCart storefront, to design one for a kind of store, to speed up a storefront page, or to check a storefront change, and to show the merchant's metafields or metaobjects (their own fields and content types) on a storefront. Transliterated Bulgarian also matches: vitrina, nova stranica, komponent, dizain, mobilna versia, zayavka, keshirane, metapoleta, metaobekti."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.4.3"
  nitrogen: "2.3"
---

# Building a Nitrogen storefront

This skill covers **Nitrogen 2.3**: `@cloudcart/nitrogen` and `@cloudcart/nitrogen-react` 2.3.x.

Nitrogen is CloudCart's framework for headless storefronts. A storefront is a React Router 7 app, created from CloudCart's starter, that runs on Cloudflare Workers and reads the store through the CloudCart Storefront GraphQL API. The checkout is the platform's own: the storefront hands the cart over through `cart.checkoutUrl`.

Work in **five stages, in this order**: the store and its design, the build, SEO and security, analytics and pixels, and a review of the whole site. A new storefront goes through all five. A smaller change goes through the stages it touches, in the same order, and always ends with stage 5 for the pages it changed. The details are in `references/`; open the one a stage points to when you reach it.

## 0. Which Nitrogen

Read `version` in `node_modules/@cloudcart/nitrogen/package.json` (install the dependencies first if `node_modules` is missing).

- **2.3.x:** this skill applies as written.
- **2.2.x:** all of it but what 2.3 added: the kept pages (`KeptLink`, `keptPageLoader`, `useKeptPages`, `keptSectionLoader` in `references/speed.md`), a variant opened by its id in the address (`loadAddressVariantOptions`, `references/design.md`), and CloudCart Analytics' events and the real visitors' speed sent from the browser (`references/tracking.md`); on 2.2 a step back loads the page again and the API sends the events itself. Moving to `^2.3.0` removes no export, but the kept pages are the project's code too — each shared route's `clientLoader`, the root's `useKeptPages` and the links — and over HTTPS the session cookie becomes `__Host-session`, so a signed-in customer signs in once more: propose it to the user, and until then skip what this skill says of the kept pages.
- **2.1.x:** as 2.2.x, and without the metafields and metaobjects (`references/metafields.md`): 2.1 ships a schema without them, so `npm run codegen` refuses their fields, and it has no `<MetafieldRichText>` and fewer of `parseMetafield`'s types.
- **2.0.x:** as 2.1.x, and without the page cache (`createPageCache`, and the visitor's own data from `/visitor`), which came with 2.1: on 2.0 every page is rendered for each request. The page cache is the project's code too — the starter's `server.ts`, `app/lib/page-cache.ts`, `app/routes/visitor.tsx`, `app/lib/visitor.server.ts` and the root's visitor parts: until it is there, skip what this skill says of the page cache: no route gets `handle = SHARED_PAGE`, and stage 5's `MISS`-then-`HIT` check is not made.
- **Another major or minor version:** tell the user that this skill may lag that release. The installed packages' `EXPORTS.md` and `README.md` always describe the installed version: where they differ from this skill, follow them.

## Before you write code

Every task starts here, before the first line, however small:

1. **The API, from the storefront MCP.** Call `learn_cloudcart_storefront` once in a session; it answers with the `conversationId` the other tools take, and names the operation for what you want to do when you do not know its name. Then look up each type, query or mutation the task touches by name with `introspect_graphql_schema` (`Product`, `Cart`, `predictiveSearch`). What they already give — a price as `formatted`, a discount, a count, a field you were about to compute — decides what the page asks for, and what it must never compute itself. The MCP is `@cloudcart/storefront-mcp`, which the CloudCart plugin registers; if your host lists its tools as deferred, load them; if it is not installed, say so in your report.
2. **The starter's way.** Open the starter's nearest page and components (the table below), and `references/storefront-foundations.md`: what the starter already gives every storefront — the frame around the pages, analytics and its events, cookie consent and the data requests, scripts from outside, the pop-ups and forms.
3. **The merchant's own data.** When the page shows something the platform has no field for — a size chart, specifications, a designer, a section the merchant edits — open `references/metafields.md`: the wiki's use case for it, what the merchant sets up, and how to read and show it.
4. **A reuse map.** Before a new page or section, write it down and show it to the user: what exists and is used as it is (a component, a fragment, a helper, a Nitrogen export), what is extended (a prop or a variant of a component that exists), and what is missing and becomes a building block (stage 2). For a small fix, it goes into your report.
5. **The page's elements.** List every element the page shows — from the design, or from the starter's page — and every state it can be in: loading, empty, failed, signed in or out, sold out, one picture or many. Stage 5 checks each of them.
6. **The "before".** Measure the page as it is: its calls and its times (`references/speed.md`). A new page has no "before": measure the nearest page of its kind, and the new one after.

**Build on the starter, never over it.** The storefront's look is the project's own code — the merchant's theme in the admin plays no part in it (stage 5). A change goes through the design tokens (`app/styles/app.css`) and the props of the components that exist. Never a second component beside one that does the same job (another product card, another price), never CSS that overrides a component's own, never a copy of a starter file to change it there. When a component lacks something, extend it where it is, so every page that uses it gets it.

## The starter is the reference

The project was created from CloudCart's starter (the public template `cloudcart/nitro-starter`), so its files are in the project; where the project has changed one, the template on GitHub (`github.com/cloudcart/nitro-starter`) has the original. The starter is how things are done in a Nitrogen storefront: its speed, caching, SEO, security, analytics, forms and design are the standard a change meets. Before you write a page, a section or a form, open the starter's nearest one and do it the same way; where this skill and the starter's code agree, the code is the worked example.

| What | Where the starter shows it |
|---|---|
| Critical and deferred data | `app/routes/_index.tsx` (`loadDeferredData`), `app/routes/product.$handle.tsx` and its parent `app/routes/product.tsx` (the reviews, which a variant change does not reload) |
| Pictures: the first eager, the rest lazy | `app/components/ProductGallery.tsx`, `app/components/Hero.tsx` |
| Cache strategies | `app/root.tsx` and `app/lib/product-page.ts` (`CacheSettings()` for the shop and the merchant's settings), a visitor's own answer kept from every cache by Nitrogen's request handler (`context.personal.mark()` for what it cannot see) |
| The page cache and the visitor's own data | `server.ts` (`createPageCache`), `app/lib/page-cache.ts` (`SHARED_PAGE`), `app/routes/visitor.tsx`, `app/lib/visitor.server.ts` |
| A page that opens at once | `app/components/PageTransition.tsx`, `app/components/PendingPage.tsx`, `app/lib/opening.ts` |
| What is around every page | `AppShell` in `app/root.tsx`, `app/components/PageLayout.tsx` (`references/storefront-foundations.md`) |
| SEO | `app/lib/meta.ts`, each route's `meta`, `app/routes/[robots.txt].tsx` |
| Security | `server.ts` (Nitrogen's request handler, `storeDomain`), `app/entry.server.tsx` (the CSP), Nitrogen's `localRedirectPath` (a redirect target from the request), a visitor's own answer `private, no-store` (Nitrogen's request handler; `context.personal.mark()`) |
| Analytics | `app/root.tsx` (`<Analytics.Provider>`), `app/lib/analytics.ts` (`listedProducts`), each page's view |
| Listings and cards | `app/routes/category.$handle.tsx`, `app/components/ProductListing.tsx`, `app/components/ProductItem.tsx` |
| Forms | `app/components/ProductRequestForms.tsx`, `app/components/ui/Field.tsx` (16 px text on a phone), the routes under `app/routes/account*` |
| Design | `app/styles/app.css` (the tokens), `app/components/ui/` |

The starter's pages are held to the same targets as yours: the request budget (`references/graphql.md`) and stage 5's review. When the project's copy has drifted from the starter in a way this skill says is wrong, follow the skill and tell the user.

## What reaches the live store

- **A push deploys.** The platform's workflow in the repository (`.github/workflows/nova-deploy.yml`) deploys a push to the default branch to the merchant's live storefront, and an older copy of it deploys a pull request too: read it. Push, open a pull request or run `cloudcart nitrogen deploy` only when the user says so. `deploy` needs the storefront's deployment token in `CLOUDCART_NOVA_TOKEN` (`.env`), made in the admin on the storefront's Deployments tab, under Deployment tokens; `cloudcart llms-context` describes every CLI command.
- **The dev server and GraphiQL work on the live store.** A fast order, a contact or inquiry form, a review, a newsletter sign-up, a subscription or a back-in-stock request sent from them is real: an order, a mail, a subscriber. Send one only with the user's word, and tell them what it made.
- **Test visits** can reach the merchant's ad accounts: stages 4 and 5 say when to ask.

## Stage 1. The store and its design — `references/design.md`, `references/store-kinds.md`

Decide what the storefront looks like and holds before writing code: the pages, their sections and the data each one shows. That decides the components and the queries of stage 2.

- **The store's niche.** Ask which kind of store it is (fashion, electronics, food, …), or read it from the catalogue. The kind decides the structure of the search, the listings, the product cards and the product page: `references/store-kinds.md`.
- **Mobile first.** Design every page for a phone first (360–390 px wide), then add what a wider screen allows. A phone's small screen and slower network are the hardest case, and stage 5's speed target is measured on one.
- **The best practice of UX** for a store: the search, the listings, the cards, the product page, the cart and the feedback on every action, in `references/design.md`.
- **What the merchant edits without code.** Sections, banners, a size chart, a designer's profile: model them with metaobjects and metafields, from the wiki's use cases (`references/metafields.md`), and agree the model with the merchant before the pages.
- **One accent colour, and one or two complementary ones.** The accent marks what the visitor acts on (the main button, links, focus); a complementary colour marks products (a discount); everything else is neutral. They are design tokens: in the starter, `--color-accent` and `--color-highlight` in `app/styles/app.css`. Set them from the merchant's brand, with enough contrast.

## Stage 2. The build — `references/graphql.md`, `references/speed.md`, `references/building-block.md`, `references/metafields.md`

### Look it up, then use it

1. **Read the export maps of the installed version.** `node_modules/@cloudcart/nitrogen/EXPORTS.md` is the core: the Storefront API client and its cache strategies, the cart, the customer account, analytics, SEO, the CSP, translations, pagination, routing and the Vite plugin. `node_modules/@cloudcart/nitrogen-react/EXPORTS.md` has the React components and hooks: `Money`, `Image`, `ProductPrice`, `AddToCartButton`, `RichText`, `PaginatedResourceSection`, the privacy banner, the subscribe forms and more. Each export has its kind and the first sentence of its documentation; the full documentation is on the export itself, and each package's `README.md` explains the wiring.
2. **Look at what the project already has,** and at the starter's nearest page (above). Then search `app/routes/` (one file per page), `app/components/` (small UI pieces in `app/components/ui/`), `app/lib/` (helpers, fragments, the platform's page addresses in `urls.ts`, the `meta` helpers in `meta.ts`), `app/building-blocks/` once the project has one (below, "A missing building block") and `app/locales/` (one JSON file per language).
3. **Use what exists.** Never re-create a piece that Nitrogen or the project already has: a price, an image, a cart form, pagination, SEO tags, a consent banner, a translation helper. If a piece almost fits, use its props or wrap it. If a Nitrogen piece is wrong, report it to the user, and do not fork it.
4. **Take data from the API; never derive it.** Prices and totals come as `formatted`, the discount from `Product.discount`, the cart's totals from `Cart.totals`. If the API gives a wrong value, report it, and do not compute around it. One exception: a quantity tier card's figures for pieces of several variants, which the API cannot give one by one, are added up from the variants' per-piece prices (`ProductVariant.quantityDiscounts`) by the cart's rule and written with the store's format (`moneyWithFormat` with `Shop.currencyFormat`), as the starter's `app/lib/quantity-tiers.ts` does. Pages keep the platform's addresses (`/product/{handle}`, `/category/{handle}`, …), and the checkout stays the platform's.
5. **The merchant's content** (pages, articles, descriptions) is HTML from the store: render it with `<RichText>`, which names an untitled embedded frame (`<iframe>`) from its source, so a screen reader can announce it. When a page embeds frames, tell the merchant to give each one a `title`.

### GraphQL that fetches only what the page renders

- **GraphQL, not REST.** One document for each moment of the page asks for the whole shape it renders. A page splits its calls only by cache lifetime, by critical and deferred data, when one call needs another's answer, or where a Nitrogen helper runs its own; never one call per resource. Values go in variables, related data is nested, the same field twice is an alias, an optional part is `@include`, a mutation's payload carries the new state, and the API filters, sorts and pages. A list inside a list asks each item's first page, for a few items fixed in the document. The REST habits, and how each shows in the code: `references/graphql.md`.
- **Colocated.** A query lives in the route module that runs it; one that several routes run lives under `app/lib/`. A fragment that one route uses lives in that route; one that several share lives beside the component that renders it (`COLLECTION_CARD_FRAGMENT` in `CollectionGrid.tsx`) or, when no one component owns it — the product card's, the user errors' — in `app/lib/fragments.ts`; the query spreads it. **Select only the fields the page renders**: a field "for later" costs every visit.
- **One server request per page.** Data loads in the route's `loader`. Await only what the first screen needs; start the rest first and render it in `<Suspense>` with `<Await>`. A section below the first screen takes its fields from the page's existing deferred query; a list of products the visitor may never scroll to is asked for only as they near it (`references/graphql.md`).
- **Within the page's request budget.** Independent calls run together, never more than 6 at a time (the Workers limit). No N+1: a list's items come in the list's own query.
- **No client-side fetching of server data.** The browser gets data from loaders, and changes it through the app's actions: `<CartForm>`, or `useFetcher` posting to a route. It reaches sf only through the storefront's own `/api/sf` proxy, and only for what Nitrogen does there itself: a customization file's upload (`uploadCartCustomizationFile`), the cookie consent and the analytics events.
- **Pagination** with `getPaginationVariables(request, {pageBy})` in the loader, and `PaginatedResourceSection` (or `<Pagination>`) in the page; both directions work.
- **The right cache strategy** for each query: `CacheLong()` only for menus and static lists, `CacheSettings()` (a minute) for settings the merchant edits, `CacheShort()` or the default for the catalogue and content, `CacheNone()` for what visitors must see at once after they change it. A query that passes the buyer is cached for that buyer alone.
- **The page cache** for a page that is the same for every visitor who is not signed in: `handle = SHARED_PAGE`, with nothing of the visitor's in its loader — their own parts come from `/visitor` in the browser (`references/speed.md`).
- **A page that opens at once:** a click shows the page being opened from what the link already showed, and its data fills it in place; a next page starts loading before the visitor reaches it (`references/speed.md`).
- **The signed-in buyer** goes to the API as the `buyer` variable with `@inContext(buyer: $buyer)`, from `customerAccount.getBuyer()`. The customer's own data is read with `customerAccount.query` and changed with `customerAccount.mutate`, which never cache.
- **The page's address.** A loader or action reads it from its `url` argument, never from `new URL(request.url)`: with React Router's v8 flags, `request` is the data request (`/product/x.data?_routes=…`). Nitrogen's helpers that take a `request` correct this themselves.
- **Validate every query and mutation** with the storefront MCP's `validate_graphql_codeblocks` (you called `learn_cloudcart_storefront` before writing code; should its guide ever differ from this skill, this skill wins), then `npm run codegen`. Codegen does not replace it: it checks the schema only, and the MCP also catches documents that pass the schema and still fail. The storefront MCP is `@cloudcart/storefront-mcp`, which the CloudCart plugin registers; the Dev MCP (`@cloudcart/dev-mcp`) has a tool of the same name that checks the Admin API only, never a storefront document. If your host lists the MCP's tools as deferred, load them; if the MCP is not installed, say so in your report. The API refuses a query deeper than 10 levels or with a complexity over 1000.
- **Mutations** answer with `userErrors` (`customerUserErrors` for the customer's own): show them next to their field; never throw them.

### A missing building block

Build it the way Nitrogen builds its own, so it can move into Nitrogen as it is: in `app/building-blocks/`, one file per block with its test beside it; unstyled, with `cc-<block>-<part>` class hooks and `classNames`; its data through props, typed from its fragment; links through props; documented; tested with vitest; named to the user as a candidate for Nitrogen. The details are in `references/building-block.md`.

## Stage 3. SEO and security — `references/seo.md`

**SEO**, for every indexable page:

- Rendered on the server; `meta` with the starter's `seoMeta` (title, description, the canonical on the store's domain, image), `privateMeta` on a private or form page.
- A listing's pages each their own canonical (`listingUrl`); structured data (Product, Organization, Article, BreadcrumbList) with Nitrogen's helpers; a description on every page; alt text on content images; a 404 for a missing record.

**Security:**

- **Tokens stay on the server.** `PUBLIC_STOREFRONT_API_TOKEN` may reach the browser. `PRIVATE_STOREFRONT_API_TOKEN` and `SESSION_SECRET` are used only in server code, never in a component, a client module or anything rendered. Values live in `.env`, which is never committed, and in the storefront's environment in the CloudCart admin (`cloudcart nitrogen env pull`). Never print them.
- **The customer's access token** stays in the signed session cookie, and Nitrogen's `customerAccount` sends it. Never in a URL, browser storage, client code or an `Authorization` header.
- **The CSP nonce.** Every inline script carries the request's nonce: nitrogen-react's `<Script>`, or `useNonce()`. A third-party source is added to the policy in `app/entry.server.tsx`. Never loosen the CSP to make a script run.
- **Forms are validated by the API:** a route action submits to the mutation and shows its `userErrors`. Checks in the browser are a convenience only.
- **A customer's data goes only to that customer:** read with `customerAccount.query`. Nitrogen's request handler answers a visitor's own page `private, no-store` by itself — a signed-in customer's, one that reads or changes the cart, a form's, one that sets a cookie — whatever a route's `headers` said; a loader that reads a record by a reference the visitor holds (a return by its reference) says so with `context.personal.mark(reason)`. Such a page is never in the page cache. A page is shared only through the page cache, which renders it without the visitor's cookies and leaves their own parts to the browser (`references/speed.md`); never set a shared `Cache-Control` yourself.

## Stage 4. Analytics and the merchant's pixels — `references/tracking.md`

- **The wiring stays as the starter has it:** `<Analytics.Provider>` in the root, with the shop, the cart, the consent and the merchant's pixels from the admin. Never add a vendor's script by hand.
- **Each page renders the view for its kind** (`<Analytics.ProductView>`, `<Analytics.CollectionView>`, …), once; a page of another kind renders none.
- **Check that they fire:** a dev server sends nothing to CloudCart Analytics; in the browser's console, one `[nitrogen] CloudCart Analytics: PAGE_VIEW (…)` per page view, plus the page's own view (`VIEW_CONTENT` on a product, `SEARCH` on a search; the cart page's view is its `PAGE_VIEW (CART)`, and opening the cart drawer shows `VIEW_CART`); an add to cart shows `ADD_TO_CART` once. In the network panel, before the visitor's choice, no request to a vendor of a group that waits for consent; after it, the vendors receive the page's events — real events in the merchant's ad accounts: ask the user first (`references/tracking.md`). Report what you saw, or that you could not open a browser.

## Stage 5. The review of the whole site — `references/verification.md`, `references/quality.md`, `references/speed.md`

Before a release, and for every page a change touches, however small — open `references/quality.md` and go through its checklist:

- **Caching:** on a second load the profiler (`/__nitrogen/subrequests`) shows the shared data as `HIT` or `STALE`; each query has the strategy its data needs; on the deployed storefront a shared page answers `MISS`, then `HIT`; private pages are never cached.
- **The queries:** each page's calls against its budget, no N+1, none of the REST habits in `references/graphql.md`, no field the page does not render, and where a call or a field can go. Report the numbers before and after.
- **Times:** each changed page's data on a click, cached and not, and the time to the waiting page and to the page's content, with no layout shift after the click — before and after (`references/speed.md`).
- **Every element in every state:** the list you made before writing code, each element checked on a phone and a desktop.
- **SEO:** every indexable page passes `references/seo.md`'s checklist.
- **Speed:** a Lighthouse performance score of **at least 90 on a phone** (its default mobile profile) for the home, a category and a product page — Lighthouse on the production build, or PageSpeed Insights on the live site. A test visit to a store that reports server-side reaches the merchant's ad accounts: ask the user first (`references/verification.md`). Report the scores and what holds them back.
- **`npm run check` passes** (codegen, typecheck, lint, build, and the tests once there are any), and the whole checklist in `references/quality.md` is gone through.
- **Report what you measured,** with the numbers. "It should be fine" is not a measurement.
