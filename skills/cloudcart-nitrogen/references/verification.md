# Verifying a change

Stage 5 of the skill, the review. A change is done when it is measured and checked, not when it compiles.

## The profiler: the page's calls before and after

The dev server (`npm run dev`) prints two development addresses beside the app's: `/graphiql` and `/__nitrogen/subrequests`, the subrequest profiler. The profiler groups the calls to the Storefront API by the page request that made them. For each call it shows the operation, its variables, the response size, the cache status, the strategy and the duration, and links to the line that made the call and to the query in GraphiQL.

Measure every page you change, before you change it and after:

1. Open the profiler in one tab and the page in another.
2. Load the page, then load it again right away. The first load fills the cache, and the second shows what a returning visitor costs.
3. For each load, count the calls that reach the API: cache status `MISS`, `STALE` (served from the cache, then refreshed from the API) and `NONE` (not cached). A `HIT` does not count, and neither does a call marked `—`, which an identical call already in flight answered: neither reaches the API. A `PUT` is the cache being written, and is hidden by default. The heading's "N calls" counts the hits too, so subtract them.
4. Compare the counts with the page's budget (`references/graphql.md`) and with your "before". Report both numbers.

Look for:

- **N+1:** the same operation repeated once per item (a product query for each card, say). Select the data in the list's own query instead: through a fragment on its `nodes`.
- **A call that waits for no reason:** on the timeline, a bar that starts only after another ends although it needs nothing from it. Start both together.
- **A call that is never cached:** `NONE` on data that is the same for every visitor. Give it a strategy.
- **Errors:** a call with GraphQL errors is listed with them. A deferred call that fails renders its fallback, so the page can look fine while the section is gone.

The profiler's data is also at `/__nitrogen/subrequests.json`, for a script.

The calls are half of it: the times a visitor waits — a page's data on a click, cached and not, and the time to the waiting view and to the content — are measured as `references/speed.md` says.

## GraphiQL

`/graphiql` explores the API with the schema shipped with Nitrogen, against the store in `.env`, and can run a query as the signed-in buyer. Use it to try a query before you put it in a loader, and open a profiled call in it to see its answer.

## The project's checks

```sh
npm run check
```

It runs codegen, typecheck, lint (design tokens, translations, ESLint, Prettier; `npm run format` fixes the formatting) and build, and the tests once `npm test` is part of it (`references/building-block.md`). In a project created from the starter, the pre-commit hook first refuses a commit while other files are changed or untracked (`scripts/require-committed-tree.mjs`: what is checked is what is committed), then runs the same, and refuses a commit whose generated types (`storefrontapi.generated.d.ts`) changed but were not staged. All must pass. Fix a failure where it starts, and never silence a rule to get past it.

## Speed: Lighthouse on a phone

The target is a Lighthouse performance score of at least 90 with its default mobile profile, for the home, a category and a product page. Measure what ships, not the dev server:

- **Locally:** Lighthouse in Chrome's DevTools, or `npx lighthouse <url> --only-categories=performance`, against the production build (`npm run build`, then `npm run preview` or `cloudcart nitrogen preview`). Both serve it with `vite preview`, over HTTP/1.1, where Lighthouse simulates six connections to the host, so a build's many small files cost round trips that Cloudflare's HTTP/2 does not: with Lighthouse 12.6.0 the starter's pages measured 88–91 over HTTP/1.1 and 96–97 over HTTP/2, the same build, while Lighthouse 13.4.1 in DevTools scored the home 100 over HTTP/1.1. Compare runs of one version, served one way: a local run tells you what a change does, and the live site gives the score.
- **The live storefront:** PageSpeed Insights (pagespeed.web.dev) runs Lighthouse's mobile profile on its pages, from Google's machines, with nothing blocked. Run it only with the user's word (below).
- **A test visit can reach the merchant's ad accounts.** Every page reports its views to the store's `/api/sf`, and where the merchant turned on server-side reporting (`analyticsSettings { pixels { provider serverSide } }`), the API forwards them to Meta, TikTok and Google Analytics. A new browser profile counts the advertising groups as accepted when the merchant made them so by default. Blocking the vendors' hosts (`--blocked-url-patterns='*facebook.com*'`, quoted for the shell, and the same for `facebook.net`, `tiktok.com`, `googletagmanager.com`, `google-analytics.com`, `doubleclick.net`) stops only the browser's pixels. So before a test visit to a store with server-side reporting — a Lighthouse run, PageSpeed Insights, the tracking check — tell the user that it adds test events to their ad accounts, and ask. Locally, block the vendors' hosts too, and say that the score leaves the pixels out; Nitrogen adds their scripts only once the page has loaded and is idle.

Run each page three times and take the median: one run varies by several points. Run Lighthouse in a browser profile without extensions (a DevTools run in a guest or incognito window, or the CLI): an extension that blocks the merchant's pixels logs errors that fail Best practices' `errors-in-console`. Report the score with its metrics (FCP, LCP, TBT, CLS) and what holds it back: the largest-contentful-paint element and the opportunities Lighthouse lists. A score under 90 is reported to the user with that cause.

## The review of the whole site

Before you call the change done, go through `references/quality.md`: speed, caching, queries, security, SEO, consent and analytics, accessibility, translations, the states between success and failure, and design.

## Reporting

Tell the user:

- what changed, and which pages it touches;
- each page's calls before and after, on the first and the second load;
- each page's times before and after: its data on a click, cached and not, and the time to the waiting view and to the content;
- the reuse map (what was used as it is, what was extended, what was built) and the page's elements checked in each state;
- the checks you ran and their result;
- what you did not check, and why: a check in a real browser, a phone, a store with other data.
