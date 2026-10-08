# Technical decisions (Step 4) → CLAUDE.md

Addressed to the developer, after the interview. Most inputs already exist in the specification — scale, integrations, notifications, files, flows. This step translates them into decisions; it asks only what the spec cannot answer. Keep the same rhythm: say what you derived, ask three or four questions with defaults, write.

## 1. Project shape and stack

The stack is a Level 1 question of the interview (F3 and F4): the project's shape fixes most of it, so it is proposed there as one coherent set with the user's standards as the recommendation, every deviation named with its reason and every paid service with its price class. Here, after the interview, it is only confirmed against what the specification turned out to need — a new integration, a scale that changed, a background job nobody expected.

| Project shape | Coherent default set |
|---|---|
| CloudCart app (embedded admin + customer portal / storefront widget) | Cloudflare Workers (Paid) · TypeScript strict · Hono or GraphQL Yoga API · D1 + KV · React Router + Tailwind (+ shadcn/ui for the admin) · Queues + Cron Triggers · Resend for email · store token encrypted at rest · webhook signatures verified |
| Medusa store (v2) | Node 20+ · Postgres · Redis (event bus, workflow engine, cache) · custom modules, workflows, subscribers, scheduled jobs · Admin UI extensions (widgets, UI routes) · Next.js storefront starter · container platform or VPS |
| Standalone web app with admin | Cloudflare Workers or a container platform · TypeScript strict · React Router + Tailwind + shadcn/ui · GraphQL when several frontends share one backend, otherwise REST · platform DB and object storage · platform queues or cron |

Per concern:

| Concern | Default to propose | Notes |
|---|---|---|
| Hosting and plan | Cloudflare Workers Paid for Workers projects | Free tiers have CPU and time limits that break SSR and background jobs — write the required plan into CLAUDE.md with the reason |
| Language and tooling | TypeScript strict, linter, formatter, Vitest, CI on every push (lint, typecheck, tests), pre-commit hook running the same, `.gitignore` covering secrets | All of it is T-101 — the rules are enforced by tooling |
| Frontend | React Router. **Styling is Tailwind CSS and components are shadcn/ui — a rule, not a default.** Whenever the project has a UI, no other CSS framework or component kit is used; write it into `## Stack` and principle 7 | On Workers SPA mode isn't supported — SSR. One app or several (admin + customer-facing) follows from the spec's screens. shadcn/ui setup is part of T-101 |
| API | GraphQL (Yoga) with several frontends; otherwise REST (Hono) or framework routes | How frontends reach the API: service bindings on Workers, HTTP elsewhere |
| Database and query layer | From the hosting. The query layer (Drizzle / Kysely / MikroORM in Medusa) is chosen *after* checking the docs — a task, not a decision | |
| Login | Platform-provided when embedded (CloudCart install token, Medusa Auth module); otherwise passwordless email code + optional TOTP for staff, following the Lucia guide with Oslo | Session lifetimes come from the spec |
| Files and images | Platform object storage behind an own domain; resize once at upload into a fixed set of sizes, WebP | Resize-on-display bills per transformation every month |
| Email | Resend / Postmark or the platform's service | Sending domain verified; new accounts have low daily limits |
| Background jobs | Platform queues + cron for everything the spec marks as long-running or scheduled | |

Skip when manifests in the folder already fix a choice — confirm instead.

Writes: `## Stack`.

## 2. Architecture

Derive from the spec, confirm with the developer:

| Decision | Default | Source in the spec |
|---|---|---|
| Services and how they talk | One Worker, or several with service bindings when admin and customer apps have different scaling or security needs | Screens, roles |
| Who touches the database | Only the API layer | — |
| Tenant isolation | Tenant id on every table, every query filtered from the session or token, isolation tests | Block 2 and 3 answers on multi-tenancy |
| Source of truth | The platform owns its records; the project stores only its own fields and reads the rest through the API with a short cache | Block 3, 6 |
| Atomicity | Parent + children in one batch; a DB constraint guarantees invariants where the DB has no multi-step transactions | Flows that must succeed or fail together |
| Idempotency | Webhooks and queue messages are at-least-once; consumers are idempotent by event id or a unique attempt key | Block 6 failure answers |
| Background work | Everything long-running or scheduled goes to queues; the message carries an id, not the data; one import at a time | Block 6, 9 |
| External rate limits | Respect 429 with backoff inside the consumer; limit concurrency to the runtime's connection cap | Block 6 |
| Money | Integers in the smallest unit; precision and rounding as the spec says; never floats | Block 5 |
| Dates | Business dates in the users' or store's zone; servers in UTC | Block 5 |
| Secrets | Tokens and webhook secrets encrypted at rest, per tenant | Block 6 |
| Scale numbers | Copy them in — they justify the batching rules | Block 3, 9 |

Every non-obvious decision carries its reason in the same bullet.

Writes: `### Architecture`.

## 3. Platform limits to research

Look them up in context7 or the official docs, never from memory. One table per component that constrains the design, each followed by the rules it implies.

- **Runtime**: memory, CPU time per request, request body size, subrequests, concurrent outbound connections, cron limits.
- **Database**: size, parameters per query, SQL length, queries per invocation, row/blob size, transaction model, point-in-time recovery window.
- **Queues**: message size, batch size, retries, consumer duration.
- **Storage / KV**: object size, value size, consistency.
- **Email**: daily limits, domain verification.
- **External APIs**: requests per minute, page sizes, webhook timeout and retry policy — if not verifiable now, write "verified in T-102 and recorded here" rather than a guess.

Writes: `### <component> limits` (one per component).

## 4. Work process

Present as one package and ask what to change. These rules bind every future session, so the developer must own them.

**Order of work** — backend → API → UI; inside UI components → blocks → pages. Why: a UI built on a finished API isn't rebuilt when the API changes; components built first are reused instead of duplicated inside pages. Alternative when the user prefers it: vertical slices per stage (each stage gets backend + API + UI before the next) — then TASKS.md phases are stages, and ids encode the stage.

**Work cycle for every task**

1. Take the next task from `TASKS.md`.
2. Make the plan with the project's `project-manager` skill and execute it by the plan (principle 10). Everything outside it goes into the files, not into the code.
3. Fix the bugs in `BUGS.md` related to the task.
4. Test twice.
5. Mark `[x]`; move fixed bugs to "Closed".
6. Commit and push — one commit per task, its number first in the message (principle 14).

**Principles** — the default set; drop what doesn't apply, add domain ones:

0. **Documentation over assumptions** — check the docs (context7, web) instead of guessing; a wrong assumption costs more than the lookup.
1. **Optimal database queries** — only needed columns and rows, indexes on filtered/sorted/joined columns (tenant id first), batched follow-ups instead of N+1, independent queries sent together, pagination. *Only with a database.*
2. **No work in motion** — new work → `TASKS.md` "New tasks"; a bug → `BUGS.md`; a decision needed → "Open questions". Exception: a bug blocking the current task is recorded and fixed now, properly.
3. **Test twice** before marking a task done.
4. **Stay within scope** — no Part II features; something missing but important → open question, wait.
5. **Readable, reusable code** — shared logic (dates, status transitions, idempotency keys, formatting) lives in one place.
6. **No workarounds** — find the cause.
7. **Components first** — three UI levels; a missing component is part of the task and built reusable; design tokens, no hardcoded values; Tailwind CSS for styling and shadcn/ui for components, nothing else. *Only with a UI.*
8. **Admin design** — the reference product from Block 8; minimalism, colour-coded statuses and dangerous actions, modals for create and quick edit, toasts, confirmation before destructive actions. *Only with an admin UI.*
9. **In the files, not in the chat** — problems, bugs, tasks, questions go to the files; the reply says what was written and where.
10. **Plan before execution** — every task starts with a plan written by the project's `project-manager` skill into `plans/T-NNN.md` (spec rules, steps with checks, the two tests, what stays out); questions that change the plan are asked before the first line of code, in rounds with a recommended answer; execution follows the plan step by step, ticks each step in the file, and records every deviation with its reason. The plan is the task's memory across context compaction. *Always.*
11. **Schema and migrations** — the schema in code is the source of the database structure, one file per area, snake_case columns; migrations are generated from it and reviewed before commit; a committed migration is never edited — every change is a new one; what the generator can't express (triggers, full-text search) is a hand-written migration; `CHECK` passes NULL, so nullable columns get explicit `is null` / `is not null`; tests apply all migrations on an empty database; mass queries are chunked under the database's parameter limit by one shared helper (the number lives in the limits section, not in the principle) and the test environment enforces the limit. General for every database — only the limit value is per engine. *Only with a database.*
12. **Propose new principles** — a rule discovered during work that would save a mistake or a repeated decision is a candidate for CLAUDE.md; it is proposed (text + reason) in TASKS.md "Open questions" and in the reply, never added silently; added under the next number after a yes. *Always.*
13. **Keep the skills current** — when work reveals a step, check or correction that belongs in a skill, the skill is updated rather than worked around: project skills (`.claude/skills/`) immediately, with a line in the reply saying what changed; skills outside the project (`~/.claude/skills/`) by proposal, as in 12, because they affect other projects. *Always.*
14. **One commit per task** — exactly one commit per task, the task number first in the message; made after the two tests and the `[x]`, including the changes to TASKS.md, BUGS.md and the plan file, then pushed to the project's main branch; a bug that blocked the task rides in the same commit and is named. *Always with git.*
15. **Secrets never in git** — keys, tokens and passwords live only in `.env`/`.dev.vars` locally and in the host's secrets; never in code, docs, tests or a commit; `.gitignore` covers them from T-101; the diff is checked before each commit; a leaked secret is rotated, not just deleted. *Always.*
16. **Subagents — the cheapest model that does the job** — subagents for clear, well-specified work (executing plan steps, code search, mechanical changes, running tests) run on `sonnet`; the most capable model is kept for judgment: planning, code and security review, spec conflicts; a struggling `sonnet` subagent is not retried on the same model — the work comes back to the main session and the plan's clarity is questioned. *Always.*
17. **Notes — working memory** — what was learned but is not a rule lives in `notes/` (gotcha, feedback, observation with a counter, howto, skill); a note never contains a rule; hooks harvest the transcript in slices into `notes/_inbox/`, the agent merges at session start and task end; the ladder is chat → inbox → note → (seen ≥ 2) → proposal → yes → CLAUDE.md or skill → note deleted; big consolidation at stage end as its own commit; index ≤ 40 lines. *Always.*
18. **Requests — record first, assume nothing** — one or several requests in one message are recorded in TASKS.md (or BUGS.md) after a duplicate check against tasks, New tasks, Open questions and open bugs; a request with more than one plausible reading or a missing piece is asked about first and recorded after the answer, never guessed; the clear ones are recorded at once; most messages need no question — a question exists only if both readings and the different work they lead to can be named, otherwise the obvious reading is recorded; one round per message, each with a recommended reading, never more than five (a ceiling, not a target); vague wording gets an interpretation to confirm. *Always.*
19+. **Domain principles** from the spec: "the platform is the source of truth", "an order is never created without a recorded attempt".

Writes: `## Order of work`, `## Work cycle for every task`, `## Principles`.

Environments (dev / staging / production) and deployment are the user's decision. Don't define them; record in CLAUDE.md what the user decided, or one line saying it is still theirs to decide.

## 5. Tools and skills for the stack — search, propose, install after a yes

This skill doesn't list tools or skills, because the lists go stale and every project is different. It gives the rule and the places to look. The agent searches, proposes a short list with one reason each, and installs only after the user's explicit yes — never silently.

**For every external service the project depends on** (hosting, database, storage, email, the platform's API, the repository, DNS), the order is fixed: **CLI or MCP → API → the user.** If a CLI or an MCP server exists, propose it and do the work yourself once installed. If none exists but the service has an API, use it with a key the user creates. Only when neither exists, give the user exact steps and what to paste back. Genuinely human-only work — a paid account, buying a domain, approving an OAuth login, accepting terms — is listed plainly, with the steps.

**For every major component of the stack** (framework, UI kit, database, hosting platform, integrated platform) and for the project's domain (a storefront, an admin panel, an import pipeline), look for skills that would make the work better than documentation alone. Propose the ones worth installing, in the user's words: "For React Router there is a skill with X installs from Y; I propose we add it." Prefer the user's own skills over public ones when they overlap — a storefront skill the user has already written knows their conventions.

Where to look, in this order:

1. **The user's own skills** — `~/.claude/skills/`, and `.claude/skills/` inside the user's other projects. These encode their conventions and win over anything public.
2. **Installed plugins and their marketplaces** — `enabledPlugins` and `extraKnownMarketplaces` in `~/.claude/settings.json`; a plugin may already be installed but disabled.
3. **The public registry** — skills.sh, searched with `npx skills find <term>` (run it plain — macOS has no `timeout`, so a wrapped call fails with „command not found“ and looks like an empty registry). Judge before proposing: official or well-known source, install count in the thousands or more, a repository with real stars. The `find-skills` skill, when available, carries this procedure.
4. **Official documentation through context7** for anything without a skill — principle 0 covers the rest.

Record what was installed in `CLAUDE.md` → `## Files` (project skills) or in the hand-over (user-level tools), so a future session knows what it has.
