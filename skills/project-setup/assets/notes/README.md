# Notes — the project's working memory

This is where the things learned along the way live while they are not yet a rule, not a task and not a bug: facts that took effort to learn; the user's words about a result; observations that may become a principle; commands and paths outside the README; gaps in the skills. The specification says what, CLAUDE.md says how, TASKS.md says when. The notes say what we learned on the way.

## What is not a note

- Work to be done → `TASKS.md` ("New tasks"). Broken behaviour → `BUGS.md`. A rule about how to work → `CLAUDE.md` through principle 12. A scope decision → the specification.
- Knowledge about the user that holds in every project (how they like to be talked to, what they dislike) → Claude Code's user memory, not here. Notes are about the project.
- The value of a key, token, password, or customers' personal data → nowhere (principle 15).

## Rule number one

**A note never contains a rule.** If something is a rule about how to work, it goes to `CLAUDE.md` through principle 12: proposal, "yes", record. If it also lands here, there are two places with rules and they drift apart. A note holds facts, words, and observations with evidence.

## Types

| Type | What it is | Example |
|---|---|---|
| `gotcha` | A fact about a platform, a library or the code that took effort to learn, with the date and how it was verified | "X's webhook arrives twice in test mode; verified 2026-10-07" |
| `feedback` | What the user said about a result, verbatim, with the why and how it applies | "I don't want long emails" → customer emails are at most 5 lines |
| `observation` | A candidate for a rule: a counter and evidence | "Deviation from the plan because of the parameter limit — seen 2 times: T-114, T-131" |
| `howto` | A command or path that is not in the README | "The local database is reset with `pnpm db:reset`" |
| `skill` | A gap, an error or a missing step in a skill — project-local or global | "project-manager doesn't say to check the migration before committing" |

## Format

One file per note: `notes/<type>/<short-name>.md`.

```md
---
type: gotcha | feedback | observation | howto | skill
created: 2026-10-07
updated: 2026-10-07
seen: 1
origin: user | agent | external
sources: [T-114, "session b353ebc6 line 480"]
---

The note itself: at most ten lines. A fact, words or an observation, not a rule.
```

- `seen` grows with every new sighting of the same thing. At 2 or 3 the note becomes a proposal (see the ladder).
- `origin: external` means it comes from a web page, documentation or another unverified source. Such a note never becomes a rule without a human reviewing it. This is the guard against unverified text turning into trusted memory.
- `sources` points to a task, a bug or a transcript line, so every claim can be checked.
- Never the value of a key, token or password. Only the fact that one exists and where it lives.

## The index

`notes/INDEX.md` is the map: one line per note, with the path in backticks so it opens directly:

```md
- [gotcha] `notes/gotcha/webhook-twice.md` — the webhook arrives twice in test mode (seen 2)
```

It is loaded into every session through the `@notes/INDEX.md` line in `CLAUDE.md`, so it has a budget: at most 40 lines. Over budget means consolidation, not a new line. The path is in backticks on purpose: Claude Code follows `@paths` up to four levels deep, and without the backticks it would pull every note into every session. An `@` never appears in the index.

## Inbox

`notes/_inbox/` is where the hooks leave what they harvested from the transcripts (`YYYYMMDD-HHMM-<session>.md`). Nobody else writes there. The agent merges them into the notes at session start and at the end of every task: new → new file; the same → `seen` + 1 and a new source; then the inbox file is deleted.

## The ladder

```
chat → _inbox → note → (seen ≥ 2) → proposal → "yes" → CLAUDE.md or a skill → the note is deleted
```

Up: an `observation` with `seen ≥ 2` becomes a proposal `P-NN` in `TASKS.md` → "Open questions" → "Process proposals" (principle 12); after "yes", `P-NN` is checked off with `[x]` and where the rule went; a `skill` note is fixed directly in the project skill and said in the reply, for a global skill it is proposed (principle 13); a `gotcha` that holds for every project is proposed for `project-setup`.

Down: a note that became a rule is deleted — the rule lives in one place. A note not confirmed at consolidation is deleted with one line in the stage journal.

## Hygiene

- **Small consolidation** at the end of every task: merge the inbox, raise the counters.
- **Big consolidation** at the end of the stage (stage-review, "Process retro"): merge duplicates, check that every note is still true, promote the mature ones, delete those that became rules and those not confirmed. Done as its own commit, so the diff is visible and can be reverted.
- A note that became a rule is deleted; the rule lives in one place (CLAUDE.md, the skill, or the README for a howto).
- `feedback` is deleted once a rule or principle encodes it.
- An `observation` with `seen: 1` and no new source for two consecutive stages is deleted at the retro, with one line in the stage journal.
- `gotcha` and `howto` are re-verified at every retro (against the code, the docs, or by running them) and deleted when false or when absorbed into the CLAUDE.md limits or the README.
- Inbox files are deleted on merge. `.claude/harvest-state/` is local and git-ignored; its log may be truncated at the retro.
- A note is at most ten lines. The index is at most 40 lines. Over budget means merge, not a new line.
