---
name: stage-review
description: "Code and security review at the end of every stage of the project. Use for the \"End of stage N\" task from TASKS.md, for \"review the stage\", \"check security\", \"code review\", and before accepting the first version. Reviews the stage's code with fresh eyes against the specification, CLAUDE.md and a security checklist, records every finding as a bug in BUGS.md, then fixes them one by one with a separate commit for each, and finally checks the stage's acceptance criteria."
---

# Stage review — code and security review at the end of a stage

The same author has the same blind spots. This skill is the second pair of eyes: once per stage, over everything written since the stage began, with the question "what does a person using this software get", not "does the diff look right". Findings are not fixed in motion — first all of them are recorded in `BUGS.md`, then they are fixed one by one. That way nothing is lost, and the order is by severity, not by order of discovery.

**Language.** Talk to the user in the language they write in. Plans, journals and everything in `TASKS.md`, `BUGS.md` and `CLAUDE.md` follow the project's language (the one `CLAUDE.md` is written in). Notes in `notes/` are always English. The phrases quoted in this skill are examples, not strings to repeat.

## When

- The "End of stage N" task from `TASKS.md` — the last task of every stage.
- Before "Check of all acceptance criteria" in Phase 4 — the final stage.
- On request: "do a review", "check security".

## 1. Scope

1. Find the start of the stage: the commit of the last task of the previous stage (`git log` by task numbers) or the start of history for stage 1. The scope is `git diff <start>..HEAD` plus the files it touches, read in full.
2. Read from the specification the sections of all tasks in the stage and the stage's acceptance criteria (Part III).
3. Read `CLAUDE.md` in full — the principles and limits are the yardstick.
4. Read the open bugs in `BUGS.md`, so they are not duplicated.

## 2. Review with fresh context

The review is done from a context that did not write the code:

- If a subagent tool (`Agent`) is available, run one reviewer with the most capable available model and give it: the scope (the range and the files), the path to the specification and `CLAUDE.md`, the two checklists below, and the finding format. It returns a list, not fixes.
- If the `code-review` and `security-review` skills are available in the environment, run them over the range as a first pass and merge their findings into the same list.
- If neither is available, do the review yourself, as a separate pass after the end of the stage, and mark it in `BUGS.md` as "self-review" — it is weaker than a fresh review and the client should know.

### Code checklist

- **Coverage** — every rule from the stage's sections has code and a test. A rule without a test is a finding.
- **Specification over code** — behaviour that contradicts a section of the specification is a bug, even if the test passes.
- **Tests test the rules** — the boundary values from the specification ("up to 5 attempts" → the sixth), not only the happy path.
- **Principles 1 and 11** — queries per row (N+1), missing indexes for filters and sorts, `select *`, missing pagination, migrations edited after commit, `CHECK` on a NULL column without an explicit condition.
- **Principle 5** — the same logic in two places (prices, dates, statuses, formatting).
- **Principle 6** — workarounds: a `try/catch` that swallows, `// TODO`, special cases that hide a cause.
- **Principle 7** — hard-coded colours, spacing and texts in components; logic in a page instead of a component; a CSS framework or component library other than Tailwind and shadcn/ui.
- **Limits** — code that would exceed a limit from the tables in `CLAUDE.md` at the scale from the specification.
- **Idempotency** — a queue consumer or webhook that does not recognise a repeated delivery.

### Security checklist

- **Authorisation on every operation** — every query and mutation checks the role and the tenant membership (company, store). Matrix of roles × operations against §2 of the specification; every "no" cell has a test.
- **Data isolation** — the isolation tests exist, pass, and cover every new list or detail view from the stage.
- **Input validation** — at the boundary (API, webhook, file upload): type, size, format, length. Errors do not reveal internal details.
- **Secrets** — no keys, tokens or passwords in the code, the documentation, the tests or the git history (`git log -p` by the usual patterns). Secrets live in `.env`/`.dev.vars` locally and in the host's secrets.
- **Sessions and cookies** — HttpOnly, Secure, SameSite; tokens hashed in the database; logout ends the session.
- **Login** — rate limiting of attempts and of code frequency; the same response for an existing and a non-existing email.
- **Webhooks** — the signature is verified before anything else; an invalid one is rejected and logged.
- **Files** — type and size are checked on the server; unique names; only those that must be public are.
- **Dependencies** — `pnpm audit` (or equivalent) with no critical or high vulnerabilities; versions are pinned.
- **Logs** — no personal data, no secrets, with enough context (which tenant, which operation).
- **What never leaves the server** — the list from `CLAUDE.md` (exact stock, internal notes, cost prices, other tenants' data) is not returned to clients. Check the response types, not only the code.

## 3. Record the findings

Every finding is a bug in `BUGS.md`, in the file's format: `Severity`, `Found during: End of stage N (stage-review)`, `Owned by: End of stage N`, steps, expected, actual. Severity:

- **Critical** — data leak, missing authorisation, wrong money, data loss.
- **Important** — a violated section of the specification, a missing test for a rule, a limit that will be exceeded at scale.
- **Minor** — style, duplication, texts.

Order them by severity. Nothing is fixed before the list is complete and recorded — otherwise the review turns into patching the first thing found.

Tell the client in three lines: how many findings, how many critical, which ones. The details are in the file (principle 9).

## 4. Fix them one by one

By severity, from critical down. For every bug:

1. Find the cause (principle 6), not the symptom.
2. Write the test that reproduces the bug, and watch it fail.
3. Fix. Watch the test pass. Run the whole test suite.
4. Mark the bug "Fixed", then "Verified", move it to "Closed".
5. One commit per bug: `B-NNN Short description` at the start of the message, including `BUGS.md`.

Minor findings are fixed last. If the client decides to defer a minor finding, it stays in "Open" with the note "deferred by client" and is not lost.

New work discovered during the fixes goes to `TASKS.md` → "New tasks" (principle 2); it is not done here.

## 5. Stage acceptance

1. Walk through the stage's acceptance criteria (Part III) one by one, as the client would check them — through the real entry point (UI, API), not through the tests. Record the result next to every criterion in the specification or in `TASKS.md`: `✓`, or a finding → `BUGS.md` and back to step 4.
2. Triage of "New tasks": each gets a number and a place in the phase by priority, or goes to Part II of the specification with a short description.
3. Demo for the client: a list of what can already be done with the product, in the words of the criteria, and what remains for the next stage.
4. Mark the "End of stage N" task `[x]` and commit it (principle 14).

The stage is accepted when all critical and important bugs are closed and every criterion is `✓`.

## 6. Process retro

The stage is the only moment when someone looks at the notes all at once. Between stages they only grow; here they are put in order. This is the big consolidation from `notes/README.md` — a separate commit `notes: consolidation after stage N`, so the diff is visible and can be reverted.

1. **Merge the inbox.** `notes/_inbox/` → `notes/` by the rules (new → file; same → `seen` + 1). Inbox files are deleted.
2. **Verify every note.** Is it still true? A `gotcha` is checked against the code or the documentation, a `howto` is run, `feedback` is compared with what the client has said since. Untrue → deleted with a line in the stage journal. Duplicates are merged, the counters are added up.
3. **Promote the mature ones.** `observation` with `seen ≥ 2` → proposal `P-NN` in `TASKS.md` → "Process proposals" with text, reason and evidence (principle 12). `skill` → fix the project skill; for a global one, propose (principle 13). A `gotcha` true for every project of this kind → propose it for `project-setup`. The proposals are shown to the client in the demo, in three lines, with "yes"/"no" for each; after "yes" the rule goes into `CLAUDE.md` or the skill, the note is deleted, and `P-NN` is marked `[x]` with where it went — the rule lives in one place, the trace of where it came from stays in `TASKS.md`.
4. **Clean up what has served its purpose.** A note that became a rule is deleted; the rule lives in one place (`CLAUDE.md`, the skill, or the README for a `howto`). `feedback` is deleted once a rule or principle encodes it. An `observation` with `seen: 1` and no new source for two consecutive stages is deleted at the retro, with one line in the stage journal. `gotcha` and `howto` are re-verified at every retro (against code, docs, or by running them) and deleted when false or when absorbed into the `CLAUDE.md` limits or the README. Inbox files are deleted on merge. `.claude/harvest-state/` is local and git-ignored; its log may be truncated at the retro.
5. **Check the harvest.** Did files arrive in `notes/_inbox/` throughout the stage (the log is `.claude/harvest-state/harvest.log`)? Nothing for a whole stage means the hooks are not running: `.claude/settings.json`, `python3`, the permissions of `harvest.sh`. The harvest returns summaries instead of notes, or misses the client's corrections → fix `.claude/hooks/harvest_prompt.md` — it is a project skill like any other (principle 13) and improves from the same observations.
6. **Budget.** A note up to ten lines, `notes/INDEX.md` up to 40 lines. Over budget means merging, not a new line.

## Common excuses

| Excuse | Reality |
|---|---|
| "I read the code while writing it" | Same author, same blind spots. The review is a separate pass from a separate context. |
| "I'll fix this right away, it's small" | First the whole list. Otherwise the first thing found gets fixed, not the most important. |
| "The specification says nothing about this input" | Silence is not permission for the input to break the program. What does the person get? |
| "The tests pass, so it's fine" | Tests prove what they test. The permissions matrix and the isolation are checked separately. |
| "The notes are fine, I'll look at them another time" | Another time is the next stage, with twice as many. An unreviewed note is noise in the index of every session. |
