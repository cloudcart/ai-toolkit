# Changelog

## 0.3.4

- Rewrote `docs/project-setup.bg.md` as a pitch rather than a manual: the problem it solves (sessions that start from zero, decisions re-made, lessons lost at compaction), what you get, and why the learning loop matters, with the same install and start instructions.

## 0.3.3

- Added `docs/project-setup.bg.md`: a short Bulgarian guide to what the `project-setup` skill does, how to install and start it, what it needs, and what feedback is useful — for teams trying it out. Linked from the README.

## 0.3.2

- `project-setup` audit mode can now **rebuild** an existing `CLAUDE.md` instead of only patching it. Patching a file that has another structure leaves a file that neither the skills, the hooks nor the user read well, so when more than half of the shape is missing the skill recommends a rebuild: the template is the skeleton, the old content is poured in — under five guarantees, because the usual loss in a rewrite is silent. Nothing is lost (a shown mapping old line → new section, with explicit "dropped because" rows); contradictions are asked, never resolved silently; diff before writing, one commit; principle numbers become canonical and every reference in TASKS.md, BUGS.md, plans, notes and skills changes in the same commit, while task and bug ids never change; the language stays the project's. The user chooses patch or rebuild per file.


## 0.3.1

- `project-setup`: new always-on principle 18, **Requests — record first, assume nothing**. Several requests in one message are recorded in `TASKS.md` after a duplicate check; a request with more than one plausible reading is asked about first and recorded after the answer, never guessed; questions are rationed to one round per message, at most five, each with a recommended reading, because the opposite failure — an agent that asks about everything — is as costly as one that assumes. Wired into the TASKS.md header rules and the project-manager skill's intake. Domain principles now start at 19.


## 0.3.0

New skill: `project-setup`. The toolkit so far helped work *on* a CloudCart store; this one helps start the software project around it — or any other project.

- **Interview in two levels.** A trial run with one long questionnaire showed that rounds of ten or more questions get answered in bulk ("всичко приемам"), which hides the decisions that mattered. The skill now asks the root decisions first (stack included), then goes block by block through the specification: it writes the section, asks only the questions with more than one defensible answer, and shows what it decided by standard as a digest you veto by number. A decision made without a question is still recorded, with a status that says whether a human saw it.
- **Four files plus two project skills.** `specification.md`, `CLAUDE.md` with every architectural decision and its reason and the platform's limits as tables, `TASKS.md` ordered by priority with spec references, `BUGS.md`; and `.claude/skills/project-manager` (a plan before every task, surviving compaction) and `.claude/skills/stage-review` (code and security review at the end of every stage).
- **A memory the agent maintains itself.** A `notes/` layer for what was learned but is not a rule, and hooks that harvest the session transcript in slices *before* compaction — the transcript on disk is append-only through compaction, so nothing is lost and nothing races. Observations seen twice become proposals; the user's "да" turns them into principles or skill fixes. The agent never edits its own rules silently.
- **Environment check.** Auto-compaction window of 500 000 tokens in the project settings, context7 for documentation lookups, a narrow permissions allowlist proposed rather than a blanket one.
- **A session-start hint instead of an onboarding flow.** Claude Code has no hook that runs when a plugin is installed, and a welcome message once is forgotten by the time it is needed. `scripts/setup-hint.sh` runs at session start, looks only at the shape of the folder, and hands the agent a few lines of context where the skill is relevant: an empty folder, code without `CLAUDE.md`, or a `CLAUDE.md` without the rest of the kit — the last one points at the skill's audit mode, since a file's existence says nothing about its quality. Once per folder for the last two, nothing in a set-up project, off with `CLOUDCART_SETUP_HINTS=0`. The audit mode itself now covers the whole kit (project skills, notes, hooks, settings) with approval per group.

The skill is Claude Code first: the interview and the files work on any host, the settings and hooks do not. Requires `bash` and `python3` for the hooks. The kit's source and the agent's notes are English; the project documents follow the project's language, the interview follows the user's.


## 0.2.8

- README: **Turn on auto-update** is now its own section with numbered steps, instead of a sentence buried in a paragraph. Covers what changes once it is on (background refresh shortly after session start, current session keeps its loaded version), how to turn it off, the managed-settings route for team admins, and how it interacts with `DISABLE_AUTOUPDATER`.

## 0.2.7

- README now documents how to update the plugin. It had update notes for the CLI, the Dev MCP and the wiki — all of which refresh themselves — and nothing for the plugin, which does not: Claude Code enables marketplace auto-update by default only for Anthropic's own marketplaces, so a third-party one like this stays on the installed version indefinitely. Adds the manual update commands, how to switch the marketplace to auto-update, and how to check the installed version.

## 0.2.6

Borrowed from the CloudCart support project's `platform-expert` agent, which this skill descends from — and identified why one of its rules does not transfer.

That agent is a sub-agent: it reports to a parent that holds the ticket and writes the merchant reply. "Report completely, completeness beats brevity" is correct there because the recipient is another agent that selects what the merchant sees. This skill has no such parent — a forked skill's result reaches the user close to unedited — so the rule arrived without the filtering layer that made it safe. That was the 0.2.5 bug at its root.

- **Who is reading your answer.** States the audience and that nothing edits the answer downstream, so the selecting is the skill's own job. Adds the two rules that follow: give the click path rather than confirming a fact, and name conditions instead of assuming a store state you cannot see.
- **The question sets the scope, and finishing it is the finish line.** Counterweight to "cover every dimension": once the answer holds with its complete predicate, stop reading. Material never gathered cannot bloat the answer.
- **The "which component owns this" map.** When someone points at a surface, which module produces it and where its content is configured is design knowledge a live-data lookup cannot discover on its own. The skill supplies element → owning component → screen, so a lookup can then read the value.

## 0.2.5

A question answerable by one screen and one field produced roughly 600 words: customer-facing behaviour, courier interactions, a dead-end scenario, a pricing alternative, three unresolved documentation items and a seven-step debugging checklist. The skill was doing what it was told — `Completeness beats brevity` was a non-negotiable, and the thinking framework marked follow-ups and adjacent features as required output.

The rules conflated two different obligations. Reading is where completeness belongs; the answer is where proportion belongs.

- **Read exhaustively, answer proportionately.** Research relentlessly, then write the answer to the question that was asked, at the size that question deserves. Depth found and not needed is what makes the short answer trustworthy, not material owed to the reader.
- **Extra paragraphs must earn their place** by changing what the merchant does next — a prerequisite, a surprising side effect, a blocking gate, a cheaper route to the same goal. Merely true and related is not enough; offer it instead of appending it.
- **The thinking framework's "required" means required to consider, not to publish.** Passing the whole checklist through to the merchant is the failure the checklist exists to prevent.
- **Only uncertainty bearing on the answer given gets reported.** Every gap met while reading is not a finding. One qualified claim reads as careful; five read as unreliable.

## 0.2.4

Asked the same question twice, `cloudcart-platform-expert` gave two confident and contradictory answers about when a minimum-order limit blocks a customer. The cause is a genuine contradiction in the wiki — `settings-cart-limits-and-decrement` says the check fires at order submit, `storefront-cart-customisation` says it blocks the cart's checkout button — which the skill resolved silently instead of reporting. Three fixes:

- **Contradicting pages are the finding.** Where two pages describe the same behaviour differently, report the disagreement and the surface each describes. Never pick the more plausible page, never blend them into a third version. A confident reconciliation hides a real documentation defect, and asked twice it produces two different confident answers.
- **Uncertainty has to survive rendering.** `gaps` was the last field of the output block, and the block gets rewritten into prose before it reaches anyone — so caveats were dropped and the merchant received claims the skill never made. Renamed to `uncertain`, moved above `answer`, and every item must now also appear inline next to the sentence it qualifies.
- **Reassurances are claims.** "Takes effect immediately", "nothing else is affected" read as the absence of a caveat and get written unchecked. The answer asserted immediate effect; no page says it. Also: preserve the source's hedges — a page saying something "usually" happens must not be upgraded into a precise mechanism.

## 0.2.3

- Removed the wiki-gaps log. `cloudcart-platform-expert` no longer writes a gap file — the plugin ships to many separate users, so a local log serves no one. Gaps are still flagged, in the answer itself. The skill now declares `disallowed-tools: Write, Edit, NotebookEdit`, making read-only a property of the skill rather than an instruction it can drift from.
- Corrected the 0.2.2 note below: the "compared after discounts" claim it described as ungrounded is in fact documented, in the `## Related` note on `settings-cart-limits-and-decrement`. The skill now says explicitly that a one-line `## Related` note is documentation and citing it is grounded — which is the stronger reason to traverse Related rather than treat it as a link list.

## 0.2.2

Tightened `cloudcart-platform-expert` after reviewing a real answer against the wiki:

- **Interaction claims.** A sentence describing how one feature interacts with another is where platforms genuinely differ, so it is exactly what cannot be supplied from general knowledge. Such a sentence now has to trace to a page — including to a `## Related` one-liner, which counts.
- **Disambiguation ordering.** The answer resolved one reading of an ambiguous question in full, then disclosed that the question had three and warned the first might be wrong. Disambiguation is now a gate: if you are about to write "but if you actually meant X, don't use the above", lead with the question instead.
- **Hub frontmatter.** An aspect page can carry `plan_gates: []` while the hub that owns the screen carries real gates. Reading only the aspect reports a gated feature as ungated.
- **Label language.** Wiki labels are English; a translated nav path next to an untranslated field name leaves the merchant scanning for a string that is not on screen.

## 0.2.1

- Fixed skill routing: platform questions were dispatching to `cloudcart-dev-mcp-install` instead of `cloudcart-platform-expert`. The platform-expert description now leads with concrete phrasings and carries Bulgarian triggers in Cyrillic rather than only transliterated, trigger phrases moved to `when_to_use`, and each of the other three skills states explicitly when *not* to use it.
- `cloudcart-platform-expert` now states that the Dev MCP's `semantic_search` covers the Admin GraphQL schema, not platform behaviour, so it is not a substitute for the wiki on "how does it work" questions.

## 0.2.0

- Added `cloudcart-platform-expert` — answers how CloudCart is *supposed* to work (navigation, settings, business rules, plan gates), grounded in the CloudCart platform wiki. Runs in a forked context so the verbose wiki reading stays out of the main conversation.
- Added the platform wiki sync: `scripts/sync-wiki.sh` clones [`cloudcart/platform-wiki`](https://github.com/cloudcart/platform-wiki) to `~/.cloudcart-ai-toolkit/wiki`, with a `SessionStart` hook (`hooks/hooks.json`) that refreshes it in the background on Claude Code and a skill-side check that covers every other host. The source is public, so no account or token is required. Freshness is checked with a single `ls-remote` against the remote head, so an up-to-date session pays a fraction of a second instead of a clone.
- Removed `cloudcart-onboarding-merchant`. Store connection (URL parsing, browser sign-in, PAT) now lives in `cloudcart-product-management` Step 0; `cloudcart-cli-install` and `cloudcart-dev-mcp-install` hand off there instead.
- Added `cloudcart-product-management` (previously unreleased) — create, edit, delete, and bulk-import products, with bulk-transform primitives and dry-run/snapshot rules for large sets.

## 0.1.0

Initial release.

- Plugin manifests for Claude Code, Cursor, OpenAI Codex, Gemini CLI, and VS Code (GitHub Copilot).
- Auto-registration of the CloudCart Dev MCP server (`@cloudcart/dev-mcp`) via `.mcp.json`.
- Three skills:
  - `cloudcart-cli-install` — installs `@cloudcart/cli` on demand.
  - `cloudcart-dev-mcp-install` — registers the Dev MCP with hosts that don't support plugin auto-install.
  - `cloudcart-onboarding-merchant` — guides merchants through CLI install, store auth, and day-to-day operations via the MCP-first GraphQL workflow.
