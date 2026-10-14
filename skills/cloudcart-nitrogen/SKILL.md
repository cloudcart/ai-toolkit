---
name: cloudcart-nitrogen
description: "Build or change a CloudCart headless storefront made with Nitrogen — a React Router app whose package.json depends on @cloudcart/nitrogen. Use for any change to such a storefront: a new page or route, a component or section, a GraphQL query or mutation, a form, caching, the cart, the customer account, analytics, SEO, or a review of such a change. A checklist to work through before, during and after the change: reuse Nitrogen's building blocks, colocated GraphQL within the page's request budget, security, and measured verification. Covers Nitrogen 2.0. In Bulgarian: витрина с Nitrogen, headless магазин, нова страница, нов компонент, GraphQL заявка, кеширане, количка, профил на клиента. NOT for the Admin API or a store's own data (use cloudcart-product-management), and NOT for how the platform itself behaves (use cloudcart-platform-expert)."
when_to_use: "Whenever the project in front of you is a Nitrogen storefront (`@cloudcart/nitrogen` in package.json) and you are about to write, change or review code in it — before the first line, not after. Also when asked to add a page, section or feature to a CloudCart storefront, to speed up a storefront page, or to check a storefront change. Transliterated Bulgarian also matches: vitrina, nova stranica, komponent, zayavka, keshirane."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.4.0"
  nitrogen: "2.0"
---

# Building a Nitrogen storefront

This skill covers **Nitrogen 2.0**: `@cloudcart/nitrogen` and `@cloudcart/nitrogen-react` 2.0.x.

Nitrogen is CloudCart's framework for headless storefronts. A storefront is a React Router 7 app, created from CloudCart's starter, that runs on Cloudflare Workers and reads the store through the CloudCart Storefront GraphQL API. The checkout is the platform's own: the storefront hands the cart over through `cart.checkoutUrl`.

Work through the five steps for every change: before you build, while you write the GraphQL and the code, and before you call it done. The details are in `references/`; open the one a step points to when you reach it.

## 0. Which Nitrogen

Read `version` in `node_modules/@cloudcart/nitrogen/package.json` (install the dependencies first if `node_modules` is missing).

- **2.0.x:** this skill applies as written.
- **Another major or minor version:** tell the user that this skill may lag that release. The installed packages' `EXPORTS.md` and `README.md` always describe the installed version: where they differ from this skill, follow them.

## 1. Before building: look it up, then use it

1. **Read the export maps of the installed version.**
   - `node_modules/@cloudcart/nitrogen/EXPORTS.md` — the core: the Storefront API client and its cache strategies, the cart, the customer account, analytics, SEO, the CSP, translations, pagination, routing and the Vite plugin.
   - `node_modules/@cloudcart/nitrogen-react/EXPORTS.md` — the React components and hooks: `Money`, `Image`, `ProductPrice`, `AddToCartButton`, `RichText`, `Script`, the privacy banner, the subscribe forms and more.

   Each map lists every export with its kind and the first sentence of its documentation, grouped by the path you import it from. The full documentation is on the export itself: hover it in the editor, or read its `.d.ts`. Each package's `README.md` explains the wiring, and lists what Nitrogen leaves out on purpose and why.
2. **Look at what the project already has.** Read its `AGENTS.md` first: the starter ships one with the project's conventions, and they apply alongside this checklist. Then search `app/routes/` (one file per page), `app/components/` (with the small UI pieces in `app/components/ui/`), `app/lib/` (shared helpers, fragments, and the platform's page addresses in `urls.ts`), `app/building-blocks/` (pieces built in this project that Nitrogen lacks) and `app/locales/` (the translations, one JSON file per language) for what you are about to make.
3. **Use what exists.** Never re-create a piece that Nitrogen or the project already has: a price, an image, a cart form, pagination, SEO tags, a consent banner, a translation helper. If a piece almost fits, use its props or wrap it. If a Nitrogen piece is wrong, report it to the user, and do not fork it.
4. **Take data from the API; never derive it.** Prices and totals come as `formatted`, the discount from `Product.discount`, the cart's totals from `Cart.totals`. If the API gives a wrong value, report it, and do not compute around it. Pages keep the platform's addresses (`/product/{handle}`, `/category/{handle}`, …), and the checkout stays the platform's.
5. **The merchant's content** (pages, articles, product and category descriptions) is HTML from the store. Render it with `<RichText>`, which names an untitled embedded frame (`<iframe>`) from its source so that a screen reader can announce it. When a page embeds frames, tell the merchant to give each one a `title`.
6. **Nothing fits?** Build it as section 3 says.

## 2. GraphQL and data — `references/graphql.md`

- **Colocated.** A query lives in the route module that runs it, as a `#graphql` template literal; one that several routes run lives in one module under `app/lib/`. A fragment lives next to the component that renders its fields, and the query spreads it. Select only the fields the page renders.
- **One server request per page.** A page's data loads in its route `loader`, on the server. Await only what the first screen needs. Start the rest first, return it as promises, and render it in `<Suspense>` with `<Await>`.
- **Within the page's request budget.** The page's calls to the API are counted in the profiler (step 5). Independent calls run together with `Promise.all`, never more than 6 at a time: that is the Workers limit on simultaneous outgoing connections.
- **No client-side fetching of server data.** A component never calls the API with `fetch` or in a `useEffect`. The browser gets data from loaders, and changes it through the app's own actions: `<CartForm>`, or `useFetcher` posting to a route.
- **Cursor pagination:** `getPaginationVariables(request, {pageBy})` in the loader, `<Pagination>` in the page.
- **The right cache strategy** for each query: `CacheLong()` only for menus and static lists, a minute at most for settings the merchant edits, and `CacheNone()` for what visitors must see at once after they change it. A query is cached under its variables too, so one that passes the buyer is cached for that buyer alone. The table is in the reference.
- **The signed-in buyer** goes to the API as the `buyer` variable with `@inContext(buyer: $buyer)`, taken from `customerAccount.getBuyer()`. The customer's own data is read with `customerAccount.query` and changed with `customerAccount.mutate`, which never cache and add the token themselves.
- **The page's address.** A loader or action reads it from its `url` argument, never from `new URL(request.url)`. With React Router's v8 flags, `request` is the data request (`/product/x.data?_routes=…`), not the page. Nitrogen's helpers that take a `request` (`getSelectedProductOptions`, `getLocaleFromRequest`, `storefrontRedirect`) correct this themselves, and `getPaginationVariables` reads only its own parameters.
- **Validate every query and mutation.** Use the storefront MCP's `validate_graphql_codeblocks`; in a new session, call its `learn_cloudcart_storefront` first. Then run `npm run codegen`: it types every `#graphql` document from the schema shipped with Nitrogen, and fails on a field the schema lacks. The API refuses a query deeper than 10 levels or with a complexity over 1000.
- **Mutations** answer with `userErrors` (`customerUserErrors` for the customer's own). Read them, and show them to the buyer next to the field they name; never throw them.

## 3. A missing building block — `references/building-block.md`

Build it the way Nitrogen builds its own, so that it can move into Nitrogen as it is:

- In `app/building-blocks/`, one file per block named after it (`LowStockNotice.tsx`), with its test beside it (`LowStockNotice.test.tsx`).
- **Unstyled, with class hooks.** It carries no styles. It takes a `className`, or `classNames` and stable `cc-<block>-<part>` classes on each part if it has several. The project's theme styles it where it is used.
- **Its data through props,** typed from the fragment that selects it. The block itself never fetches.
- **Documented:** a doc comment on every export, whose first sentence says what it is.
- **Tested** with vitest. Add vitest to the project if it has none: the reference shows how.
- **Kept in one place,** and named to the user as a candidate for Nitrogen.

## 4. Security

- **Tokens stay on the server.** `PUBLIC_STOREFRONT_API_TOKEN` may reach the browser. `PRIVATE_STOREFRONT_API_TOKEN` and `SESSION_SECRET` are used only in server code, and never in a component, a client module or anything rendered. Values live in `.env`, which is never committed, and in the storefront's environment in the CloudCart admin (`cloudcart nitrogen env pull` fetches them). Never print them.
- **The customer's access token** stays in the signed session cookie, and Nitrogen's `customerAccount` sends it. It never goes in a URL, in browser storage, in client code, or in an `Authorization` header.
- **The CSP nonce.** Every inline script carries the request's nonce: use nitrogen-react's `<Script>`, or `useNonce()`. A third-party source is added to the policy in `app/entry.server.tsx` (`createContentSecurityPolicy`). Never loosen the CSP to make a script run.
- **Forms are validated by the API.** Submit through a route action to the mutation, and show its `userErrors`. Checks in the browser are only a convenience. The API rate-limits forms per visitor, from the IP that the private token lets it trust.
- **A customer's data goes only to that customer.** Read it with `customerAccount.query`, which never caches, and never put it in a response that another visitor can receive.

## 5. Verification — `references/verification.md`

- **Measure the page before and after** in the dev server's profiler, `/__nitrogen/subrequests`, under `npm run dev`. Load the page twice and count its calls to the API. Look for no new calls beyond the budget, and no N+1: the same operation repeated once per item.
- **`npm run check` passes:** codegen, typecheck, lint and build. The starter's `check` has no tests: add `npm test` to it with the first building block (`references/building-block.md`).
- **Go through the quality checklist,** `references/quality.md`: speed, accessibility and devices, SEO, consent and analytics, translations, the states between success and failure, and design.
- **Report what you measured,** with the numbers. "It should be fine" is not a measurement.
