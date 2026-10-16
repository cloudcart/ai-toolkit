# SEO

What every page of a Nitrogen storefront needs for search engines, and how the starter does it. The requirements are Google Search Central's: each rule names its page under `developers.google.com/search/docs/`.

The starter's helpers for a route's `meta` are in `app/lib/meta.ts`: `seoMeta`, `pageMeta`, `privateMeta`, `errorMeta`, `listingUrl`, `crumbsJsonLd`, `storeOrigin` and `storeName`. `breadcrumbJsonLd` is in `app/components/Breadcrumbs.tsx`; it calls Nitrogen's `generateBreadcrumbJsonLd`. The other `generate…JsonLd` helpers are Nitrogen's (`EXPORTS.md`).

## What the storefront already does: keep it

- **Server rendering.** Everything a search engine should read comes from the loader and is in the first HTML. Never load indexable content only in the browser, and never set `noindex` from client code: Google may not run the JavaScript (javascript/javascript-seo-basics).
- **Canonical URLs on the store's own domain.** `storeOrigin(matches)` gives the store's primary domain, whichever host served the page, so a preview host's pages point at the store.
- **Only the store's domain is indexed.** `server.ts` passes `storeDomain: env.PUBLIC_STORE_DOMAIN` to Nitrogen's `createRequestHandler`, which answers every other host (the platform's preview address) with `X-Robots-Tag: noindex`. Keep it. On such a host both apply: the page carries `noindex`, and its canonical still names the store's domain.
- **One address per page.** The platform's addresses (`app/lib/urls.ts`): `/product/{handle}`, `/category/{handle}`, `/page/{handle}`, … Never invent a new address for a page that has one. An address with a trailing slash answers with a 301 to the one without, as the platform's storefront does (Nitrogen's request handler).
- **One page per product.** A variant URL (`?Color=Red`) preselects the variant, and its canonical is the product's URL without options (structured-data/product-variants).
- **Real 404s.** A loader that finds nothing throws `new Response(null, {status: 404})`, and unknown addresses get a 404 from the catch-all route. `server.ts` passes every 404 through `storefrontRedirect`, which answers with the merchant's 301 redirect when there is one.
- **Crawlable pagination, uncrawlable filters.** `<Pagination>`'s links are real `<a href>` links. Filters and sorting change the page through forms and scripts, not links, so they create no endless crawlable URLs. The chosen filters' chips are links, each to the page with one filter fewer: a finite set, shown only on a filtered page, whose canonical is the listing's. Their URLs still exist (a filter form puts its choices in the query) and can be shared, which is why their canonical matters.
- **The sitemap is the platform's.** On the store's domain CloudCart serves `/sitemap.xml` itself, listing the platform's addresses. The storefront has no sitemap route, and never adds one.
- **`robots.txt`** (a route of the starter) disallows only the platform's checkout, and names the sitemap only on the store's domain. **`llms.txt`** answers with the merchant's text, or 404 when there is none.
- **`<html lang>`** is the store's language. Each store has one language, so there are no `hreflang` alternates.

## Every indexable page

- **A `meta` export built with `seoMeta(matches, {...})`**, the starter's wrapper of Nitrogen's `getSeoMeta` (`app/lib/meta.ts`) that adds the store's name as `og:site_name`: `title`, `description` and `url` (the canonical, `${storeOrigin(matches)}${path}`), plus `image` where the page has one. Open Graph and Twitter tags follow from them. A simple page uses `pageMeta(matches, {title, path, description, crumbs})`, and a paginated list adds `search` (`url.search`), so each page of it is its own canonical through `listingUrl`.
- **The merchant's SEO fields first, as they wrote them:** `seo.title || title`, and `seo.description` whole, as the platform keeps it; only the fallback, the page's own `description`, is cut to about 160 characters (`seo.description || description?.slice(0, 160)`) (product, collection, page, blog, article, vendor and tag all have `seo`; the home has `shop.homePageSeo`). A page without a merchant description gets one: a translated sentence that names the page and the store, from the `seo` texts in `app/locales/*.json` (`seo.collection`, `seo.product`, `seo.vendor`, `seo.blog`, …; add one for a new kind of page). Never leave it empty (appearance/snippet).
- **Titles as the platform's:** the merchant's SEO title as it is, with no store name added.
- **Exactly one `h1`,** and meaningful `alt` text on content images: the merchant's alt text, or the product's title for a product photo without one (`<MediaFile alt={title}>`; appearance/google-images). A decorative image, or a card's image whose title is in the same link, has `alt=""`.
- **The error case:** a route with its own error boundary starts `meta` with `if (error) return errorMeta(matches)`, so the error page keeps the root's title and `noindex`.

## Pages that must not be indexed

- **Private, form and utility pages** return `privateMeta(title)` from their own `meta`: account pages, sign-in and registration, the cart, search results, all products, comparison, GDPR and withdrawal forms (crawling-indexing/robots-meta-tag).
- **Each route sets it itself.** React Router shows the deepest route's `meta`, and a parent's is not merged: a child of a `noindex` layout returns `privateMeta` too.
- **Never also disallow a `noindex` page in `robots.txt`:** a crawler that may not fetch the page never reads its `noindex`.

## Listings: categories, collections, brands, tags, blogs

- **Each page of results is its own canonical:** `url: listingUrl(matches, path, location.search)` keeps the page parameters (`cursor`, `direction`). Never point every page at the first (specialty/ecommerce/pagination-and-incremental-page-loading).
- **Filtered and sorted views point at the listing:** `listingUrl` gives them the listing's first page. Google calls a canonical a weaker signal here than a `robots.txt` rule, which matters only when filter URLs are crawlable links; keep filters as forms and scripts, as the starter does (crawling-indexing/crawling-managing-faceted-navigation).
- **A description** from the listing's `seo` or its own description, else the translated sentence; its image for Open Graph.

## Structured data (JSON-LD)

Pass it to `seoMeta` as `jsonLd`, as one object or a list. Mark up only what the page shows: a rating that the page hides must not be in the markup (structured-data/sd-policies).

| Page | Markup | Helper |
|---|---|---|
| Home | `Organization`: name, url, `logo`, the store's contact (`Shop.contact`: e-mail, phone, address, company, VAT number) | `generateOrganizationJsonLd({...shop, logo, contact}, url)` |
| Product | `Product` with `offers`, and `BreadcrumbList` | `generateProductJsonLd`, `breadcrumbJsonLd` |
| Category, selection | `CollectionPage` and `BreadcrumbList` | `generateCollectionJsonLd`, `breadcrumbJsonLd` |
| Article | `Article` with `author` (`authorV2`), `datePublished`, `dateModified` (`updatedAt`), and `BreadcrumbList` | `generateArticleJsonLd`, `crumbsJsonLd` |
| Any other page with a breadcrumb trail | `BreadcrumbList`, from the same crumbs the page shows | `crumbsJsonLd(matches, crumbs, path)` |

**The product** (structured-data/product-snippet, …/merchant-listing): `generateProductJsonLd` writes the name, every picture, the offer (price, currency, availability: `InStock`, `BackOrder` for a variant bought while out of stock, `OutOfStock`), `priceValidUntil` from `discount.endsAt`, the brand (`vendor`), the variant's `sku`, a `gtin` when the barcode has 8 to 14 digits, and `aggregateRating`. It gives no offer for a product sold on request (`statusType: REQUEST`) or without a price. Pass it the product the page loads with:

- `images`: the product's photographs (`media` of type `IMAGE`, their `previewImage`);
- `statusType`: the selected variant's;
- `reviewSummary`: only when the page shows the rating (`showsRating`), else `null`.

Deferred data (the reviews list, say) is not available to `meta`. Mark up only what the loader awaited.

## Before you call a page done

- [ ] Title, description, canonical on the store's domain, image: in the HTML the server sends.
- [ ] `privateMeta` on a private or form page, set by that route.
- [ ] A listing's second page keeps its own canonical; a filtered view's points at the listing.
- [ ] Its JSON-LD from the table above, with every field the page shows.
- [ ] One `h1`, and alt text on content images.
- [ ] A missing record answers 404.
- [ ] If you can, run the page's URL through Google's Rich Results Test (search.google.com/test/rich-results) and report the result; if you cannot, say the markup was not tested.
