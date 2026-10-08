# Writing guide for the four files

## specification.md

Built during the interview from `assets/specification.md.template`, one block at a time. It is the single source of truth for scope, so it is written as **rules**, not as meeting notes: "The customer can pause a subscription. Staff can do everything." — never "we discussed that the customer will probably want to pause".

Structure:

- **Part I — First version**: §1 goal; §2 roles and login; one section per entity (data, rules, who may do what); one section per flow (steps, statuses, side effects, errors, corrections); rules and calculations; one section per integration; notifications; administration; client side; core technical requirements.
- **Part II — Later extensions**: every feature deferred in Step 3, two or three sentences each — enough that nobody builds it by accident and nobody forgets it.
- **Part III — Delivery and acceptance**: stages (3–5, each a usable increment, stage 1 = core data and access), acceptance criteria per stage as testable sentences in the user's words, decisions by standard (one line per rule decided without a question, with its section and a status, `reviewed` or `unreviewed` — the digest's durable home; the unreviewed ones have a `Q-NN` in TASKS.md), remaining clarifications (the `Q-NN` list with proposals; when the user is a developer for a client, a sub-heading "Questions for the business" holds the product forks the business must decide).

Rules:

- Every rule in Part I is testable — numbers, limits, who may do what. "A convenient interface" is not a rule; "a modal for quick edit, confirmation before deletion" is.
- Numbered sections (`## 3.`, `### 3.1.`) — tasks will reference them as `§3.1`. Don't renumber once TASKS.md exists; add new sections at the end of their part.
- A section the user explicitly put out of scope says so in one line, so the question isn't asked again.
- When an open question is decided later, the answer is written into the section it concerns and the `Q-NN` is marked `[x]` — both in the spec and in TASKS.md.

## CLAUDE.md

Target density: `references/example-claude-md.md` — about 150 lines for a mid-size project. Every line is either a fact a future session needs or a rule with its reason. No generic advice ("write clean code") unless it comes with a concrete rule.

Sections, in this order:

1. **Title + one sentence** — what the project is.
2. **`## Files`** — the spec (named as the single source of scope), `TASKS.md`, `BUGS.md`, `plans/` (per-task plans), `.claude/skills/` (`project-manager`, `stage-review`).
3. **`## Stack`** — one bullet per concern. Name the library and the guide you follow where it matters.
4. **`### Architecture`** — decisions as bullets; every non-obvious one carries its reason in the same bullet. Cover: services and how they talk, who touches the database, tenant isolation, source of truth, atomicity, idempotency, background work, external rate limits, money, dates, secrets, scale numbers.
5. **`### <component> limits`** — one table per constraining component; below each, the rules that follow. Include the required plan tier and why.
6. **`## Order of work`** — the phases, one line each.
7. **`## Work cycle for every task`** — the six steps as agreed; step 2 is "plan with `project-manager`, then execute by the plan", step 6 is "one commit per task, pushed".
8. **`## Principles`** — numbered from 0, each with a `###` heading and one to five bullets. Only the ones that apply, but principles 10 (plan before execution), 12 (propose new principles), 13 (keep the skills current), 14 (one commit per task), 15 (secrets never in git), 16 (subagents on the cheapest model that does the job), 17 (notes — working memory) and 18 (requests — record first, assume nothing) are always there, and 11 (schema and migrations) whenever there is a database. Principles are written general — the engine-specific numbers live in the limits tables. Domain principles follow from 19. The file ends with the import line `@notes/INDEX.md`, which loads the notes index into every session.

What doesn't belong: the task list, the spec's content (reference it), setup commands that will change (a README written during T-101).

## TASKS.md

### Header

Title ("Tasks — first version"), the source and reference convention (`§X`), the scope boundary (first version only; Part II excluded by name with its section range), the order statement **including that order is priority**, and a **Rules** block:

- mark `[x]` only after two tests;
- work discovered during another task → "New tasks", not done in motion;
- bugs → `BUGS.md`;
- gaps and decisions → "Open questions"; once decided, the answer goes into the spec and the question is marked `[x]`;
- "New tasks" is a waiting room, not a queue: at the end of every task each new task gets a number in its phase and a place by priority, or goes to Part II of the spec;
- a client request in chat is a new task; the client decides when — "now" makes it the next task, otherwise it waits for triage;
- the last task of every stage is "End of stage N", run by the project's `stage-review` skill.

### Before start

Right after the header rules, before Phase 1: a checklist of everything outside the repository that the first tasks need — always including two items for the notes layer: "on first open Claude Code will ask you to approve the hooks from `.claude/settings.json` — accept them" and "`python3` must be available (the hooks use it)" — accounts and plans, repository and CI, domain and DNS, sending domain, keys, tools and skills to install. Each line says who does it: the agent through a tool (after the user's yes), the agent through an API with a key from the user, or only the user. This is where "What I need from you" lives — not in the chat.

### Phases and numbering

Task ids encode the phase, so a number alone says where a task belongs:

| Phase | Ids | Typical subsections |
|---|---|---|
| Phase 1 — Backend | T-1xx | 1.1 Foundation (repo structure, tooling incl. CI on every push and a pre-commit hook running lint/typecheck/tests, `.gitignore` for secrets, DB + migrations + local env, storage, logging) → 1.2 Database schema (one task per entity, with constraints and indexes) → 1.3 Security and access → 1.4 Business logic |
| Phase 2 — API | T-2xx | One task per domain area for each audience (admin / customer), plus webhook, upload and download tasks |
| Phase 3 — UI | T-3xx | 3.1 Foundation (design tokens, layout, shared components) → Components per app → Blocks per app → Pages per app |
| Phase 4 — Checks and acceptance | T-4xx | Acceptance criteria, backup and restore check, mobile check, fixing discrepancies, load and concurrency scenarios |

Numbers are assigned once and never reused. A task added later keeps its number and sits where it belongs in the order — T-138 between T-118 and T-119 is fine.

Separate phases with `---`.

### Order = priority

A session takes the next unchecked task, so the order of the list is the priority. Inside each phase and subsection, order by:

1. **Dependencies** — nothing is listed before what it needs (schema before logic, logic before API, components before pages).
2. **Stage** — features of stage 1 (Part III) before stage 2, and so on. When a subsection mixes stages, group the tasks by stage and say which stage a group serves in a short intro line.
3. **Core before supporting** — the central flow before the convenience around it.

Triage keeps the order alive: a task born in "New tasks" is placed by the same three rules when it gets its number, never appended at the end of a phase by default.

If the user chose vertical slices in Step 4, phases are stages instead (Phase 1 — Stage 1 …), ids encode the stage, and inside a stage the order is backend → API → UI.

### End of stage

Every stage from Part III ends with one explicit task, placed right after the last task that completes the stage (usually in the UI phase; the final one in Phase 4): `End of stage N — stage-review: code and security review, findings in BUGS.md, fixed one by one, triage of "New tasks", acceptance criteria of stage N`, referenced `_Part III, Stage N_`. It is a real task with a number, so "take the next unchecked task" reaches it. Its plan is to run the `stage-review` skill.

### Granularity

A task is one deliverable that can be tested on its own and done in one working session. Too small ("add a column") creates bookkeeping; too big ("subscriptions") can never be marked done. A mid-size first version lands around 60–90 tasks.

Put into the task text the rules that define it — numbers, limits, edge behaviour — so the implementer has the essentials without re-reading the spec, while the spec stays the source of truth:

> - [ ] **T-111** Customer login with an email code: 6 digits, 10 minutes, up to 5 attempts, the same response whether or not the email belongs to a store customer. Codes stored hashed. Session 30 days. — _§2.3_

Every task ends with `— _§X, Y_`. A task that triggers or depends on another names it in the text ("Sends an email (T-125)"). Infrastructure constraints that apply (batching, no per-row queries, streaming, idempotency) are repeated in the task — they are the things most often forgotten.

Business-logic tasks: each is one reusable module covered by tests. Say so once in the subsection intro.

### The UI phase

Three levels, each its own subsection per app:

- **Components** — primitives: button, input, select, table, status badge, money and date formatting, image with `srcset`, quantity stepper, pagination.
- **Blocks** — composites: filter bar, lines table, address picker, form with validation in a modal or on a page, confirm dialog.
- **Pages** — assembled from blocks; one task per page or tightly related group.

Components shared by two apps get one task in "Foundation".

### Phase 4

Always include: the final "End of stage" — `stage-review` over the whole first version — together with checking every acceptance criterion from the spec (one task referencing the section); setting up and *verifying* backup and restore for the database and separately for files; checking on a phone; fixing the discrepancies found; a load/concurrency scenario written for this project ("the same queue message delivered twice — one order"; "a nightly run over 2 000 records with one date").

### Open questions

After Phase 4, before "New tasks". Intro: "Questions that need a decision. The current behaviour in the specification is the proposal." Items as `Q-NN`, carried over from the spec; decided ones `[x]` with the decision in bold and the resulting rule in one sentence.

Under "Open questions" a sub-heading "Process proposals" holds `P-NN` items: proposed principles (principle 12) and global-skill changes (principle 13), each with the reason and the evidence (the `observation` note, the tasks). The developer decides these, not the client. A decided item is marked `[x]` with where it went ("→ principle 11") or "rejected" and a word why — never deleted, so the origin of every rule stays traceable.

### New tasks

Last section. Intro: "Tasks found during work. Added here with a reference to the task they were found in." Starts as `_None._`.

## BUGS.md

The same for every project. Intro rules: bugs are recorded, not fixed in motion; the exception is a bug that blocks the current task — recorded and fixed now, in the same commit, named; who fixes which bug (related task → after it; unowned → gets an owner at triage: next task in the area or "End of stage N"; stage-review findings → all recorded by severity first, then fixed one by one, each with a failing test and its own `B-NNN` commit). Then the `B-NNN` format block with severity, found during, related to, owned by, steps, expected, actual, status (Open | Fixed | Verified | Deferred by client), the severity definitions, `## Open`, `## Closed`, both starting `_None._`.
