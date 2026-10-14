# GraphQL and data in a Nitrogen storefront

The rules of step 2 of the checklist, with the patterns the starter uses. The API is the CloudCart Storefront GraphQL API; `storefront` and `customerAccount` come from the request context that every loader and action receives (`context.storefront`, `context.customerAccount`).

## Colocation

- A route's query is a `#graphql` template literal in the route module, below the component, ending in `as const`. A query that several routes run (a category, a vendor and a tag page all list products) lives in one module under `app/lib/`.
- A component that renders a product card exports the fragment for the card's fields next to itself. The page's query spreads it (`...ProductItem`) and interpolates its text (`${PRODUCT_ITEM_FRAGMENT}`), so the card and its data change together. Fragment names are unique across the app.
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
- Calls that do not depend on each other run together (`Promise.all`), never more than 6 at a time: a Worker has at most 6 simultaneous outgoing connections per request.
- A query that needs another's answer waits for it. Chain such queries only when the data really depends on the first answer: each link adds a round trip.

## The request budget

Each page has a budget of calls to the API, measured in the profiler (`references/verification.md`). The starter's pages measure:

| Page | Calls |
|---|---|
| home | 3 |
| category | 2 |
| product | 4 warm, 5 cold |
| search | 2 |
| cart | 2 |

A change that adds a call to one of these pages needs a reason, and you report it to the user. A new page of a kind in the table has that kind's budget: a new page that lists products has a category's, 2 calls. A new kind of page has no budget yet: aim for one critical call and as few deferred ones as the page needs, and report the count you measured, which becomes its budget.

## Cache strategies

`storefront.query(QUERY, {variables, cache})`. Without `cache`, a query gets `CacheDefault()`: fresh for 1 second, then served stale for up to a day while it refreshes. Mutations are never cached. A cached answer is stored under the query together with its variables: a query that passes the buyer is cached for that buyer alone, and never served to another visitor.

| Data | Strategy |
|---|---|
| Menus and static lists (`robots.txt`, a form's country list) | `CacheLong()`: fresh for 1 hour, then stale for 23 more while it refreshes |
| Settings the merchant edits in the admin | at most a minute fresh: `CacheCustom({mode: 'public', maxAge: 60, staleWhileRevalidate: 86400 - 60})` |
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

The Storefront API names some things differently from the admin: a brand is a `Vendor` (`vendorsConnection`, `vendor(handle:)`, `Product.vendorDetails`); a category, and a merchant's selection, is a `Collection`; a product tag is a `ProductTag`; a blog category is a `Blog`; a physical store is a `StoreLocation`. Look a name up with the Storefront MCP's `introspect_graphql_schema`.

## Pagination

Lists are connections (`nodes`, `pageInfo`) that take `first`/`after` and `last`/`before`, both directions working. The loader reads the page from the URL; the page renders `<Pagination>`. For a list of products or cards, reuse the starter's: `PaginatedResourceSection` (from `@cloudcart/nitrogen-react`, a "load more" list built on `<Pagination>`) for a list in a fixed order, and `ProductListing` (`app/components/`) only where the visitor filters and sorts, since it brings that toolbar.

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

## Money and other values

- Select `formatted` with every `amount` (`price { amount currencyCode formatted }`) and render it with `<Money>`: some markets require a dual-currency display that only the store's own formatting gives.
- `DateTime` values are UTC without a zone. Read them with `parseDateTime` and `formatDateTime`, not `new Date()`.

## Validation and limits

1. **The storefront MCP.** In a new session call `learn_cloudcart_storefront` first: it maps the whole API and names the operation for each step. Then check every new or changed document with `validate_graphql_codeblocks`. It also catches mistakes that pass schema validation and still fail, such as `amount` without `formatted`. Use `introspect_graphql_schema` to look up a type or field.
2. **`npm run codegen`** types every `#graphql` document against the schema shipped with Nitrogen (`@cloudcart/nitrogen/storefront.schema.graphql`), and fails on a field or argument the schema lacks.
3. **Limits.** The API refuses a query that is more than 10 levels deep or has a complexity over 1000. A page's queries stay within both.
