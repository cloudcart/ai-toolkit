<!--
Illustrative example — the TASKS.md matching example-claude-md.md (fictional subscriptions app for CloudCart). Trimmed: a few representative tasks per subsection, "…" marks omitted ones. Note: ids encode the phase; every task ends with its spec reference; rules with numbers live inside the task text; tasks that trigger others name them (T-134); open questions carry a proposal.
-->

# Tasks — first version

Source: `specification.md`, **Part I**. References `§X` point to sections of the specification.

Only the features of the first version go here. The extras from Part II (§10–13) are not added.

Tasks follow the order of work from `CLAUDE.md`: **backend → API → UI → acceptance**. Within the UI the order is **components → blocks → pages**.

The order of tasks is also the priority: dependencies first, then features of an earlier stage (Part III), then core processes before supporting ones. The next task is the first unchecked one.

**Rules**

- Every task starts with a plan in `plans/T-NNN.md` from the `project-manager` skill and is executed by it (principle 10).
- Mark a task `[x]` only after it has been tested twice.
- Work found necessary during another task is written down in "New tasks", not done in motion.
- Bugs are recorded in `BUGS.md`.
- Gaps and questions that need a decision are recorded in "Open questions". Once decided, the answer is reflected in the specification and the question is marked `[x]`.
- "New tasks" are triaged at the end of every task: each gets a number in its phase and a place by priority, or goes to Part II of the specification. The list below is a waiting room, not a queue.
- A request from the client in the chat is a new task. The client decides when: "now" means next task, otherwise it waits for the triage.
- The last task of every stage is "End of stage N": the `stage-review` skill reviews the code and the security, records the findings in `BUGS.md`, fixes them one by one and walks through the stage's acceptance criteria.

## Before start

Things outside the repository that the first tasks depend on. Each one says who does it.

- [ ] Cloudflare account with Workers Paid — only you: paid account.
- [ ] GitHub repository and CI — me, through the CLI, after your "yes" to installing it.
- [ ] Email sending domain in Resend — me through the API; you confirm the DNS records.
- [ ] Keys of the CloudCart development store — only you: a test store; I put them in secrets.
- [ ] Skills for the stack that I propose to add — after your "yes".

---

## Phase 1 — Backend

### 1.1. Foundation

- [ ] **T-101** Repository structure: one Cloudflare Worker (Hono) with two React Router frontends — admin and portal — and a shared package for the domain logic. TypeScript in strict mode, linter, formatting, Vitest. CI on every push (lint, typecheck, tests) and a pre-commit hook with the same. `.gitignore` for the secrets. — _§9_
- [ ] **T-102** D1 database, migrations, KV namespace, local environment with `wrangler dev`. Choice of query layer (Drizzle or Kysely) after checking the documentation. Check and record in `CLAUDE.md` the CloudCart API limits: requests per minute, page size, webhook response deadline, retries. — _§9_
- [ ] **T-103** Technical records for diagnostics: errors from the API, from the consumer and from the cron, with `store_id` and the subscription id. — _§9_

### 1.2. Database schema

Every table has a `store_id` and is created with the constraints and indexes its queries need.

- [ ] **T-104** Stores: CloudCart id, domain, encrypted token, webhook secret, time zone, installation status. — _§3_
- [ ] **T-105** Subscriptions: customer (CloudCart id), product and variant (CloudCart ids), quantity, interval (week, 2 weeks, month), next date, status. Index on `store_id, status, next_date`. — _§4.1, 4.2_
- [ ] **T-106** Subscription history: status changes and order attempts with a unique key `subscription_id + date`. — _§4.3, 5_
- [ ] **T-107** Processed webhook events: event id, store, received at. Records are deleted after 7 days. — _§5.3_
- …

### 1.3. Security and access

- [ ] **T-110** Installing the app in a store: receiving and storing the token encrypted, creating a webhook secret, registering the webhooks through the API. Uninstalling: stops the subscriptions and deletes the token. — _§3_
- [ ] **T-111** Merchant sign-in from the CloudCart admin: request signature check, 7-day session. Customer sign-in with an email code: 6 digits, 10 minutes, up to 5 attempts, the same response whether or not the email is a customer of the store. 30-day session. — _§2.3_
- [ ] **T-112** Isolation between stores: every query is filtered by the `store_id` from the session or the token. A customer sees only their own subscriptions. Isolation tests. — _§2, 9_
- [ ] **T-113** Webhook signature check with the store's secret; requests without a valid signature are rejected with 401 and logged. — _§5.3_

### 1.4. Business logic

Every piece of logic is one reusable module covered by tests.

- [ ] **T-120** Next date: from the start date and the interval, in the store's time zone; on the 29th–31st with a monthly interval — the last day of the month. — _§4.2_
- [ ] **T-121** Statuses: active → paused → active; active or paused → stopped (final). The customer can pause and stop; the merchant — everything. Every change is written to the history. — _§4.3_
- [ ] **T-122** Order creation: record the attempt with the unique key, read the current price from CloudCart, create the order through the API, move the next date. If the key already exists — nothing is done. On 429 — retry with increasing delay; after 5 failed attempts the subscription is paused and an email is sent (T-125). — _§5.1, 5.2_
- [ ] **T-123** Nightly selection: subscriptions with next date ≤ today in the store's time zone, active, with an installed store — one message per subscription in the queue, in groups of 100. — _§5.1_
- [ ] **T-124** Webhook processing: cancelled order → marks the attempt as cancelled; deleted product → pauses its subscriptions and sends an email (T-125). Idempotent by event id. — _§5.3_
- [ ] **T-125** Email notifications through Resend as a background job: upcoming order (3 days before the date), order created, subscription paused with a reason. Texts are in the store's language. — _§6_
- …

---

## Phase 2 — API

- [ ] **T-201** REST foundation with Hono: context with store and session, a single error format, input validation with a schema. — _§9_
- [ ] **T-202** Admin: subscription list and detail with filters by status and customer, pause, resume, stop, change of interval and quantity. Pagination. — _§8_
- [ ] **T-203** Portal: the customer's subscriptions, pause, resume, stop, moving the next date forward. — _§7_
- [ ] **T-204** Storefront endpoint for subscribing from a product page: variant, quantity, interval; the customer is recognized by the store session or creates a subscription after signing in with a code. — _§4.1, 7_
- [ ] **T-205** Webhook endpoints: receive, check the signature (T-113), write to the queue, respond 200 immediately. — _§5.3_
- …

---

## Phase 3 — UI

The order is components → blocks → pages. Components shared by the admin and the portal are in "Foundation".

### 3.1. Foundation

- [ ] **T-301** Design tokens aligned with the CloudCart admin: status colors (active, paused, stopped), spacing, fonts. — _§8_
- [ ] **T-302** Shared components: status badge, amount and date format by the store's settings, button with confirmation. — _§7, 8_

### 3.2. Components — admin

- [ ] **T-310** Table with pagination and filters.
- [ ] **T-311** Edit modal with a form and validation.
- …

### 3.3. Blocks — admin

- [ ] **T-320** Subscription list with filters by status and search by customer. — _§8_
- [ ] **T-321** Subscription card: customer, product, interval, next date, actions pause / resume / stop with confirmation. — _§8_
- …

### 3.4. Pages — admin

- [ ] **T-330** Subscriptions — list. — _§8_
- [ ] **T-331** Subscription — detail with history. — _§8_
- …
- [ ] **T-339** End of stage 1 — `stage-review`: code and security review of the stage, findings in `BUGS.md`, fixes one by one, triage of "New tasks", acceptance criteria of stage 1. — _Part III, Stage 1_

### 3.5. Components, blocks and pages — portal

- …

---

## Phase 4 — Checks and acceptance

- [ ] **T-401** End of the last stage — `stage-review` over the whole first version and a check of all acceptance criteria from §15.
- [ ] **T-402** Set up and verify backup and restore of D1 (Time Travel, 30 days) and of the KV data that Time Travel does not cover. — _§9_
- [ ] **T-403** Check the portal on a phone. — _§9_
- [ ] **T-404** Fix the discrepancies found. — _§14_
- [ ] **T-405** Check under load: nightly processing with 2,000 subscriptions on one date; the same message delivered twice — one order; a webhook delivered twice — one processing; a 429 from CloudCart in the middle of a batch — the rest are not lost. — _§9, 15_

---

## Open questions

Questions that need a decision. The current behavior in the specification is stated as the proposal.

- [x] **Q-01** What happens to a subscription when the product is deleted in the store? — **It is paused** with a reason and the customer receives an email. — _§4.3, 5.3_
- [x] **Q-02** Can the customer move the next date backward? — **No.** Only forward, up to 90 days. — _§7_
- [ ] **Q-03** If the product's price changed between subscribing and the order, should the customer be notified before the order? Proposal: the "upcoming order" email shows the current price; the order is created without extra confirmation. — _§5.2, 6_
- [ ] **Q-04** Does the subscription continue after a failed payment of the previous order? Proposal: yes, the store manages payments; the app does not track payment status in the first version. — _§5_

### Process proposals

_None._

---

## New tasks

A waiting room, not a queue. Tasks found during work are added here with a reference to the task they were found in. At the triage at the end of the current task each one gets a number in its phase and a place by priority, or goes to Part II of the specification — and is removed from here.

_None._
