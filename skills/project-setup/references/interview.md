# Discovery interview — two levels, forks only

Read this before the first question. The interview has two levels: **Foundation** — the root decisions everything else hangs on, one or two rounds — and **Clarifications** — nine blocks, each *written first and asked second*. At both levels only **forks** reach the user; everything else is decided by standard and written into the specification as a rule. The round mechanics are mattpocock/skills' *grilling*: numbered questions, each with a recommended answer worded so "yes" accepts it, rounds until nothing askable remains.

## The fork test — what gets asked

A question reaches the user only if it passes one of these two:

1. **Only the user knows.** Competent people would answer differently depending on things only the user knows: budget, market, business model, the client, the timeline, taste in a product they will live with.
2. **Expensive to change.** The answer changes the data model, the flow of money, the roles, or the scope of the first version.

Everything else is decided and written as a rule, without a question: an industry standard, a security practice, a platform constraint, a consequence of something already decided, anything cheaply reversible later. "The old short URL redirects forever", "a category with services is not deleted", "money is integers", "name and phone are required" are decisions. "Does the customer have an account, or is it like Calendly", "does the platform take a commission", "D1 or Postgres", "prices per location or shared" are forks.

When in doubt: would the user be annoyed to be *asked* this, or annoyed to find it *decided*? The first means decide; the second means ask.

## Rounds

- **Unique numbers for the whole interview.** #1, #2 … #40 — never restarting per round, never "#1b". A question asked again keeps its number and is repeated in short form, never referenced by number alone.
- **Cap of seven per round**, the most expensive-to-get-wrong first. A frontier larger than seven is worked over several rounds; a smaller one is never padded.
- **Format:**

  ```
  ❓ **#7 — <title>**: <the question; the options when there are more than two>

  ➡️ <recommendation and why>

  ---
  ```

- **Facts are yours, decisions are the user's.** Anything the folder, the code, the docs or context7 can answer is looked up, never asked. A lookup in progress blocks only the questions downstream of it.
- `AskUserQuestion`, when available, may carry a round of up to four pure-choice forks with the recommended option first and "(Recommended)"; otherwise use the text format.
- Business language at both levels. "Who may cancel, and until when?", not "state transitions".
- The user's language throughout. The format, the digest header and every quoted phrase in this file are English examples; say them in the language the user writes in.

## Business questions

A business question is asked only when it is a **product fork with software consequences**, and it is phrased as one: not "how does the customer find the salon?", but "a page per salon, or one shared catalogue — two different systems". Pure business questions — success metrics, price levels, marketing — are not asked: prices are settings, metrics are not software.

When the user is a developer building for a client (Foundation, F1), business forks are not asked to the developer. They go to the spec's "Remaining clarifications" under a sub-heading "Questions for the business", each with the recommended default, so the software has a defined behaviour until the business decides.

## The digest — how decisions made without a question stay visible

With every block's round, give a digest: "**Decided by standard:**" followed by five to ten one-line decisions, each with its spec section. The user vetoes a line by its number ("not 3"). The same lines are appended to the spec's Part III section "Decisions by standard", one per line with the section reference and a status (`reviewed` after a digest the user saw; `unreviewed` when written without one, see the end of this file), so the whole set can be reviewed later without re-reading the document. The spec sections themselves stay clean rules — no "the agent decided" inside them.

---

## Level 1 — Foundation

One or two rounds, eight to twelve questions in total. These decisions shape everything after them. Asking them first means the stack's limits and tools can be researched in the background while Level 2 runs, and that Level 2 asks only forks that still exist given the foundation.

Entry point A (empty folder): this *is* the opening — don't plan blocks before it. Entry points B and C: confirm what the documents or code already settle, ask only the rest.

| # | Question | Recommendation to propose | Why it is a fork |
|---|---|---|---|
| F1 | What is the project in one sentence — and who are you in it: the business that will use it, or a developer building it for a client? | — | Routes every business question |
| F2 | One business uses the system, or many businesses on one platform? | One platform with strict data isolation when more than one | Data model, isolation, roles |
| F3 | A standalone application, or on top of a platform (CloudCart, Medusa, other)? | Standalone unless the users already live in a platform | Stack, login, source of truth |
| F4 | Stack: hosting, database, frontend, API | The user's standards (`technical-decisions.md`, section 1). Name every deviation from them with its reason, and every paid service with its price class | Cost, vendor, limits |
| F5 | Money: are there payments; who holds the money; are there subscriptions to the platform? | No payments in v1 unless the product is about them; the platform never holds money itself | Money flow, legal, data model |
| F6 | External systems it connects to: platform, ERP, payments, calendars, SMS | — | Which integration sections exist |
| F7 | What deliberately does NOT go into the first version? | A list derived from F1–F6, to confirm | Scope |
| F8 | Scale class: tens, thousands, hundreds of thousands of records; concurrent users | A concrete table to confirm | Batching, queues, database |
| F9 | Interface language and the countries it operates in | One language, one country | Currency, time zones, translations |
| F10 | Is anything written down — a document, notes, an old system? | Read it before anything else | Entry point |

Not every F is asked: F3 is skipped in a CloudCart app folder, F10 in a folder with a spec. Write the answers into §1, the outline of §2, Part II (F7), and keep the stack answer for CLAUDE.md.

**After Level 1, before Level 2:** start the research in the background — the platform's limits for the chosen stack, tools and skills for it (`technical-decisions.md`, sections 3 and 5) — with subagents on the cheapest model that does the job. Tell the user in one line that it is running. Create the spec draft now, with §1 filled.

---

## Level 2 — Clarifications, block by block

The rhythm of a block, inverted from "ask then write":

1. **Write the section first.** From the fundamentals, the standards below and the domain, draft the block's section as rules. Mark each place where a real fork exists with `<!-- ? -->`.
2. **Ask the forks** — the marked places, as one round: cap seven, most expensive first, unique numbers.
3. **Give the digest** of the rest: "Decided by standard:" five to ten lines with section references.
4. **Write the answers**, remove the marks, append the digest lines to "Decisions by standard". One line on what was written where. Next block.

Each block lists what the section must **cover**, the **forks** that are usually real, and the **standards** decided without asking. They come from e-commerce and SaaS tooling; adapt to the domain in front of you. Entities and flows repeat per item, but the list of entities (or flows) is confirmed in *one* question as a table, not one question per entity.

### Block 1 — Goal and boundaries → §1

- **Cover:** the problem, for whom, what it is not, what is replaced, data that exists today.
- **Forks:** migrate existing data in v1 or later; the first real user when it changes priorities.
- **Standards:** non-goals written explicitly; success metrics are not part of the software.

### Block 2 — Roles and login → §2

- **Cover:** every role and what it may do; the visitor; how each role gets in; sessions; deactivation; acting on behalf of another; lost access.
- **Forks:** do end customers have accounts or act through emailed links (Calendly-style); self-registration or invitation; a role between owner and staff; may staff act on behalf of customers and under which rules.
- **Standards:** passwordless email code unless the platform provides login; sessions 30 days for customers, 7 for staff; admin-only for settings, deletion and reopening final states; deactivation ends sessions and keeps records; the last admin cannot be removed; lost access is reset by the role above.

### Block 3 — Entities → one section per entity

- **Cover:** data and required fields; uniqueness; relations; who creates, edits, deletes; archiving; history; internal fields; snapshots.
- **Forks:** which fields are required at creation vs later (fast registration); shared across units or per unit (prices per location); which roles may edit; the project's or the platform's (source of truth).
- **Standards:** archive instead of delete once referenced; compound uniqueness where the domain implies it; exactly one primary element; a snapshot of name and price on anything with money; internal notes never reach customers.

### Block 4 — Flows and statuses → one section per flow

- **Cover:** steps and who does each; statuses, transitions, side effects; failures; corrections; concurrency; numbering.
- **Forks:** cancellation and refund policy; what a no-show costs; may the business override the online rules; instant confirmation or approval; what stays frozen on edit; who may reopen a final state.
- **Standards:** linear statuses with two terminal ones; a reason on cancel; the first to confirm wins a contested slot; numbers never change; an email on every status change; corrections only in the first status unless decided otherwise.

### Block 5 — Rules and calculations

- **Cover:** money, discounts, quantities, dates, validations.
- **Forks:** who computes prices and tax (platform or project); discount stacking and priority when discounts exist; business vs calendar days; what is taxed.
- **Standards:** integers in the smallest unit, mathematical rounding per line; a missing price means not orderable; month-end clamps; servers in UTC, business dates in the users' zone; standard format validations; files JPG/PNG/WebP/PDF up to 10 MB.

### Block 6 — Integrations → one section per system

- **Cover:** data and direction; trigger; source of truth; failure behaviour; file formats; credentials; uninstall.
- **Forks:** which system wins on conflict; sync frequency when it costs money or quota; block or degrade when the external system is down.
- **Standards:** webhooks verified by signature and processed idempotently; retry with backoff on 429; one import at a time, re-runnable; duplicates in a file reported; credentials encrypted; a sandbox for development.

### Block 7 — Notifications

- **Cover:** the event × recipient matrix; channel; language; content essentials; test mode.
- **Forks:** SMS or email only (cost); how many reminders and when; who gets internal notifications.
- **Standards:** an email to the counterpart on every status change; errors to staff; test mode so real customers get nothing in development; every email links to its record.

### Block 8 — Screens

- **Cover:** screens per role; lists with search and filters; bulk actions; the settings screen; the design reference.
- **Forks:** the design reference when not embedded; which roles use a phone; bulk actions.
- **Standards:** list and detail per entity for staff; customers see only their own; search by name or code, filters by status and date; confirmation before destructive actions; Tailwind + shadcn/ui.

### Block 9 — Non-functional requirements

- **Cover:** language, devices, scale, performance, security, backups, legal pages.
- **Forks:** legal pages and data-deletion requests in scope; what the user considers too slow.
- **Standards:** backups for the database and separately for files, 30 days; the list of what never leaves the server; logs without personal data; staff on desktop, customers also on phone.

---

## Follow-up rules — the answers steer the questions

**A named reference product comes first.** When the user says "like Calendly", "as in Setmore", "like the Shopify admin", that product is the specification for the block it touches. Look up how it actually behaves — accounts or links, what the customer sees, what the owner configures — before writing the section and before any fork. Proposing the opposite and correcting after the answer costs a round and the user's trust; the trial run did exactly that. Record what you took from it in the spec with the product's name, so the choice is traceable.

Every answer is read for what it opens. Each of these is a new branch on the tree; it either becomes a fork to ask (if it passes the fork test) or a standard to decide and record:

- **A new noun** — an entity nobody listed. Add it to the entity list and tell the user a block was added.
- **A new verb or flow** — an action with its own steps. Chase it: who, in which status, what stays frozen, what is re-sent.
- **An exception** — "except when", "sometimes", "usually". Ask for the exact rule; exceptions are where bugs live.
- **A number or limit** — confirm it and decide what happens at the boundary.
- **A vague word** — "fast", "convenient", "flexible", "optional". Ask what it means concretely here.
- **An external name** — a system, a file, a provider. Open the integration questions for it.
- **A contradiction** with an earlier answer or the document. Point it out; ask which holds.
- **A platform fact** you can't verify — note it for the research instead of asking the user.

A branch that belongs to a later block is parked, and the user is told: "Noted for the notifications block."

## Trigger follow-ups

When the user mentions… ask in the same or the next block:

| Mention | Follow-ups |
|---|---|
| File import / export | formats, encoding, delimiter, columns, size, frequency, who runs it, duplicates in the file, what the report shows, one at a time? |
| "On behalf of" a customer | same rules or different; who is recorded; who gets the emails; may staff exceed limits |
| Several stores / companies / clients on one instance | tenant isolation: what is strictly per tenant, shared settings, per-tenant credentials, uninstall |
| Payments | who collects money (platform or project); payment statuses; manual marking of payment; due dates and terms |
| Delivery | fee rules, taxed or not, who sets the fee, delivery date and who confirms it |
| Discounts / price groups | priority, stacking, nesting (categories), missing price behaviour, display precision |
| Recurring actions (subscriptions, schedules) | interval rules, month-end, pause/resume, what happens when the referenced item disappears, time zone |
| Images / files | types, size, where served from, resizing, deletion, who may upload |
| Search | by which fields, partial match, language specifics |
| Reports | which numbers, for whom, period, export format — usually Part II |
| Stock | who is the source, when it decreases, when it returns, overselling rule, what the customer sees |
| External API | rate limits, duplicates, outage behaviour, sandbox, credentials storage |

---

## Gap-check lenses (Step 2)

Read the finished draft through each lens. Every gap becomes `- [ ] **Q-NN** Question. Proposal: … — _§X_` in "Remaining clarifications".

- **Concurrency** — two actors on the same thing at once; a scheduled run overlapping the previous one.
- **Permissions** — for every action in every flow: who, in which status? Any action without an owner?
- **Lifecycles** — every status has a way in, a way out, and defined side effects? Any status with no exit?
- **Missing or deleted values** — the referenced record no longer exists; the import is empty; keys duplicate; price missing.
- **Money and time** — who computes, where it rounds, which date starts a term, zone, month-end.
- **Integrations** — source of truth on conflict; API down or rate-limited mid-batch; duplicate delivery; uninstall.
- **Scope edges** — anything mentioned once and never detailed.
- **Contradictions** — two sections that disagree.

Then ask the user to decide the questions that block stage 1. Leave the rest open with their proposals.

---

## When the interview ends

All of these must hold:

- No fork remains unasked: every `<!-- ? -->` mark is resolved, every block's frontier is empty.
- Every section of the spec template is filled, marked out of scope, moved to Part II, or has a `Q-NN` with a proposal.
- Every entity and every flow the user mentioned has its own section.
- Part I vs Part II is decided; stages and acceptance criteria are written and were *shown* in digest form.
- The stage-1-blocking questions are decided.
- You read back a ten-line summary and the user confirmed it. Don't act on the tree before that confirmation.

Say it plainly: "The interview is over. From here I derive the technical decisions and the plan from the specification." Then go to `technical-decisions.md`.

**If the user says "I accept everything" or stops answering:** don't take it as permission to decide silently. Stop asking, keep writing, and switch to digest-only mode — every block still produces its "Decided by standard" lines, and the forks you had to decide yourself go to "Remaining clarifications" with your choice as the proposal. Before CLAUDE.md and TASKS.md, give one digest of the ten to fifteen decisions with the highest cost of being wrong and get a single "yes" for it. Mark the status: lines from a digest the user saw are "reviewed", lines written in this mode are "unreviewed"; the final digest clears the mark on what it covers, and the rest become one `Q-NN` in TASKS.md ("Review N unreviewed decisions by standard before the end of stage 1", numbers listed). The mark is how a future session tells a human decision from a default.
