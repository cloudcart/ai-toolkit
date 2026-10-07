# Environment check (Step 0, before the first question)

Run this once the folder has been looked at and before the interview starts. The interview is long and the limits research later needs documentation lookups, so the environment has to be right first. Report the result in two or three lines; fix what can be fixed without the user, ask for the rest, and don't block the interview on it.

## 1. Auto-compaction window — must be 500 000 tokens

Why: the interview and the file writing fill the context. Compaction at the wrong moment loses answers that aren't yet in the spec draft. A fixed, large window makes compaction predictable.

Key: `autoCompactWindow` (number, tokens, 100 000–1 000 000). Related: `autoCompactEnabled` (boolean, default true). Any settings file accepts it; precedence is `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`.

Check — read the three files and compute the effective value:

```bash
for f in .claude/settings.local.json .claude/settings.json ~/.claude/settings.json; do
  [ -f "$f" ] && echo "$f: $(python3 -c "import json,sys; d=json.load(open('$f')); print(d.get('autoCompactWindow','-'), d.get('autoCompactEnabled','-'))")"
done
```

Fix — write the project file `.claude/settings.json` from `assets/harvest/settings.json`, which carries this key together with the harvest hooks (section 5). Create it if missing, merge if it exists; never drop other keys:

```json
{
  "autoCompactWindow": 500000,
  "hooks": { "…": "from assets/harvest/settings.json" }
}
``` If `autoCompactEnabled` is `false` anywhere in the chain, say so — compaction off defeats the setting. If the user-level file holds a different value, mention it in one line so the user can align it; don't edit the user file from a project setup.

A changed value is guaranteed to apply from the next session; say that.

## 2. context7 MCP — must be available and working

Why: principle 0 (documentation over assumptions) and the limits research in Step 4 depend on it.

Check — `ToolSearch` with query `+context7`. Three possible states:

| State | Meaning | Action |
|---|---|---|
| Tools for resolving a library and fetching docs are listed | Working | Nothing |
| Only `authenticate` / `complete_authentication` are listed | The remote server (plugin or HTTP config) is installed but not authorised | Call the `authenticate` tool, give the user the URL, ask them to approve in the browser; if the callback page doesn't load, ask for the callback URL from the address bar and pass it to `complete_authentication`. Continue the interview meanwhile; remind once before Step 4. Still unauthorised at Step 4: don't ask again and don't block — research the limits in the official docs with WebFetch (principle 0 allows it), stamp each table "verified on <date> from the official documentation", and put the context7 login in "Before start" so the T-101 session has it. Don't add a second context7 server mid-session: a server added with `claude mcp add` is loaded only in the next session, so adding it now would look fixed and not be |
| Nothing | Not configured | Add it to the project (below) |

Add at project scope — stdio via npx, no account needed:

```bash
claude mcp add --scope project context7 -- npx -y @upstash/context7-mcp@latest
```

which writes `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

Remote alternative when the user has an API key: `type: "http"`, `url: "https://mcp.context7.com/mcp"`, header `CONTEXT7_API_KEY`. Project servers need the user's approval the first time in an interactive session; `claude mcp list` from the project folder shows what is configured. Say that the server appears after approval or a restart.

## 3. Tools and skills for the stack — propose, don't force

Once the project's platform and stack are known (Step 0 for an existing project, Step 4 for a new one), look for the CLIs, MCP servers and skills that fit them, following `references/technical-decisions.md`, section 5: the user's own skills first, then installed plugins, then the public registry, then documentation. Propose a short list with a reason each. Install only after an explicit yes.

## 4. Permissions — propose a narrow allowlist

Autonomous work stops at every permission prompt, and for a non-technical user the prompts are noise they can't judge. Propose — don't apply — a narrow allowlist for this project in `.claude/settings.json`, limited to the commands the work cycle runs:

```json
{
  "permissions": {
    "allow": [
      "Bash(pnpm test:*)", "Bash(pnpm lint:*)", "Bash(pnpm typecheck:*)", "Bash(pnpm build:*)",
      "Bash(pnpm dev:*)", "Bash(pnpm db:*)",
      "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
      "Bash(git add:*)", "Bash(git commit:*)", "Bash(git push:*)"
    ]
  }
}
```

Adjust the package manager and script names to the project. Apply only after the user's explicit yes. Never propose a blanket `Bash` — it removes the one gate between the agent and destructive commands. Model, effort and theme stay the user's; don't change them from a project setup. If a denied command blocks work later, it's recorded as an open question, not worked around.

## 5. Harvest hooks — the notes layer's safety net

Principle 17 makes the agent write notes itself at the end of a task. The hooks catch what it did not write before the context is compacted away. Three hooks in the project's `.claude/settings.json`, one script (`.claude/hooks/harvest.sh`), installed in Step 5 from `assets/harvest/`:

| Hook | When | What the script does |
|---|---|---|
| `Stop` | after every assistant turn | compares the transcript size on disk with the last harvested position; once it has grown by `HARVEST_SLICE_BYTES` (default 1.5 MB ≈ 30–40k tokens of filtered text), harvests the new slice in the background |
| `PreCompact` (auto and manual) | just before compaction | harvests whatever is left since the last slice (if more than `HARVEST_MIN_BYTES`, 20 kB) |
| `SessionStart`, matcher `compact` | right after compaction | prints the list of files waiting in `notes/_inbox/` — stdout of this hook enters the agent's context |

A harvest filters the transcript slice (`harvest_filter.py`: user text, agent text, tool names, truncated results; thinking and system reminders dropped; secret-looking strings redacted), prepends `harvest_prompt.md`, the notes index and the principle headings, and runs `claude -p` on Sonnet with tools disallowed. The output lands in `notes/_inbox/<date>-<session>-L<from>-L<to>.md`. Only the agent writes to `notes/` — at session start and at the end of every task it merges the inbox and deletes the files (project-manager steps 0.4 and 7.5).

**Why slices, not one pass at compaction.** The agent's own understanding at the end of a task is the richest source; the hooks are the net under it. Harvesting in slices means that by the time compaction fires, most of the session is already harvested and the last call is small. The transcript on disk is append-only — compaction appends a summary line and deletes nothing — so a harvest can run before, during or after compaction and sees the same lines. Verified on a session with 22 compactions.

**Ambiguities that were resolved, so nobody re-derives them:**

- *Recursion.* `claude -p` started from the project folder loads the project's hooks, so a harvest would trigger a harvest. The child runs with `--settings '{"disableAllHooks": true}'`, `--no-session-persistence` (no transcript of its own) and `HARVEST_CHILD=1`, which the script checks first.
- *Blocking.* `Stop` fires every turn, so the hook must return at once: it moves the position marker, takes a `mkdir` lock (macOS has no `flock`) and spawns the job in a new process session via `python3` (macOS has no `setsid`). One job per session at a time; a second `Stop` during a job exits.
- *Lost slices.* If the child fails (offline, rate limit), the marker is rolled back so the next harvest covers the same lines.
- *Tokens are unknowable from a hook.* The threshold is bytes of transcript growth, configurable through `HARVEST_SLICE_BYTES`; the filtered text is capped at 400 kB.
- *`SessionEnd` is useless here* — its budget is 1.5 seconds.
- *Two writers.* Hooks write only to `_inbox/`; the agent is the only writer of `notes/`. The harvester proposes `seen: +1`; the agent applies it.
- *What survives compaction.* `CLAUDE.md` and its `@notes/INDEX.md` import are in the system prompt and survive; what does not is the awareness of new inbox files — that is what the `SessionStart` hook re-injects.
- *Secrets and injection.* The filter redacts key-like strings, the prompt forbids values, the inbox is git-ignored, and a note from an external source (`origin: external`) never becomes a rule without a human.
- *Dependencies.* `bash` and `python3`. No Windows support for the bash hook — say so if the project will be driven from Windows.
- *Resume or fork.* A resumed or forked session may get a new transcript with copied history and be harvested again; the merge (`seen` + 1 on the same thing) absorbs duplicates.
- *Cost.* Three to six Sonnet calls per compaction cycle, 30–80k input tokens each, on the user's own subscription or key.

**Verify after installing.** Open the project in Claude Code once (it asks to approve the hooks from `.claude/settings.json` — the client must accept), work a few turns, then check `.claude/harvest-state/harvest.log`: every harvest logs a line. A whole stage without a line means the hooks are not running (`python3`, executable bit on `harvest.sh`, hooks approved). The harvester's prompt is a project file; if it returns summaries instead of notes or misses the client's corrections, stage-review step 6 fixes `harvest_prompt.md` like any project skill (principle 13).

## Report format

Two or three lines, for example:

> Environment: auto-compaction 500 000 (written to `.claude/settings.json`; the user-level setting is 600 000). context7: installed but needs a login — here is the link: … Continuing the interview; I will remind you before the limits research.
