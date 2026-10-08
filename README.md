# CloudCart AI Toolkit

Connect your AI tools to the CloudCart platform.

The Toolkit gives your agent access to the CloudCart Admin GraphQL API — semantic schema search, query validation, and store management through the CloudCart CLI's `app execute` command.

## Install

* **For Claude Code**: Run these two commands in a chat:

    ```
    /plugin marketplace add cloudcart/ai-toolkit
    /plugin install cloudcart-plugin@cloudcart-ai-toolkit
    ```

* **For Cursor**: Open the Command Palette (`CMD+SHIFT+P` / `CTRL+SHIFT+P`) and run **Cursor: Install Plugin From URL**. Then paste:

    ```
    https://github.com/cloudcart/ai-toolkit
    ```

* **For Gemini CLI**: Run this command in your terminal:

    ```
    gemini extensions install https://github.com/cloudcart/ai-toolkit
    ```

* **For VS Code**: Open the Command Palette (`CMD+SHIFT+P` / `CTRL+SHIFT+P`) and run **Chat: Install Plugin From Source**. Then paste:

    ```
    https://github.com/cloudcart/ai-toolkit
    ```

## Update

Claude Code does **not** update this plugin on its own. Auto-update is enabled by default only for Anthropic's own marketplaces; third-party ones like this stay on the version you installed until you act. [Turning on auto-update](#turn-on-auto-update) is a one-time fix.

To update once, by hand:

```
/plugin marketplace update cloudcart-ai-toolkit
/plugin update cloudcart-plugin@cloudcart-ai-toolkit
/reload-plugins
```

`/plugin marketplace update` refreshes the catalog, `/plugin update` installs the newer version, and `/reload-plugins` applies it to the session you're in — without it, the new version loads on your next launch. If the reload warns that it would invalidate the prompt cache, re-run it as `/reload-plugins --force`.

To check what you're on, run `/plugin list`, or compare against [CHANGELOG.md](CHANGELOG.md).

### Turn on auto-update

Worth doing once, so the above stops being manual:

1. Run `/plugin`
2. Press **Tab** until you reach the **Marketplaces** tab
3. Select **cloudcart-ai-toolkit** from the list
4. Choose **Enable auto-update**

From then on Claude Code refreshes the catalog and updates the plugin in the background shortly after each session starts — with a random delay of up to ten minutes, so the session you're in keeps the version it launched with. When something updates, you'll be prompted to run `/reload-plugins`, or the new version simply loads next time you start.

To turn it off again, follow the same path and choose **Disable auto-update**.

If you administer a team, you can enable it for everyone instead of asking each person to toggle it: set `"autoUpdate": true` on the marketplace's `extraKnownMarketplaces` entry in managed settings.

Auto-update covers this plugin only. `DISABLE_AUTOUPDATER=1` in your environment switches off all automatic updates, including plugins; pair it with `FORCE_AUTOUPDATE_PLUGINS=1` if you want to pin Claude Code itself but keep plugins current.

## What you get

- **Schema discovery**: Semantic search over CloudCart's Admin GraphQL schema, in any language
- **Query validation**: Validate GraphQL queries and mutations against the live schema before they run against your store
- **Store management**: Add products, manage inventory, view orders, customers, and more — through the CloudCart CLI's `app execute` capabilities
- **Platform knowledge**: Answer "how is this supposed to work / where do I set it / is this by design", grounded in the CloudCart platform wiki instead of guessed from memory
- **Project setup**: Interview-driven start of a new software project — a specification built block by block, then `CLAUDE.md`, `TASKS.md`, `BUGS.md`, two project-local skills and a notes layer that lets the agent learn from its own sessions. See [Project setup](#project-setup)
- **Auto-updates**: The CLI and Dev MCP track `@latest` and the platform wiki tracks its repository, so new capabilities and new documentation are picked up automatically. The plugin itself is the exception — see [Update](#update)

## The platform wiki

The `cloudcart-platform-expert` skill answers from a curated, ~2 500-page wiki of how the platform actually behaves — admin navigation, settings, business rules, plan gates, and storefront behaviour.

The wiki is not bundled with this plugin. It is cloned to `~/.cloudcart-ai-toolkit/wiki` from [`cloudcart/platform-wiki`](https://github.com/cloudcart/platform-wiki) — a public repository, so no account or token is needed.

- **In Claude Code**, a `SessionStart` hook refreshes it in the background. The hook forks and returns immediately, so it never delays session startup.
- **On every host**, the skill verifies the wiki is present before answering and fetches it if it isn't.

Updates are cheap: at most once every 24 hours the sync asks the remote for its current commit, and only clones when that commit has changed. A first install takes a few seconds; an up-to-date check takes well under one.

To manage it by hand:

```bash
scripts/sync-wiki.sh            # sync if missing, or if upstream moved since the last check
scripts/sync-wiki.sh --force    # re-clone now
```

| Environment variable       | Default                   | Purpose                        |
| -------------------------- | ------------------------- | ------------------------------ |
| `CLOUDCART_WIKI_HOME`      | `~/.cloudcart-ai-toolkit` | Where the wiki is stored       |
| `CLOUDCART_WIKI_TTL_HOURS` | `24`                      | How often to check for updates |
| `CLOUDCART_WIKI_REPO`      | `cloudcart/platform-wiki` | Source repository              |
| `CLOUDCART_SETUP_HINTS`    | `1`                       | `0` turns off the project-setup session-start hint |

## Project setup

The `project-setup` skill turns the first hour of a project into a repeatable procedure. Ask for it in plain words — "set up a new project", "нов проект", "направи спецификация", "разбий спецификацията на задачи" — or run `/cloudcart-plugin:project-setup`.

It interviews you in two levels. **Фундамент** first: the eight to twelve root decisions, stack included, each with a recommended answer. Then **Уточнения**, nine blocks from roles and entities to integrations and non-functional requirements: it writes each section of the specification first, asks only the questions that have more than one defensible answer, and lists what it decided by standard so you can veto a line by number. Facts are looked up, decisions are yours. Business questions you can't answer go to a „Въпроси към бизнеса“ list instead of blocking the interview.

What it leaves in the project:

| File | What it is |
| --- | --- |
| `specification.md` | What is being built: Part I (first version), Part II (later), Part III (stages, acceptance criteria, decisions by standard, remaining clarifications) |
| `CLAUDE.md` | How: stack, every architectural decision with its reason, the platform's hard limits as tables, the order of work, the working principles |
| `TASKS.md` | In what order: numbered tasks anchored to spec sections, ordered by priority, with open questions, process proposals and new tasks |
| `BUGS.md` | Bugs get written down instead of fixed in motion |
| `.claude/skills/project-manager`, `.claude/skills/stage-review` | A plan before every task; a code and security review at the end of every stage |
| `notes/` + `.claude/hooks/` | The agent's working memory and the hooks that feed it (below) |

The kit itself is English, and so is the agent's working memory (`notes/`). The documents meant for people — specification, `CLAUDE.md`, `TASKS.md`, `BUGS.md`, plans — are written in the project's language: the specification's if there is one, otherwise yours. The interview runs in whatever language you write in.

A short guide in Bulgarian for teams trying it out: [docs/project-setup.bg.md](docs/project-setup.bg.md).

You don't have to remember the skill exists. A `SessionStart` hook looks at the shape of the folder you open and, when the project isn't set up, gives the agent a few lines of context so it can offer the skill in one sentence: in an empty folder every time, in a folder with code but no `CLAUDE.md` once, and once when a `CLAUDE.md` exists without the rest of the kit — then it suggests the audit mode, which reads what you have and proposes what to add, item by item, overwriting nothing. It never starts the interview by itself and never touches your files. Turn it off with `CLOUDCART_SETUP_HINTS=0`.

### How the agent improves itself

Lessons die at context compaction unless something catches them. The kit closes that loop with files, not with a service:

1. **Notes** (`notes/`): what was learned but is not a rule — a fact that took effort, the user's words about a result, a recurring observation with a counter, a command outside the README, a gap in a skill. One small file per note, an index loaded into every session.
2. **Harvest hooks** (`.claude/hooks/harvest.sh`): a `Stop` hook harvests the session transcript in slices *before* compaction, `PreCompact` takes the remainder, and after compaction a `SessionStart` hook tells the agent what is waiting. Harvesting runs in the background on Sonnet; only the agent writes to `notes/`.
3. **The ladder**: an observation seen twice becomes a proposal in `TASKS.md`; your "да" turns it into a principle in `CLAUDE.md` or a fix in a skill, and the note is deleted. The agent never changes its own rules silently.
4. **Stage retro**: `stage-review` consolidates the notes at the end of every stage, in its own commit, and checks that the harvest is actually running.

Requirements for the hooks: `bash` and `python3` on the machine that runs Claude Code; macOS and Linux. Claude Code asks to approve the project's hooks the first time the project is opened. The harvester's prompt is a project file, so the agent can refine it like any other project skill.

## Other install methods

If your platform doesn't support plugins, install the CLI and Dev MCP directly:

```bash
# CLI
npm install -g @cloudcart/cli@latest      # or: brew tap cloudcart/tap && brew install cloudcart

# Dev MCP — register with your AI host as an MCP server using:
#   command: npx
#   args:    -y @cloudcart/dev-mcp@latest
```

## Contributing

Fixes to plugin manifests and skill content are welcome here. CLI bugs go to [`cloudcart/cli`](https://github.com/cloudcart/cli); Dev MCP bugs go to [`cloudcart/dev-mcp`](https://github.com/cloudcart/dev-mcp).
