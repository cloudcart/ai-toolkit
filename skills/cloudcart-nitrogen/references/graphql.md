# GraphQL and data in a Nitrogen storefront

The rules of stage 2 of the skill, the build, with the patterns the starter uses. The API is the CloudCart Storefront GraphQL API; `storefront` and `customerAccount` come from the request context that every loader and action receives (`context.storefront`, `context.customerAccount`).

## GraphQL, not REST

A REST API has an endpoint for each resource: a page calls several of them and joins the answers. GraphQL turns this around. The page sends one document that describes the whole shape it renders, such as the product with its variants, its brand and its pictures, and the API follows the relations on the server. Most mistakes in a storefront's data come from writing GraphQL as if it were REST.

A page splits its data into several calls for these reasons only:

- **A different cache lifetime or client:** the merchant's settings (`CacheSettings()`) apart from the catalogue, and the customer's own data through `customerAccount`, which never caches.
- **A different moment:** what the first screen needs (awaited) apart from what is below it (deferred).
- **A real dependence:** a call that needs another's answer. The product page's reviews wait for the settings that say whether the store shows them.
- **A Nitrogen helper that runs its own query:** `getCookieConsent()` and `getMarketingPixels()` share one call, and the cart has its own (`context.cart`). Use the helper; do not copy its fields into your document.

Never split a page's data one call per resource. The starter's product page makes four calls, each for one of these reasons (`app/routes/product.$handle.tsx` and its parent `app/routes/product.tsx`).

Each habit below shows in the code, and has a GraphQL way. Look for them when you write a query, and when you review one:

| The REST habit | How it shows in the code | The GraphQL way |
|---|---|---|
| A call per resource | A module of helpers such as `getProduct()`, `getCollection()` and `getMenu()`, each running one root field, and a loader that awaits several of them with the same cache | One colocated document with every root field the page needs at that moment |
| The whole resource everywhere | One large fragment, or the same long selection, spread on pages that render a few of its fields | A fragment for each component, with only the fields it renders, spread by the pages that render that component: a fragment is for colocation, not for reuse |
| Related data fetched by id | An `id` or `handle` from one answer passed to another `storefront.query` in the same loader; a query inside `.map()` or a loop over `nodes` (an N+1) | Nest it in the same document (`product { vendorDetails { … } }`), and select a list's items through a fragment on its `nodes`. Ids the page already holds (a merchant's hand-picked products) come in one call: `nodes(ids:)`, with a fragment on each type (`... on Product`) |
| A value written into the document | `${…}` inside a `#graphql` document with anything but a fragment's text (`${PRODUCT_ITEM_FRAGMENT}` is right); a document built with `+`, `.replace()` or `.join()` | Declare a variable (`$handle: String!`) and pass the value in `variables`. A value written in can break the document or change what it asks, and each value makes a new document that the API parses and caches again |
| A second call for the same field, or for an optional part | Two documents that differ only in their arguments; a call made only when a flag is set | Aliases in one document (the home's `featured: products(…)` and `newest: products(…)`), and `@include(if: $withList)` for a part only some visits need (the product page's reviews) |
| A query after a mutation | `storefront.mutate(…)` and then `storefront.query(…)` in the same action, to read the new state | Select what the page needs in the mutation's payload: the cart's mutations answer with the `cart` |
| Filtering, sorting or paging in code | `.filter()`, `.sort()` or `.slice()` on `nodes`; `first: 100` on a catalogue list (`products`, `search`) "to get everything". One item's own lists, such as a product's variants or a customer's addresses, are rightly asked whole | The API's arguments: `filters`, `query`, `sortKey` with `reverse`, and `first` with `after`. A page holds at most 100 items: a larger `first` is cut to 100 |
| Calling the endpoint | `fetch()` to `/api/sf` or to the store's API in the app's code | `context.storefront.query` in a loader, and an action for a change: they bring the cache, the profiler, the tokens and the buyer's IP |
| An anonymous operation | `query {` or `query(` with no name | Name each operation after its purpose (the starter's `query Product(…)`, `query HomeProducts(…)`): the profiler lists the calls by their names, and an anonymous one shows none |
| An answer taken as all or nothing | Reading a status code, or a `try`/`catch` as the only error handling around `storefront.query` | An answer can carry `data` and `errors` together: a field that failed is `null`, and the rest is there. `storefront.query` throws only when the request itself fails, and returns GraphQL errors as `errors` beside the data. Render without a part that is `null`, and read `errors` where a missing part matters |
| A list of products inside a list, paged or filtered | `products` or `relatedProducts` with `after`, `last` or `filters` inside the `nodes` of `collections`, `vendorsConnection`, `products` or `nodes`; an outer `first` the URL sets | Below |

### A list inside a list

The API loads the first page of a list inside a list for all the items at once, so it costs the same whatever the number of items. A page after a cursor, the last items, and a list's `filters` are fetched for each item alone. The same query, measured on a test store with 3 items and with 9:

| Inside each item | 3 items | 9 items |
|---|---|---|
| A product's pictures, variants, categories, files, linked products or reviews (`products` › `images`, …) | 33 to 36 database queries | the same |
| A category's products (`collections` › `products(first: 10)`) | 35 database queries, 1 catalogue search | 35, 1 |
| A brand's products (`vendorsConnection` › `products(first: 10)`) | 37, 1 | 37, 1 |
| A product's related products (`products` › `relatedProducts(first: 10)`) | 57, 2 | 57, 2 |
| A category's next page or last items (`products(first: 3, after: …)`, `products(last: 3)`) | 83, 4 | 195, 11 |
| A category's filters (`products(first: 3) { filters { … } }`) | 57, 4 | 125, 10 |

- **Inside a list, ask each item's first page.** `first` without `after`. The next page of one item, its last items and its `filters` are asked for that item alone: on its own page, or, to page it in place (a carousel's "next"), from a resource route the page loads with `useFetcher().load()`, as the starter's `app/routes/related-products.tsx` pages one product's related products.
- **Keep both lists short.** The cost no longer grows with the items, but the answer does: every item brings its `first` products, each with the fields its card asks for. Keep the outer list fixed in the document (`collections(first: 4)`, not a `first` the URL sets) and the inner `first` small (`products(first: 4)`); ask only the lists the page renders.
- **The API does not refuse such a query.** Its complexity counts a list once, whatever its `first`, so only the document keeps it small.

## Colocation

- A route's query is a `#graphql` template literal in the route module, below the component, ending in `as const`. A query that several routes run (a category, a vendor and a tag page all list products) lives in one module under `app/lib/`.
- A fragment that several pages spread — the product card's, `PRODUCT_ITEM_FRAGMENT` — lives in `app/lib/fragments.ts`, the starter's module of shared fragments, and names the fields the card renders. The page's query spreads it (`...ProductItem`) and interpolates its text (`${PRODUCT_ITEM_FRAGMENT}`), so the card and its data change together. Fragment names are unique across the app.
- Select only what the page renders. A field "for later" costs every visit, and it counts toward the query's complexity.
- A field goes into the fragment of what renders it. When only one page shows it (a category's product count on `/categories`), it goes into that route's own fragment, not into a shared one (`...CollectionCard`), which would carry it on every page that spreads it.
- Read each field's type in the schema: `Int` may be null, `Int!` never is. Render nothing for a null, rather than a zero or an empty label.
- After changing a `#graphql` document, run `npm run codegen`. It regenerates `storefrontapi.generated.d.ts`, which types what `storefront.query` returns for that document. Commit the regenerated file with the change.

## The loader: critical and deferred data

One request per page: the route `loader` runs on the server and gathers everything the page needs. Await only what the first screen shows; start the rest first, and return it as promises.

```tsx
export async function loader(args: Route.LoaderArgs) {
  // Start what is below the fold first: it needs nothing from the critical query, so it runs beside it…
  const deferredData = loadDeferredData(args);
  // …and wait only for what the first screen needs.
  const criticalData = await loadCriticalData(args);
  return {...deferredData, ...criticalData};
}

async function loadCriticalData({context, params}: Route.LoaderArgs) {
  const {product} = await context.storefront.query(PRODUCT_QUERY, {variables: {handle: params.handle}});
  if (!product) throw new Response(null, {status: 404});
  return {product};
}

function loadDeferredData({context, params}: Route.LoaderArgs) {
  // Not awaited. A failure must not fail the page: catch it and render without the section.
  const reviews = context.storefront
    .query(REVIEWS_QUERY, {variables: {handle: params.handle}, cache: context.storefront.CacheShort()})
    .catch((error: Error) => {
      console.error(error);
      return null;
    });
  return {reviews};
}
```

The page renders a deferred value in `<Suspense>` with React Router's `<Await>`. The loader's `.catch` turns a failure into `null`, which the section renders as nothing; `errorElement` is the safety net for a rejection that escapes it:

```tsx
<Suspense fallback={<ReviewsSkeleton />}>
  <Await resolve={reviews} errorElement={null}>
    {(data) => (data ? <Reviews data={data} /> : null)}
  </Await>
</Suspense>
```

- **A section below the first screen** (a strip of brands under the home's categories) takes its fields from the page's existing deferred query when the page has one (the home's `HomeProducts`). It then neither holds up the first byte, as a field in the critical query would, nor adds a call, as its own query would.
- **A list the visitor may never reach** — a product's related products, its linked ones, the recently viewed — is asked for only as the visitor nears it, so a visit that stops at the first screen costs nothing for it. A resource route gives its pages, and the section loads the first with Nitrogen's `useAutoLoad(ref, {load, limit: 1})` on its own element: card placeholders hold its room (two rows of them for the related products), so nothing below moves when the products come; a section most products lack (the linked products) shows nothing until the answer, rather than a placeholder that comes and goes. The starter's `RelatedProducts`, `LinkedProducts` and `RecentlyViewed` do so; such a route is measured on its own, not in the page's budget.
- Calls that do not depend on each other run together (`Promise.all`), never more than 6 at a time: a Worker has at most 6 simultaneous outgoing connections per request.
- A query that needs another's answer waits for it. Chain such queries only when the data really depends on the first answer: each link adds a round trip.
- **A part that does not follow the address.** A route's loader runs again whenever its address changes, the whole of it: a product page's runs for each variant chosen (`?Color=Red`). Put a part that does not follow that change in a parent route whose `shouldRevalidate` reloads it only for what it follows. The starter's `app/routes/product.tsx` holds a product's reviews, which reload for another product or another page or star filter of the reviews, not for a variant; the page (`app/routes/product.$handle.tsx`) does not reload for the reviews' own page or filter. Two routes that need the same query (the store's settings) send the identical document: Nitrogen sends an identical query in flight once.

## The request budget

Each page has a budget of calls to the API, measured in the profiler (`references/verification.md`). The starter's pages measure:

| Page | Calls |
|---|---|
| home | 3 |
| category | 2 |
| product | 4 warm, 5 cold |
| search | 2 |
| cart | 2 |

These are counted as `references/verification.md` says, on the page's first load after another page has loaded (so the shop, the menus and the consent are already cached): the page's own calls plus the footer's subscribe forms, which are never cached. A search counts with a term. A first load on a fresh dev server also counts the shared calls, so load another page first. A change that adds a call to one of these pages needs a reason, and you report it to the user. A new page of a kind in the table has that kind's budget: a new page that lists products has a category's 2 — its own query and the subscribe forms. A new kind of page has no budget yet: aim for one critical call and as few deferred ones as the page needs, and report the count you measured, which becomes its budget.

## Cache strategies

`storefront.query(QUERY, {variables, cache})`. Without `cache`, a query gets `CacheDefault()`: fresh for 1 second, then served stale for up to a day while it refreshes. Mutations are never cached. A cached answer is stored under the query together with its variables: a query that passes the buyer is cached for that buyer alone, and never served to another visitor.

| Data | Strategy |
|---|---|
| Menus and static lists | `CacheLong()`: fresh for 1 hour, then stale for 23 more while it refreshes |
| Settings the merchant edits in the admin: the shop's name, logo, domain and contacts, policies, `llmsTxt` (read by `robots.txt`), a form's fields and countries | `CacheSettings()`: fresh for 1 minute, then stale for up to a day while it refreshes |
| Catalogue pages: products, categories, search, content | `CacheShort()` (fresh for 1 second, then stale for 9 more) or the default |
| What visitors must see at once after they change it (their own comment still awaiting approval, say) | `CacheNone()`, while they are signed in |

`customerAccount.query` always uses `CacheNone()`. "Signed in" means `customerAccount.getBuyer()` returned a buyer. The starter's article page shows a signed-in reader their own comments that are still waiting for approval, so it skips the cache for them:

```ts
cache: buyer ? storefront.CacheNone() : storefront.CacheShort(),
```

## The signed-in buyer

```ts
const buyer = await context.customerAccount.getBuyer();
const data = await context.storefront.query(PRODUCT_QUERY, {variables: {handle, buyer}});
```

```graphql
query Product($handle: String!, $buyer: BuyerInput) @inContext(buyer: $buyer) {
  product(handle: $handle) { ... }
}
```

- The customer's own data (orders, addresses, wishlist) is read with `customerAccount.query` and changed with `customerAccount.mutate`. They add the access token from the session and never cache.
- The token never goes in an `Authorization` header: the API takes it as an argument or through `@inContext(buyer:)`.

## The API's names

The Storefront API names some things differently from the admin: a brand is a `Vendor` (`vendorsConnection`, `vendor(handle:)`, `Product.vendorDetails`; its page `/vendor/{handle}`, `vendorPath` in `app/lib/urls.ts`, and the list of them `/vendors`); a category, and a merchant's selection, is a `Collection` (`collections` lists the categories, `collections(kind: SMART_COLLECTION)` the selections); a product tag is a `ProductTag`; a blog category is a `Blog`; a physical store is a `StoreLocation`. Some of Shopify's names do not exist here (`productByHandle`, `metafields`, `checkoutCreate`). Look a name up with the Storefront MCP's `introspect_graphql_schema`, and read its `learn_cloudcart_storefront` for what the schema does not show (the server owns every price, how a cart is addressed, how the checkout works). A category's, selection's, brand's or tag's products, or `products`, asked without a `sortKey` come in the store's own order — its listing setting, or best sellers first when it set none (a search in relevance order); newest first is `sortKey: CREATED_AT, reverse: true`: `CREATED_AT` alone is oldest first.

## Pagination

Lists are connections (`nodes`, `pageInfo`) that take `first`/`after` and `last`/`before`, both directions working. The loader reads the page from the URL; the page renders `<Pagination>`. For a list of products or cards, reuse the starter's: `PaginatedResourceSection` (from `@cloudcart/nitrogen-react`, a "load more" list built on `<Pagination>`) for a list in a fixed order, and `ProductListing` (`app/components/`) only where the visitor filters and sorts, since it brings that toolbar. A fixed-order grid of product cards takes the listing's columns (`LISTING_GRID_CLASSES`) and, with no filters beside it, `FULL_WIDTH_CARD_SIZES` for the cards' `sizes` (both in `app/components/ListingToolbar.tsx`; `LISTING_CARD_SIZES` is for the grid beside the filters).

```ts
const variables = getPaginationVariables(request, {pageBy: 24});
// → {first, endCursor} going forward, {last, startCursor} going back.
// It reads only its own parameters, so `request` is safe here (see "The page's address" in SKILL.md).
```

```graphql
products(first: $first, last: $last, before: $startCursor, after: $endCursor) {
  nodes { ...ProductItem }
  pageInfo { hasPreviousPage hasNextPage startCursor endCursor }
}
```

```tsx
<Pagination connection={collection.products}>
  {({nodes, NextLink, PreviousLink, isLoading}) => (…)}
</Pagination>
```

Two paginated lists on one page each take a `namespace`, in both `getPaginationVariables` and `<Pagination>`. Never load a whole catalogue to page through it in the browser: a store can have millions of products.

## Mutations and forms

- A form posts to a route `action`. The action calls the mutation, and returns its `userErrors` (`field`, `message`, `code`; `customerUserErrors` for the customer's own mutations) for the form to show next to the field they name. Never throw them.
- When the API refuses the whole operation (it answers with `errors` and no payload, a variable it could not take, say), the action returns a general form error that the page shows in the store's words, and logs the details on the server; they are a developer's, never shown to the buyer. The starter's `app/lib/action.ts` has `payloadOf` and `API_ERROR` for this.
- The cart has its own: `<CartForm>` posts a cart action to the cart route, and `<AddToCartButton>` is built on it. `useOptimisticCart` shows the change before the answer arrives.
- Never `fetcher.reset()` a fetcher that may still be working, a shared key's above all: after its action answers, the router reloads the page's data under it, and a reset then aborts that reload — the cart stays old — and leaves the router expecting a fetcher it has dropped, so the next link throws "Expected fetcher" and goes nowhere (React Router 7). To stop showing an answer, remember the one shown and compare, as the starter's cart panel does (`CartAddRefusal` in `app/components/CartMain.tsx`).

## Money and other values

- Select `formatted` with every `amount` (`price { amount currencyCode formatted }`) and render it with `<Money>`: some markets require a dual-currency display that only the store's own formatting gives.
- `DateTime` values are UTC without a zone. Read them with `parseDateTime` and `formatDateTime`, not `new Date()`.

## Validation and limits

1. **The storefront MCP.** In a new session call `learn_cloudcart_storefront` first: it maps the whole API and names the operation for each step. Its guide is written for every client of the API; in a Nitrogen storefront this skill wins where they differ: the customer's token stays in the session cookie and never goes in an `Authorization` header (`customerAccount` sends it, and the buyer goes as `@inContext(buyer: $buyer)`); `$country` and `$language`, when a document declares them, are filled by Nitrogen's client; and the checkout is the platform's (`cart.checkoutUrl`), so the guide's delivery, payment and `cartSubmitForCompletion` steps are not the storefront's. Then check every new or changed document with `validate_graphql_codeblocks`. It also catches mistakes that pass schema validation and still fail, such as `amount` without `formatted`. Use `introspect_graphql_schema` to look up a type or field.
2. **`npm run codegen`** types every `#graphql` document against the schema shipped with Nitrogen (`@cloudcart/nitrogen/storefront.schema.graphql`, the file `node_modules/@cloudcart/nitrogen/dist/storefront.schema.graphql`: search it for a field), and fails on a field or argument the schema lacks.
3. **Limits.** The API refuses a query that is more than 10 levels deep or has a complexity over 1000. A page's queries stay within both. The complexity does not grow with a list's `first`, so it does not catch a list inside a list ("A list inside a list", above).
