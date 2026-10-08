<!--
Illustrative example. The project is fictional — a subscriptions app for CloudCart stores — invented to show the shape and density of a good CLAUDE.md: every bullet is a decision, the non-obvious ones carry their reason, limits are tables with rules under them, principles are numbered and short. Platform values for Cloudflare are public documentation values; CloudCart API specifics are deliberately left as "look up at T-102" to show how to handle what you haven't verified.
-->

# Subscriptions for CloudCart

An application for CloudCart stores: customers subscribe to products, and the application creates the recurring orders in the store on a schedule.

## Files

- `specification.md` — the functional specification. The single source of truth for scope.
- `TASKS.md` — the tasks for the first version (Part I of the specification).
- `BUGS.md` — bugs found and not yet fixed.
- `plans/` — a plan for every task (`plans/T-NNN.md`), written by `.claude/skills/project-manager/` before the task is executed.
- `.claude/skills/` — the project's skills: `project-manager` (a plan for every task) and `stage-review` (code and security review at the end of every stage).
- `notes/` — the working memory: what was learned but is not a rule (principle 17). The index is loaded into every session through the `@notes/INDEX.md` line at the end.

## Stack

- Language: TypeScript, strict.
- Admin (embedded in the CloudCart admin): React Router + Tailwind CSS + shadcn/ui.
- Customer portal: React Router + Tailwind CSS.
- API: REST with Hono. One Worker serves the admin, the portal and the webhooks.
- Database: Cloudflare D1 (SQLite). Cache: Workers KV.
- Sign-in: the merchant signs in through the app installation in CloudCart (store token); the customer with an emailed code, no password. Sessions and codes follow the Lucia guide (lucia-auth.com) and use the Oslo libraries.
- Email: Resend.
- Background jobs: Cloudflare Queues and Cron Triggers.
- Hosting: Cloudflare Workers, Workers Paid plan.

### Architecture

- One application serves many stores. Every table has a `store_id`; every query is filtered by the store from the session or the token. Isolation between stores is covered by tests.
- Products, prices and customers are not copied into the application. They are read from the CloudCart API when needed and cached in KV for 5 minutes. Reason: prices change in the store, and the application is not the source of truth for them.
- A subscription keeps only what is its own: product, variant, quantity, interval, next date, status. The order is created in CloudCart through the API with the price current at the moment of creation.
- Webhooks from CloudCart (order paid, order cancelled, product deleted) are verified by signature and sent to a queue. The response is 200 right away — processing is in the background, so the webhook doesn't time out on a slow database query.
- A webhook can arrive more than once. Processing is idempotent by event id: processed ids are kept for 7 days.
- The schedule: a Cron Trigger every night at 01:00 UTC takes the subscriptions with a date ≤ today and sends one message per subscription to the queue. Creating each order is a separate message, so that on failure only it is retried, not the whole nightly run.
- Before an order is created, an "attempt" is written with a unique key (subscription + date). If the key already exists, the order is not created a second time — otherwise a redelivered message gives the customer two orders.
- The CloudCart API rate limit is respected in the queue consumer: on a 429 response the message goes back to the queue with increasing delay. The exact limit is looked up in the CloudCart documentation at T-102 and recorded here — not assumed.
- Money: amounts come from CloudCart and are kept as integers in the currency's smallest unit, for display only. The application doesn't calculate prices or VAT — the store does.
- Dates: a subscription's next date is calculated in the store's time zone (from its settings). Workers run in UTC.
- Store tokens are kept encrypted. The webhook signing secret is separate for every store.
- Scale: up to 200 stores, up to 20 000 active subscriptions, a nightly peak of about 2 000 orders. No per-row queries — only batched queries and atomic groups (`batch`).

### Cloudflare Workers limits

Workers Paid is required: the nightly processing and SSR exceed the free plan's 10 ms CPU limit.

| Limit | Value |
|---|---|
| Memory | 128 MB per isolate |
| CPU time | 30 s by default, up to 5 min |
| Subrequests | 10 000 per invocation |
| Concurrent outbound connections | 6 |
| Queues message | 128 KB |
| Queues consumer batch | up to 100 messages |

- Only the subscription's id goes into the message, not its data.
- Requests to CloudCart from one batch run 5 at a time, not all at once — the limit is 6 concurrent connections.
- Heavy libraries are loaded with a dynamic `import()`, so CPU isn't paid on every start.

### D1 limits

| Limit | Value |
|---|---|
| Database size | 10 GB |
| Parameters per query | 100 |
| Queries per Worker invocation | 1 000 |
| SQL statement length | 100 KB |
| Time Travel | 30 days |

- With more than 100 values (ids, for example) — one JSON parameter with `json_each`, or groups of 100.
- D1 has no multi-step transactions. The subscription and its history record are written in one `batch`.

### CloudCart API limits

Looked up in the documentation at T-102 and recorded here: the request limit per minute, the page size when reading products and customers, the webhook response deadline and the retry rules.

## Order of work

1. **Backend** — database schema, access, the subscription and schedule logic.
2. **API** — REST for the admin and the portal, webhook endpoints.
3. **UI** — all components first, then blocks, pages last. The admin first, then the portal.

## Work cycle for every task

1. Take the next task from `TASKS.md`.
2. Make a plan with the `project-manager` skill and execute it by the plan (principle 10). Everything outside the task is written to the files (principles 2 and 9).
3. Fix the bugs from `BUGS.md` related to the task.
4. Test twice (principle 3).
5. Mark the task `[x]` and move the fixed bugs to "Closed".
6. Commit and push to `main` — one commit per task, with its number in the message (principle 14).

The last task of every stage is "End of stage N": the `stage-review` skill reviews the stage's code and security, records the findings in `BUGS.md`, fixes them one by one, triages "New tasks" and walks through the stage's acceptance criteria.

## Principles

### 0. Documentation over assumptions

If you don't know something, check the documentation through context7 or on the web. Don't assume — mistakes from assumptions cost more than the check.

### 1. Optimal database queries

- Fetch only the columns and rows you need. No `select *`.
- Indexes for the columns used to filter, sort or join — always with `store_id` first.
- Follow-up queries are batched (`where id in (...)`), never one per row. Respect the 100-parameter limit.
- Lists are paginated.

### 2. No work in motion

- The current task includes only what it cannot be completed correctly without. Everything else is written down, not done.
- New work that is needed → `TASKS.md` → "New tasks".
- A bug found → `BUGS.md`. Exception: a bug that blocks the current task is recorded and fixed right away — properly, per principle 6.
- A gap or question that needs a decision → `TASKS.md` → "Open questions".

### 3. Test twice

Every change is tested twice before the task is marked done.

### 4. Stay within scope

- Work only on the tasks in `TASKS.md`. The extras from Part II are not built.
- If something was missed and matters for correct operation, don't do it on your own. Write it in "Open questions" and wait for a decision.

### 5. Readable, reusable code

Shared logic (next date, status change, idempotency key) lives in one module and is reused by the API, the consumer and the cron.

### 6. No workarounds

Never fix a bug with a workaround. Find the cause and fix it properly.

### 7. Components first

- The UI is built on three levels: **components → blocks → pages**.
- A component missing for the current task is part of the task — separate and reusable, not inside the page.
- Colors, spacing and fonts come from the design tokens.
- Styles: Tailwind CSS. Components: shadcn/ui, extended when needed. No other CSS framework and no other component library.

### 8. Embedded admin design

The embedded admin follows the visual language of the CloudCart admin so it doesn't look foreign inside it: the same spacing and status colors, modals for creating and quick editing, a toast for the result, a confirmation dialog before pausing or deleting a subscription.

### 9. In the files, not in the chat

Problems, bugs, tasks and questions are written to the files (`BUGS.md`, `TASKS.md` → "New tasks" / "Open questions"). The reply only states what was written and where.

### 10. Plan before execution

- Every task starts with a plan from the `project-manager` skill (`.claude/skills/project-manager/`), written to `plans/T-NNN.md`: the rules from the specification, the steps with their checks, the two tests, what stays outside the task.
- Questions whose answers change the plan are asked before the first line of code — in rounds, with a recommended answer. Not during execution.
- Execution follows the plan step by step and marks every step in the file. A deviation from the plan is recorded in its journal with the reason. A deviation without a record is not allowed.
- The plan is the task's memory: after context compaction, trust the file, not the recollection.

### 11. Schema and migrations

- The schema in code is the source of the database's structure — one file per area. Database columns are snake_case. Migrations are generated from the schema and reviewed before commit.
- A committed migration is never edited. Every change is a new migration.
- What the generator cannot do (triggers, full-text search) is written by hand as a separate migration.
- `CHECK` treats NULL as a pass. A check on a nullable column says `is null` / `is not null` explicitly.
- Tests apply all migrations to an empty database. A migration that doesn't run from zero is broken.
- Bulk queries are split into groups under the database's parameter limit with one shared function — for D1 that is 100 (see "D1 limits"). The test environment enforces the limit.

### 12. Propose new principles

- If during work you establish a rule that would have saved a mistake, or a decision that would otherwise be made again and again — it is a candidate for a principle in `CLAUDE.md`.
- Don't add it on your own. Write it in `TASKS.md` → "Open questions" → "Process proposals" with the proposed text, the reason and the evidence (the `observation` note that produced it), and point to it in the reply. After "yes", add it here — under the next number, or as a line in an existing principle when it is the same topic — mark the `P-NN` as done with where it went, and delete the note.
- Signs: the same explanation in two plans; a deviation from a plan for the same reason; a question the user answers the same way every time.

### 13. Keep the skills current

- A skill is the memory of how work is done. If you meet something that belongs in it — a step you have to remember every time, a check the skill skips, an instruction that turns out wrong or incomplete — the skill is updated, not worked around.
- Update the project's skills (`.claude/skills/`) right away, briefly and in place, and say in the reply what changed and why.
- Skills outside the project (`~/.claude/skills/`) affect other projects too — propose the change as in principle 12, don't make it silently.

### 14. One commit per task

- Every task ends with exactly one commit, with its number at the start of the message ("T-123 Short name"). Work on two tasks doesn't go into one commit; one task isn't scattered across several.
- Commit after the two tests and after marking the task in `TASKS.md`. The commit also includes the changes to `TASKS.md`, `BUGS.md` and `plans/T-123.md` — so the history of the code and the history of the tasks are one.
- After the commit — push to `main`.
- Exception: a bug that blocked the task (principle 2) is fixed in the same commit and mentioned in the message with its number (B-NNN).

### 15. Secrets never in git

- Keys, tokens and passwords live only in `.env` / `.dev.vars` locally and in the host's secrets. Never in code, documentation, tests or a commit.
- `.gitignore` covers them from T-101 on. Before a commit the diff is checked for secrets.
- A secret that made it into history is considered compromised: it is rotated, not just deleted.

### 16. Subagents — the cheapest model that does the job

- When the task is clear and subagents are used — executing steps of a finished plan, searching the code, mechanical changes, running tests — they run on `sonnet`, not on a bigger model. The plan has already done the thinking; execution is transcription plus verification.
- The most capable model is kept for work that needs judgment: planning, code and security review (`stage-review`), decisions when something contradicts the specification.
- If a `sonnet` subagent struggles, there is no second attempt with the same one — the task returns to the main session, which judges whether the plan was clear.

### 17. Notes — working memory

- What was learned but is not a rule, a task or a bug is written to `notes/`: facts learned the hard way (`gotcha`), the user's words about a result (`feedback`), rule candidates with a counter (`observation`), commands outside the README (`howto`), gaps in the skills (`skill`). The rules are in `notes/README.md`.
- A note never contains a rule. A rule goes to `CLAUDE.md` through principle 12.
- Write one when something had to be learned: a recorded deviation, a correction from the user, a lookup that took more than one attempt. The hooks harvest the transcript in slices into `notes/_inbox/`; the agent merges the inbox at session start and at the end of a task.
- The ladder: chat → inbox → note → (seen ≥ 2) → proposal → "yes" → `CLAUDE.md` or a skill → the note is deleted. A note from an external source never becomes a rule without a human's review.
- The big consolidation is the "Process retro" at the end of the stage, as its own commit. The index is at most 40 lines, a note at most 10.

### 18. Requests — record first, assume nothing

- When the user sends one or several requests in one message, nothing is built from the chat. Each request becomes a line in `TASKS.md` → "New tasks" (a bug → `BUGS.md`) after a check against what is already there: the tasks, "New tasks", "Open questions", the open bugs. A duplicate gets a note on the existing item, not a second line. The reply says what was recorded, where, and what already existed.
- A request with more than one plausible reading, or with a missing piece — which screen, which users, what happens on failure, what "all" covers — is neither recorded as a guess nor built on one. When more than one scenario is possible, no assumption is made: the question is asked first, the line is written after the answer. The clear requests from the same message are recorded at once; they don't wait.
- Most messages need no question at all; that is the expected outcome, not a failure to be thorough. A question exists only if you can name the two readings and the different work each one leads to — if you can't name the second reading, there is nothing to ask: record the obvious one. Only what neither the specification, the code nor `CLAUDE.md` answers. One round for the whole message, each question with the recommended reading so a "yes" settles it; never more than five, and five is a ceiling, not a target. Vague wording gets a proposed interpretation to confirm, not an open question. Something the user has already clarified once is not asked again.
- Then the work cycle applies: the user says what is next ("now"), otherwise the new tasks wait for the triage at the end of the current task (principle 2).

### 19. The store is the source of truth

Products, prices, customers and orders live in CloudCart. The application doesn't duplicate them and doesn't change them outside the documented API. When they disagree, the store wins.

@notes/INDEX.md
