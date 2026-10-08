---
name: project-setup
description: "Lead a guided, step-by-step discovery interview for a new software project and turn it into a complete starting kit: a functional specification (specification.md) built block by block from the user's answers, then CLAUDE.md (stack, architecture decisions with reasons, platform limits, work order, principles), TASKS.md (tasks ordered by priority with spec references and open questions) and BUGS.md. The interview reads whatever exists first (spec, code), asks only what is missing, proposes defaults, surfaces the things the user hasn't thought of, and writes every answer into the spec draft right away. Use it whenever the user wants to start, set up, structure or plan a project, write or complete a specification, turn a spec into a task list, be interviewed about a project, or audit an existing CLAUDE.md/TASKS.md/BUGS.md — even if they don't name the files. Bulgarian triggers: сетъп на проект, първоначален сетъп, нов проект, стартирам проект, направи спецификация, план за действие, направи claude.md, tasks.md, bugs.md, разбий спецификацията на задачи, задай ми въпроси за проекта, интервю за проекта."
compatibility: Claude Code. The interview and the four files work on any host; the environment check, the project settings and the harvest hooks are Claude Code specific.
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.1.0"
---

# Project Setup

The first hours of a project decide how the next hundred go. This skill leads the user through a structured discovery and leaves four files behind:

- `specification.md` — **what** is being built: goal, roles, entities, flows, rules, integrations, notifications, screens, non-functional requirements; what is in the first version and what comes later; stages and acceptance criteria. The single source of truth for scope.
- `CLAUDE.md` — **how**: stack, every architectural decision with its reason, the platform's hard limits, the order of work, the working principles. A future session reads it and doesn't re-decide.
- `TASKS.md` — **in what order**: numbered tasks anchored to spec sections, ordered by priority, plus open questions awaiting a decision and new tasks found along the way.
- `BUGS.md` — bugs get written down instead of fixed in motion.
- `.claude/skills/project-manager/SKILL.md` — a project-local skill that plans every task from the spec before executing it (principle 10 of CLAUDE.md). Plans land in `plans/T-NNN.md`.
- `.claude/skills/stage-review/SKILL.md` — a project-local skill that reviews code and security at the end of every stage, writes every finding to `BUGS.md`, fixes them one by one, and checks the stage's acceptance criteria.

The user may be a developer or a business owner, and the "client" being interviewed may not be technical. The discovery part (Steps 1–3) uses business language. The technical part (Step 4) proposes a stack from the project's shape whenever the user hasn't named one, and explains the consequences in plain language — a developer corrects it, a non-technical user confirms it.

## The process at a glance

| Step | What happens | Writes |
|---|---|---|
| 0 | Read what exists: spec, code, manifests, existing files | nothing yet |
| 1 | Discovery interview in two levels: Foundation (root decisions, stack included; research starts in the background), then Clarifications block by block — each section written first, only real forks asked, the rest decided by standard and listed in a digest | `specification.md` (Part I, "Decisions by standard") |
| 2 | Gap check: read the draft adversarially, turn every gap into a question with a proposal; the user decides the blocking ones | spec "Remaining clarifications" |
| 3 | Priorities: first version vs later, stages, acceptance criteria | spec Part II and III |
| 4 | Technical decisions, platform limits research | `CLAUDE.md` |
| 5 | Plan: tasks derived from the spec, ordered by priority, with a "End of stage" task per stage; install the project skills | `TASKS.md`, `BUGS.md`, `.claude/skills/project-manager/`, `.claude/skills/stage-review/` |
| 6 | Hand over: short summary, next step | — |

Steps 1–3 are the interview. It has a defined end (below). Everything after it is derivation from the files, with the user confirming each file.

## Language

**Speak the user's language.** Every question, digest, proposal and hand-over goes to the user in the language they write in. The English phrases quoted in this skill and its references — the digest header "Decided by standard:", the question format, the closing line — are examples of what to say, not strings to repeat: say them in the user's language.

The kit's source — templates, references, project skills, notes rules, the harvester — is English, and so is everything agent-facing it produces: `notes/`, the index, inbox files, harvester output, whatever the project's language. Human-facing project documents — the specification, `CLAUDE.md`, `TASKS.md`, `BUGS.md`, the plans — follow the project's language: the specification's if one exists, otherwise the user's. When that language isn't English, translate the templates' section names consistently (one glossary for the whole project, written once into `CLAUDE.md` → `## Files`) and keep the structure, ids and formats unchanged, so the skills and hooks still find what they look for.

## Step 0 — Look first, then choose the entry point

Never ask before looking. List the folder, then take the entry point that matches:

**A. Empty folder — nothing about the project.** Don't guess and don't announce a plan of blocks yet. Open with Level 1 of the interview — the foundation round (`references/interview.md`, Level 1): what it is and who the user is in it, one or many businesses, standalone or on a platform, the stack with your standards as the recommendation, money, external systems, what stays out of v1, scale, language. From the answers derive the entities and flows you heard, tell the user how Level 2 will go for *this* project, create the spec draft from `assets/specification.md.template` with §1 filled, start the limits and tools research in the background, and continue with Block 2.

**B. Documents exist — a spec, a brief, notes.** Read all of it fully, including the tail: acceptance criteria and "remaining clarifications" hide the best open questions. Map it onto the nine blocks and mark each *covered*, *partly covered* or *empty*. If the document already is a specification, it becomes the draft — don't create a second one; otherwise create the skeleton and fill it from the document. Then, before any question, tell the user in about ten lines what you understood and what is missing. Ask only for the gaps, block by block, starting from the first incomplete block.

**C. Code exists.** Read the structure, manifests (`package.json`, `wrangler.toml`, `pyproject.toml`), routes, schema or migrations, README. Derive the stack and the features that already exist. Tell the user what you found. Entities and flows visible in the schema are *known* items to confirm, not to ask about. The interview then focuses on what is missing or next.

**D. `CLAUDE.md`, `TASKS.md` or `BUGS.md` exist.** Audit mode (below). Never overwrite a file you haven't read.

Entry points combine: a folder with code and a brief gets B and C. In every case the user hears what you already know before the first question — asking what the folder answers wastes their attention and signals you didn't read it.

**Environment check — before the first question, in every entry point.** Follow `references/claude-settings.md`: the auto-compaction window must be 500 000 tokens (`autoCompactWindow` in the project's `.claude/settings.json`), the context7 MCP must be available and authorised (add it at project scope or start its login), the platform's tooling (CloudCart dev MCP, Medusa plugins) is proposed when the project needs it, and a narrow permissions allowlist for the work cycle's commands is proposed, never a blanket one. Fix what needs no user, ask for the rest, report in two or three lines, and don't block the interview on it — but remind before Step 4, which needs the documentation lookups.

## Step 1 — Discovery interview

The interview has two levels, and at both only **forks** reach the user.

**Level 1 — Foundation.** One or two rounds, eight to twelve questions: what the project is and who the user is in it (the business, or a developer building for a client), one or many businesses, standalone or on a platform, the stack, money, external systems, the boundary of the first version, scale, language. These are the root of the design tree; everything else hangs off them, so they are asked first and the stack's limits and tools are researched in the background while Level 2 runs. The questions and recommendations are in `references/interview.md`, Level 1.

**Level 2 — Clarifications.** Nine blocks in a fixed order — goal and boundaries, roles and login, entities, flows and statuses, rules and calculations, integrations, notifications, screens, non-functional — because later blocks hang off earlier ones. The rhythm of a block is inverted from "ask, then write":

1. **Write the section first**, as rules, from the fundamentals, the standards and the domain. Mark each real fork inside it with `<!-- ? -->`.
2. **Ask the forks** as one round: unique numbers for the whole interview (#1 … #40, never restarting, never "#1b"), cap of seven, most expensive-to-get-wrong first, each with a recommended answer worded so "yes" accepts it.
3. **Give the digest** of what you decided without asking: "Decided by standard:" five to ten one-line decisions with their spec section. The user vetoes a line by number.
4. **Write the answers**, remove the marks, append the digest lines to the spec's "Decisions by standard". One line on what was written where. Next block.

### The fork test

A question is asked only if **only the user can answer it** — competent people would differ depending on budget, market, business model, client, timeline, taste — or if it is **expensive to change**: it alters the data model, the flow of money, the roles or the scope. Everything else — standards, security practice, platform constraints, consequences of earlier decisions, anything cheaply reversible — is decided and written as a rule. Asking the user to confirm the obviously right answer costs attention and teaches them to answer "yes" without reading; deciding a real fork for them costs a rewrite. The test is in `references/interview.md` with examples.

### Business questions

Asked only as product forks with software consequences, and phrased as such ("a page per salon, or one shared catalogue"), never as business questions ("how does the customer find the salon"). Metrics and price levels are not asked. When the user is a developer building for a client, business forks go to "Remaining clarifications" under "Questions for the business" with the recommended default, not to the developer.

### Mechanics

- Facts are yours, decisions are the user's: anything the folder, the code, the documentation or context7 can answer is looked up, never asked. A running lookup blocks only the questions downstream of it.
- Never ask what the folder or an earlier answer already settled. Confirm it instead.
- `AskUserQuestion`, when available, may carry a round of up to four pure-choice forks with the recommended option first and "(Recommended)"; for anything else use the text format from `references/interview.md`.
- Write after every block, not at the end: the interview outlives the chat's context, the file is the memory, and the user can fix a sentence in the file instead of answering again.

## Step 2 — Gap check

When the nine blocks are written, read the whole draft adversarially through the lenses in `references/interview.md` (concurrency, permissions, lifecycles, missing values, money and time, integrations, scope edges, contradictions). Write each gap into "Remaining clarifications" as `Q-NN` with a proposed answer and the section it concerns.

Then ask the user to decide the questions that would block the first stage of work. The rest stay open with their proposals — a future session can continue on the default if told to.

## Step 3 — Priorities, stages, acceptance criteria

1. **First version vs later.** List every feature in the draft and ask: must it be there at launch? What isn't goes to Part II, described in two or three sentences each so it isn't built by accident.
2. **Stages inside the first version.** Propose three to five stages, each a usable increment; stage 1 is always core data and access. This ranking is the priority that will order TASKS.md.
3. **Acceptance criteria.** Write testable sentences per stage, in the user's words ("A customer sees only their own subscriptions."), and show them as a digest — they follow from the rules, so they are reviewed, not asked. Ask only for the ones you may have missed.

The Part I / Part II boundary and the stage order are forks — they are scope and priority, so they are asked, with your ranking as the recommendation. Write Part II and Part III of the spec.

## When the interview ends

The interview is over when all of these hold:

- No fork remains unasked: every `<!-- ? -->` mark is resolved and every block's frontier is empty.
- Every section of the spec template is filled, or explicitly marked out of scope, or moved to Part II, or has a `Q-NN` with a proposal.
- Every entity and every flow the user mentioned has its own section.
- Part I vs Part II is decided; stages and acceptance criteria exist and were shown in digest form.
- The blocking open questions are decided.
- You have read back a ten-line summary of the project and the user has confirmed it — don't act on the tree until they confirm you have reached a shared understanding.

If the user says "I accept everything" or stops answering, that is not permission to decide silently: stop asking, keep writing, keep producing the digests, send the forks you had to decide to "Remaining clarifications" with your choice as the proposal, and before CLAUDE.md and TASKS.md give one digest of the ten to fifteen decisions with the highest cost of being wrong and get a single "yes" for it. Every line in "Decisions by standard" carries a status: a digest the user saw and did not veto makes its lines "reviewed"; lines written in this mode are "unreviewed" until the final digest covers them. The ones still unreviewed become one open question in TASKS.md — "Review N unreviewed decisions by standard before the end of stage 1" with their numbers — so a future session can tell a human decision from an agent's default, and stage-review closes it at acceptance.

Say explicitly that the interview is finished and that the rest is derivation from the specification. From here on, questions are technical.

## Step 4 — Technical decisions → CLAUDE.md

The stack was decided in Level 1 of the interview; here it is only confirmed against what the specification turned out to need. Work through `references/technical-decisions.md`: project shape and stack, hosting and plan, architecture (isolation, source of truth, atomicity, idempotency, background work, money, dates), the platform limits to research, the order of work and the working principles. Many answers are already in the spec — scale, integrations, notifications, files — so this step translates them into decisions rather than asking again.

If the user hasn't named a stack, propose one from the project's shape — platform, integrations, scale, background work, UI — with the reason for each choice and what it means for them: which hosting account and plan, roughly what it costs, what they will have to create themselves. A developer corrects it; a non-technical user confirms it. Don't ask anyone to choose between things they can't compare. Environments and deployment are the user's decision — don't define them; note in CLAUDE.md what the user decided, or that it is still theirs to decide.

Once the stack is fixed, look for tools and skills that fit it — the user's own skills first, then installed plugins, then the public registry — and propose the ones worth adding, with one reason each; install only after an explicit yes. The rule and the places to look are in `references/technical-decisions.md`, section 5. Don't bundle lists: search for what this project needs.

Research the hard limits of the chosen platform in context7 or the official docs, not from memory. If context7 still needs its login here, use the official docs through WebFetch, stamp the tables with the date and source, and move the login to "Before start" — one reminder was enough (`references/claude-settings.md`, section 2). Limits are the facts a future session is most likely to get wrong by assuming. Put the ones that matter as tables in CLAUDE.md, each followed by the rules it implies.

When the project has a UI, styling is Tailwind CSS and components are shadcn/ui — a rule, not a preference; it goes into `## Stack` and principle 7, and setting them up is part of T-101.

Write `CLAUDE.md` from `assets/CLAUDE.md.template` following `references/writing-guide.md`. Read `references/example-claude-md.md` once before your first one to calibrate the density: every bullet is a decision, non-obvious ones carry their reason. Show the file; corrections here change which tasks exist.

## Step 5 — Plan → TASKS.md and BUGS.md

Derive tasks from the specification section by section, following `references/writing-guide.md`: ids encode the phase (T-1xx backend, T-2xx API, T-3xx UI, T-4xx acceptance), every task ends with its spec reference, rules with numbers live inside the task text.

**The order of tasks is the priority.** A session takes the next unchecked task, so order means: dependencies first (nothing is listed before what it needs), then by the stage of the feature from Part III (stage 1 features before stage 2 within each phase), then core flows before supporting features. Say this in the TASKS.md header so future sessions keep it.

Carry the open questions from the spec into "Open questions" as `Q-NN`. Write the "Before start" section: everything outside the repository the first tasks need — accounts and plans, domain, DNS, sending domain, keys, repository and CI — each line saying whether you will do it yourself through a tool (after the user's yes), through an API with a key, or whether only the user can. Write `BUGS.md` from its template. `references/example-tasks-md.md` shows the result for the illustrative project.

**Stage-end tasks.** The last task of every stage from Part III is "End of stage N" — a numbered task placed right after the task that completes the stage; the final one is in Phase 4. Its plan is to run `stage-review`: fresh-context review of the stage's code against the spec, CLAUDE.md and the security checklist, every finding into `BUGS.md`, fixes one by one with one commit each, triage of "New tasks", the stage's acceptance criteria checked through the real entry points.

**T-101 enforces the rules by tooling.** Besides repo structure, strict TypeScript, linter, formatter and tests, it sets up CI that runs lint, typecheck and tests on every push, a pre-commit hook running the same, and a `.gitignore` that covers secrets. Principles 3, 14 and 15 are enforced by tooling, not by discipline.

**Install the project skills.** Copy `assets/project-manager-skill/SKILL.md` to `.claude/skills/project-manager/SKILL.md` and `assets/stage-review-skill/SKILL.md` to `.claude/skills/stage-review/SKILL.md` in the project (keep them in English — they are agent-facing). `project-manager` is what principle 10 and step 2 of the work cycle point to: every task starts with a plan in `plans/T-NNN.md`, questions that change the plan are asked first, execution follows the plan and records deviations; it also carries the session-start protocol (an unfinished plan is the current task). `stage-review` is what every "End of stage" task runs. Say in the hand-over that the first task will begin with `project-manager`.

**Install the notes layer and the harvest hooks.** Copy `assets/notes/` to `notes/` (the rules in `README.md`, the empty `INDEX.md`, the `_inbox/`), and `assets/harvest/harvest.sh`, `harvest_filter.py`, `harvest_prompt.md` to `.claude/hooks/` (keep the executable bit). Write `.claude/settings.json` from `assets/harvest/settings.json` — it carries both the auto-compaction window and the three hooks (`Stop`, `PreCompact`, `SessionStart` on `compact`); merge if the file exists. Append `assets/harvest/gitignore.snippet` to `.gitignore`. Check `python3` is on the path — the hooks need it, and say so in "Before start" if it is missing. Mechanics and the ambiguities already resolved are in `references/claude-settings.md`, section 5. `CLAUDE.md` ends with `@notes/INDEX.md`, so the index is in every session; principle 17 explains the ladder from chat to rule.

Do not scaffold code. Repository structure, tooling and local environment are `T-101` — the first task, done in the first working session under the rules just established, starting with its plan.

## Step 6 — Hand over

At most fifteen lines: the four files, the two project skills and the notes layer with its hooks, tasks per phase and per stage, the open questions that still block something, what research changed, and the next step ("Start with T-101 from TASKS.md"). Everything else is already in the files — that is principle 9 of the setup itself. The list of what is needed from the user lives in TASKS.md → "Before start", not in the chat; point to it.

**Tools first, then the user.** For every item in "Before start", before asking the user to do it, check whether a CLI or MCP for that service exists — search, don't assume (`references/technical-decisions.md`, section 5): if it does, ask the user's explicit permission to install it and do the work yourself; if there is none but the service has an API, use the API with a key the user gives you; only when neither exists give step-by-step instructions. Installing a CLI or an MCP server happens only after the user's explicit yes — never silently. What genuinely needs a human — a paid account, buying a domain, approving an OAuth login — is listed plainly, with the steps.

## Audit mode

When `CLAUDE.md`, `TASKS.md` or `BUGS.md` already exist, the job is completeness, not restyling, and the user's wording stays where it works. Read everything that exists — the three files, the spec, `.claude/skills/`, `notes/`, `.claude/hooks/`, `.claude/settings.json` — then compare against the kit and write one list of findings, grouped:

1. **CLAUDE.md** — decisions without reasons, no stack section, no limits tables, no order of work, no work cycle, missing principles (10 plan, 11 schema if there is a database, 12–18), domain principles that are really rules of the spec.
2. **Specification** — missing, or missing Part II / Part III (stages, acceptance criteria, decisions by standard, remaining clarifications); spec blocks never covered.
3. **TASKS.md** — tasks without spec references, numbering that doesn't encode the phase, order that isn't priority, no "Open questions", no "Process proposals", no "End of stage" tasks, no "Before start", no T-101 with CI and pre-commit.
4. **BUGS.md** — missing, or without the format (severity, who fixes, status).
5. **Project skills, notes, hooks, settings** — `project-manager` and `stage-review` missing or older than the kit's assets, no `notes/` or no `@notes/INDEX.md` import, no harvest hooks, auto-compaction window not set, hooks not approved (`.claude/harvest-state/harvest.log` empty after real work).

Show the list with a proposed action per item and get a "yes" per group — never one blanket yes, the digest rule applies here too. Run the interview only for the blocks the spec never covered. Then make the approved edits, never overwriting a file you haven't read, and finish with the Step 6 hand-over. A project set up by an older version of this skill is the common case: usually everything in groups 1–4 is there and group 5 is missing.

**Patch or rebuild.** With the list, recommend one of two ways to apply it, per file, and let the user choose:

- **Patch** — the file already has the kit's shape and only items are missing. Add them in place, keep everything else as it is. The default for a project set up by an earlier version of this skill.
- **Rebuild** — the file is far from the shape: more than half of the sections are missing, the order is different, or principles and decisions are mixed into prose. Build the new file from the template and pour the old content into it. Patches on a file with another structure leave a file that neither the skills, the hooks nor the user read well, so a rebuild is the better service here — under five guarantees, because the usual loss in a rewrite is silent: one reason, one number, one exception that is simply no longer there.
  1. **Nothing is lost.** Every line of the old file gets a place in the new one, or an explicit row "dropped — duplicate of X / contradicts Y, decided by the user". Show the mapping (old line → new section) before writing. Reasons, numbers and exceptions are carried over verbatim.
  2. **Contradictions are asked, never resolved silently** — the old file says one thing, the template another → a question with a recommended answer, under principle 18's rules.
  3. **Diff before writing, one commit.** Show the new file, write it after the "yes"; the old version stays in git history.
  4. **Numbers stay consistent across files.** The kit's principles take their canonical numbers (0–18), domain principles move to 19+, and every reference ("principle 7", "принцип 7") in TASKS.md, BUGS.md, plans, notes and the project skills is updated in the same commit. Task and bug ids never change — in TASKS.md and BUGS.md a rebuild reorders sections only.
  5. **The language stays the project's.** The template gives the structure, not the language.

## Files in this skill

- `references/interview.md` — the fork test, the round rules (unique numbers, cap of seven, format), the business-question rule, the digest, Level 1 (foundation questions) and Level 2 (nine blocks: cover / forks / standards), trigger table, gap-check lenses, end criterion. The round mechanics are mattpocock/skills' *grilling*.
- `references/claude-settings.md` — the environment check: auto-compaction window, context7 MCP, platform tooling, permissions, and the harvest hooks (section 5: mechanics, resolved ambiguities, how to verify they run).
- `references/technical-decisions.md` — Step 4: stack by project shape, hosting, architecture questions, limits to research, work process and default principles.
- `references/writing-guide.md` — how to write each of the four files: sections, depth, numbering, priority ordering.
- `references/example-claude-md.md`, `references/example-tasks-md.md` — a complete CLAUDE.md and a trimmed TASKS.md for an illustrative, fictional project (a subscriptions app for CloudCart stores). Read before writing your first ones.
- `assets/specification.md.template`, `assets/CLAUDE.md.template`, `assets/TASKS.md.template`, `assets/BUGS.md.template` — the file skeletons.
- `assets/project-manager-skill/SKILL.md` — the project-local planning skill, copied into each project's `.claude/skills/project-manager/`. Modelled on obra/superpowers writing-plans + executing-plans and mattpocock/skills grilling.
- `assets/stage-review-skill/SKILL.md` — the project-local end-of-stage code and security review, copied into `.claude/skills/stage-review/`; its step 6 is the big consolidation of the notes.
- `assets/notes/` — the notes layer (principle 17): `README.md` with the rules and the ladder, empty `INDEX.md`, `_inbox/`. Copied to the project's `notes/`.
- `assets/harvest/` — the harvest hooks: `harvest.sh` (Stop / PreCompact / SessionStart), `harvest_filter.py` (transcript → compact text, secrets redacted), `harvest_prompt.md` (what counts as a note), `settings.json` (auto-compaction + hooks), `gitignore.snippet`. Copied to `.claude/hooks/` and `.claude/settings.json`.
