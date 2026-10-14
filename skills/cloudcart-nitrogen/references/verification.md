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

## GraphiQL

`/graphiql` explores the API with the schema shipped with Nitrogen, against the store in `.env`, and can run a query as the signed-in buyer. Use it to try a query before you put it in a loader, and open a profiled call in it to see its answer.

## The project's checks

```sh
npm run check
```

It runs codegen, typecheck, lint (design tokens, translations, ESLint, Prettier) and build, and the tests once `npm test` is part of it (`references/building-block.md`). In a project created from the starter, the pre-commit hook runs the same, and refuses a commit whose generated types (`storefrontapi.generated.d.ts`) changed but were not staged. All must pass. Fix a failure where it starts, and never silence a rule to get past it.

## Speed: Lighthouse on a phone

The target is a Lighthouse performance score of at least 90 with its default mobile profile, for the home, a category and a product page. Measure what ships, not the dev server:

- **A deployed storefront:** deploy a preview (`cloudcart nitrogen deploy --preview`) and run its pages through PageSpeed Insights (pagespeed.web.dev), which runs Lighthouse's mobile profile.
- **Locally:** Lighthouse in Chrome's DevTools, or `npx lighthouse <url> --only-categories=performance`, against the production build.

Run each page three times and take the median: one run varies by several points. Report the score with its metrics (FCP, LCP, TBT, CLS) and what holds it back: the largest-contentful-paint element and the opportunities Lighthouse lists. A score under 90 is reported to the user with that cause.

## The review of the whole site

Before you call the change done, go through `references/quality.md`: speed, caching, queries, security, SEO, consent and analytics, accessibility, translations, the states between success and failure, and design.

## Reporting

Tell the user:

- what changed, and which pages it touches;
- each page's calls before and after, on the first and the second load;
- the checks you ran and their result;
- what you did not check, and why: a check in a real browser, a phone, a store with other data.
