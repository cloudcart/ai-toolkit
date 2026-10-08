---
name: project-manager
description: "Plans every task before execution. Use when a task from TASKS.md is started (\"start T-123\", \"next task\"), when a plan is requested (\"make a plan for…\"), and for any new work on the project even if the user doesn't say \"plan\" — a rule from CLAUDE.md, principle 10. Reads the task, the specification, CLAUDE.md and BUGS.md, writes a plan in plans/T-NNN.md, asks the questions whose answers change the plan, and only then executes — step by step, checking off the plan, with no silent deviations."
---

# Project manager — plan before execution

The plan is the bridge between the specification and the code. A task started without a plan grows, skips rules from the specification, and leaves behind decisions nobody took consciously. The plan makes them explicit before the first line of code, and during the work it is the memory that survives context compaction.

The model is borrowed from the writing-plans / executing-plans pair (obra/superpowers) and from grilling (mattpocock/skills): the plan is written from the specification, questions are asked in rounds with a recommended answer, execution follows the plan and records every deviation.

**Language.** Talk to the user in the language they write in. Plans, journals and everything in `TASKS.md`, `BUGS.md` and `CLAUDE.md` follow the project's language (the one `CLAUDE.md` is written in). Notes in `notes/` are always English. The phrases quoted in this skill are examples, not strings to repeat.

## When

- The user starts a task from `TASKS.md`: "start T-123", "next task", "continue".
- The user asks for new work that is not in `TASKS.md` — one request or several in one message. Intake first, per principle 18: check each against the tasks, "New tasks", "Open questions" and the open bugs; record the clear ones at once (a duplicate is a note on the existing item); for the ones where you can name two readings that lead to different work, ask in one round — each with the recommended reading, never more than five, and most messages need none — and record them after the answer, never on a guess. If you can't name the second reading, there is nothing to ask: record the obvious one. The reply says what was recorded and where. The client decides when: "do it now" → it gets a number in its phase and becomes the next task; otherwise it goes to "New tasks" until the triage at the end of the current task.
- The user asks for a plan: "make a plan for…".

No code is written without a plan. Exception: a bug that blocks the current task — it is recorded in `BUGS.md` and fixed at once, but it too becomes a line in the journal of the current plan.

## 0. Session start

Before taking a task, find out where the project is — the context doesn't remember, the files do:

1. `plans/` — is there a plan with unchecked steps? That is the current task. Continue from the first unchecked step and read its journal for decisions taken before the compaction. Finished steps are not done twice.
2. `git status` — uncommitted changes? They belong to that plan. If there is no unfinished plan, tell the client before touching anything.
3. No unfinished plan → the next task is the first unchecked one in `TASKS.md`.
4. `notes/_inbox/` — are there harvested files from the hooks? Merge them into `notes/` by the rules in `notes/README.md`: new → new file; same as an existing note → `seen` + 1 and the new source; `observation` with `seen ≥ 2` → proposal `P-NN` in `TASKS.md` → "Process proposals" (principle 12); `skill` → fix the project skill and say so (principle 13). Update `notes/INDEX.md` (the line carries the path in backticks; the comment at the top stays), delete the inbox file. When the client says "yes" to a `P-NN`: the rule goes into `CLAUDE.md`, the note is deleted, and `P-NN` is marked `[x]` with where it went — not deleted. The merge is short — five minutes, not a revision of all notes; that is the job of `stage-review`.

## 1. Gather

Read, don't recall:

1. The task's line from `TASKS.md` — the full text and the `§X` references.
2. The specification sections the task points to — in full, including sub-sections. The specification is the only source for scope; the plan is its argument.
3. From `CLAUDE.md` — the architectural decisions, limits and principles that affect the task.
4. From `BUGS.md` — the open bugs related to the task. They are fixed after it (work cycle, step 3) and must be in the plan.
5. From `TASKS.md` → "Open questions" — is there an unresolved question about the task's sections? Product (what the software should do) → the task is blocked: ask the client and stop if there is no answer. Technical (how to build it) → decide it yourself, record it in the journal as a decision and continue.
6. The code in the affected area and the plans of the tasks this one depends on (`plans/T-NNN.md`) — the names and interfaces you will use are there.

Facts are found, not asked: documentation through context7, limits from `CLAUDE.md`, existing names from the code.

## 2. Write the plan

File: `plans/T-NNN.md` (the folder is created with the first plan). No placeholders — "TODO", "add validation", "handle the edge cases", "like T-104" are failures of the plan. Every step says what, where, and how it is verified.

```md
# Plan — T-NNN Short name

**Task:** <the line from TASKS.md verbatim>
**Specification:** §X — <the rule in one sentence>; §Y — <…>
**Constraints from CLAUDE.md:** <limit / principle / architectural decision, one line each>
**Related bugs:** B-NNN <short> | none
**Depends on:** T-NNN <what it uses from it: names, interfaces> | nothing
**Security:** <which operations check role and tenant; what input is validated; which secrets are used and from where; what is not returned to the client> | not affected

## Questions before execution

None — everything is in the specification.
<or>
- [ ] **#1 — <title>:** <question> ➡️ <recommended answer and why>

## Steps

- [ ] 1. <action> — files: `…` — check: `<command>` — expected: <result>
- [ ] 2. …

## Tests — twice

- First time: <exactly what is verified, with what data, including the edge cases from the specification>
- Second time: <the same after a clean start / with other data / through the other entry point (API and UI)>

## Outside the task — recorded, not done

- → `TASKS.md` "New tasks": <…>
- → `BUGS.md`: <…>
- → `TASKS.md` "Open questions": <…>

## Journal

<empty until execution>
```

Steps are in execution order; one step is one action with one check. Steps that change data or schema also say how they are rolled back. Tests cover the rules from the specification, not only the happy path — if §X says "up to 5 attempts", the test makes the sixth.

## 3. Ask the questions

Only questions whose answers change the plan. If the specification answers — don't ask. If the code or the documentation answers — check, don't ask.

Ask them the grilling way: the whole frontier in one round — every question whose prerequisites are decided — numbered, each with a recommended answer phrased so that "yes" accepts the recommendation. A question whose answer depends on another open question waits for the next round. Facts are your job (code, documentation, context7); decisions are the user's. Rounds until the frontier is empty.

```
❓ **#1 — <title>**: <question>

➡️ <recommendation and why>

---
```

When `AskUserQuestion` is available and there are up to four questions with clear options — it can go through that too, the recommendation first, marked "(Recommended)".

Decisions are the user's. If they are not available and the question is a product decision: record it in `TASKS.md` → "Open questions" with the proposal. If it blocks the task — stop and say so. If it doesn't block — continue with the proposal and record it in the journal as a decision.

## 4. Check the plan against the specification

Before showing it:

- **Coverage** — every rule from the referenced sections has a step or a test. A rule without a step is a gap; a step without a rule is out of scope (principle 4).
- **Consistency** — names and interfaces match the plans of the tasks this one depends on, and the code.
- **Scope** — nothing beyond the line from `TASKS.md`. Everything else is in "Outside the task".
- **No placeholders** — search for "TODO", "later", "similar to".

## 5. Show and start

Show the plan briefly: five to ten lines and the path to the file. Then:

- There are open questions → wait for the answers, update the plan, show what changed again.
- None → start executing. The user can stop at any time. If `CLAUDE.md` says plans are approved explicitly, wait for "yes".

## 6. Execute the plan

The plan has already done the thinking. Execute it exactly, in step order, and prove every step with its check — read the result and compare it with the expected.

- **Check off** the step in `plans/T-NNN.md` as soon as it is done, in the same action that finishes it. The plan is the memory: after context compaction trust the file and `git log`, not the recollection. A finished step is not done twice.
- **Deviation = recorded decision.** When the plan turns out wrong (contradicts the specification, the interface from a previous task is different, a step cannot work): choose the smallest change that satisfies the specification, record it in the journal as `Decision: <what> — <why> — <cost if wrong>` and continue. A deviation without a journal line is a decision taken in secret.
- **Nothing outside the plan.** New needed work → `TASKS.md` "New tasks"; bug → `BUGS.md`; question → "Open questions" (principles 2 and 9). Not done in motion.
- **Code wrong, not plan** — find the cause (principle 6), don't adjust the result.
- **Stop only for**: an irreversible or destructive action; an action involving security (keys, permissions); a side effect outside the working folder (push to a shared branch, publishing, sending real emails); a plan so broken that every next step is a guess. For those — stop and ask.

## 7. Finish

1. Run the two tests from the plan, read the results. A failing test — the task is not done and is not committed.
2. Mark `[x]` in `TASKS.md`. Move the fixed bugs to "Closed" in `BUGS.md`.
3. Add to the journal `Result: <what was done> — tested 2 times — <decisions taken during the work, if any>`.
4. Triage of "New tasks": every task recorded during this one gets a number in its phase and a place by priority (dependencies → stage → core before auxiliary), or goes to Part II of the specification with a short description. A bug without a related task is owned by the next task in the area or by `stage-review` at the end of the stage — record which in the bug itself.
5. Look at the journal for lessons and record them as notes in `notes/` (principle 17): a fact learned the hard way → `gotcha`; the client's words about the result → `feedback` verbatim; a deviation from the plan or a question that repeats → `observation` with the evidence; a command outside the README → `howto`. A note, not a rule — the rule goes up the ladder: `observation` with `seen ≥ 2` → proposal `P-NN` in "Process proposals" (principle 12); a step or check this skill missed → update the skill and say so (principle 13). Then merge `notes/_inbox/`, as in step 0.4. Hygiene: a note up to ten lines, the index up to 40 lines.
6. Commit — one for the task, with its number at the start of the message, including the code, `TASKS.md`, `BUGS.md`, `plans/T-NNN.md` and the changes in `notes/`. Then push to the branch from `CLAUDE.md` (principle 14).
7. Reply briefly: what was done, which files changed, what was recorded and where. The details are in the plan and in the files (principle 9).

If the task is "End of stage N" — its plan is to run the `stage-review` skill; it takes over the review, the bugs and the acceptance criteria.

## Common excuses

| Excuse | Reality |
|---|---|
| "The task is small, no plan needed" | A small plan is five lines. A small task without a plan is the one that grows. |
| "I remember what the specification says" | You remember a summary. The exact numbers and rules are in the section. Read it. |
| "I'll check off the steps at the end" | Compaction doesn't wait. One step — one check-off, immediately. |
| "The plan is wrong here, I'll just do the right thing" | Do it and record it as a decision. Otherwise it is a decision taken in secret. |
| "While I'm here, I'll fix this too" | You record it. The current task is the current task. |
| "The test should pass" | "Should" is not proof. Run it and read the result. |
| "I know this, no note needed" | You know it until the compaction. The note is for the next session, which starts from zero. |
| "I'll add it straight as a principle, it's obvious" | Obvious once is an observation. It becomes a principle after a second sighting and a "yes" (principle 12). |
| "I'll ask, just to be safe" | Safe is naming the second reading. If you can't, record the obvious one and move on; a question without a fork is noise. |
| "The user wrote three requests, I'll ask three questions" | Requests are recorded, not interrogated. One round, only for real forks; most messages need none. |
