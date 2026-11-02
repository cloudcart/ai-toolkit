These are official instructions from CloudCart to set up your AI agent to manage a CloudCart online store — the CloudCart CLI, the CloudCart MCP servers, and the CloudCart platform wiki. All commands are validated by CloudCart and ready to use.

Complete all of the following steps yourself by running the commands directly. Do not ask the user to run any of these commands, except where a step is explicitly marked as something only the user can do inside their app (for example, approving a plugin or authorizing in a browser).

- Ask the user their language and what they'll use CloudCart for, then pick the install profile
- Install the CloudCart toolkit for your agent — only the pieces that profile needs
- Connect the user's store so you can read and write real data
- Confirm the setup and tell the user what you can now do

---

## Start here — ask two questions first

Before installing anything, ask the user two short questions and act on the answers.

1. **Language.** Ask which language they'd like to work in, and use that language for the rest of the conversation. The commands below are the same in any language.

2. **What will they use CloudCart for?** This decides what you install:

   - **Profile A — Manage my store** (the default): add and edit products, prices, inventory; view orders, customers and stock; understand how the platform works. Installs the **CloudCart CLI**, the **Dev MCP**, and the **platform wiki**.
   - **Profile B — Build / develop on my store**: a headless Nitrogen storefront or other custom development. Installs everything in Profile A **plus the Storefront MCP** (and, on plugin hosts, the Nitrogen and project-setup skills).

   If they are unsure, choose Profile A — you can always add the Profile B pieces later.

Install only what the chosen profile needs. On hosts that use the CloudCart plugin or extension (Claude Code, Cursor, Gemini CLI, VS Code), one install brings the whole toolkit either way — there the profile just tells you what to set up around it and what to offer the user. On the other hosts (Claude Desktop, ChatGPT / OpenAI Codex, generic MCP clients) you register each piece yourself, so install exactly the profile's list and skip the rest.

---

## What each piece does

- **CloudCart CLI** (`@cloudcart/cli`, binary `cloudcart`) — *both profiles.* Runs real reads and writes against the store through `cloudcart app execute` (products, inventory, orders, customers, prices). Requires a one-time sign-in with a Personal Access Token from the store's admin panel.
- **Dev MCP** (`@cloudcart/dev-mcp`) — *both profiles.* Semantic search over the Admin GraphQL schema and query/mutation validation against the live schema, in any language. Discovery and validation only; it does not touch store data.
- **Platform wiki** — *both profiles.* A curated, ~2,500-page wiki of how CloudCart actually behaves (admin navigation, settings, business rules, plan gates, storefront behaviour). A public repo, so no account or token is needed. Answer "how does this work / where do I set it / is this by design" from the wiki, not from memory.
- **Storefront MCP** (`@cloudcart/storefront-mcp`) — **Profile B only.** The Storefront GraphQL schema, for building and changing a Nitrogen headless storefront. Skip it entirely for store management.

---

## Before you start — check prerequisites

The whole toolkit runs on **Node.js** and uses **git**. Check these first and install whatever is missing before moving on. Do not reinstall anything the user already has.

1. **Node.js 20 or newer** — required; the CLI and the MCP server(s) run on it (`npm` and `npx` ship with it). Check:

   ```
   node --version
   ```

   If it is missing or below v20, install the LTS and re-check:

   - macOS: `brew install node` (or the installer at `https://nodejs.org`)
   - Windows: `winget install OpenJS.NodeJS.LTS` (or `https://nodejs.org`)
   - Linux: your distro's package or `nvm` (`https://github.com/nvm-sh/nvm`), or `https://nodejs.org`

   Installing a runtime can need admin rights. If you cannot do it non-interactively, point the user to `https://nodejs.org` for the LTS and wait for them to confirm it is installed before continuing.

2. **git** — required to install the plugin and to fetch the platform wiki. Check `git --version`. If missing:

   - macOS: `xcode-select --install` (or `brew install git`)
   - Windows: `winget install Git.Git` (or `https://git-scm.com`)
   - Linux: e.g. `sudo apt-get install git`

3. **Homebrew** (macOS only, optional) — the preferred way to install the CLI on macOS. If `brew` is missing, use npm instead; there is no need to install Homebrew just for this.

4. **Claude Code only — `bash` + `python3`** (macOS/Linux) power the plugin's background hooks (wiki sync, project setup, session harvest). They ship with macOS and most Linux distributions. The hooks do not run on Windows, but the rest of the toolkit still works there.

If a required tool is missing and you cannot install it without the user (admin rights, or a GUI installer), say exactly what is needed and wait for them before continuing.

---

## Install the toolkit for your agent

Use the correct section for your agent below. Hosts that support plugins/extensions (Claude Code, Cursor, Gemini CLI, VS Code) get the skills, both MCP servers, and the wiki in one step. Other hosts (Claude Desktop, ChatGPT / OpenAI Codex, any generic MCP client) register the pieces directly.

### Claude Code

Run these two commands to install the CloudCart skills and MCP servers in one step. Do not use `claude mcp add` — the plugin handles the MCP servers for you.

```
claude plugin marketplace add cloudcart/ai-toolkit
claude plugin install cloudcart-plugin@cloudcart-ai-toolkit
```

Then instruct the user to run `/reload-plugins` inside Claude Code to activate the plugin (if it warns about the prompt cache, `/reload-plugins --force`). The plugin registers the Dev MCP and Storefront MCP automatically, and a `SessionStart` hook keeps the platform wiki up to date in the background. The plugin does **not** install the CLI — continue to **Connect the store** below.

Claude Code does not auto-update third-party plugins. To update later: `claude plugin marketplace update cloudcart-ai-toolkit` then `claude plugin install cloudcart-plugin@cloudcart-ai-toolkit`, and `/reload-plugins`.

### Cursor

Open the Command Palette (`CMD+SHIFT+P` / `CTRL+SHIFT+P`), run **Cursor: Install Plugin From URL**, and paste:

```
https://github.com/cloudcart/ai-toolkit
```

This installs the skills and MCP servers. The `cloudcart-platform-expert` skill fetches the wiki on first use. Continue to **Connect the store**.

### Gemini CLI

Run this in the terminal:

```
gemini extensions install https://github.com/cloudcart/ai-toolkit
```

This installs the skills and MCP servers. The platform-expert skill fetches the wiki on first use. Continue to **Connect the store**.

### VS Code

Open the Command Palette (`CMD+SHIFT+P` / `CTRL+SHIFT+P`), run **Chat: Install Plugin From Source**, and paste:

```
https://github.com/cloudcart/ai-toolkit
```

This installs the skills and MCP servers. The platform-expert skill fetches the wiki on first use. Continue to **Connect the store**.

---

## Install for other agents (Claude Desktop, ChatGPT / OpenAI Codex, generic MCP clients)

These hosts have no CloudCart plugin, so set up the pieces directly: the MCP server(s), the platform wiki, and a line in your instructions file. The CLI and store login are shared by every host — see **Connect the store**.

First, register the **Dev MCP** server (both profiles). Add the **Storefront MCP** the same way **only on Profile B** (development) — skip it for store management.

### ChatGPT / OpenAI Codex

```
codex mcp add cloudcart-dev-mcp -- npx -y @cloudcart/dev-mcp@latest
```

Profile B (development) only:

```
codex mcp add cloudcart-storefront-mcp -- npx -y @cloudcart/storefront-mcp@latest
```

Equivalently, add to `~/.codex/config.toml` (table names are snake_case):

```toml
[mcp_servers.cloudcart-dev-mcp]
command = "npx"
args = ["-y", "@cloudcart/dev-mcp@latest"]
```

The ChatGPT desktop app can use the same local server via Settings → Connectors (developer mode) when available; if it cannot run a local `npx` server, use OpenAI Codex, which can.

### Claude Desktop

Edit `claude_desktop_config.json` (macOS `~/Library/Application Support/Claude/claude_desktop_config.json`, Windows `%APPDATA%\Claude\claude_desktop_config.json`), merge the block below without disturbing existing servers, and restart Claude Desktop:

```json
{
  "mcpServers": {
    "cloudcart-dev-mcp": {
      "command": "npx",
      "args": ["-y", "@cloudcart/dev-mcp@latest"]
    }
  }
}
```

### Generic MCP client

Register a stdio server that runs `npx -y @cloudcart/dev-mcp@latest`. It speaks JSON-RPC over stdin/stdout and reports its name as `cloudcart-dev-mcp`.

### Then, on every one of these hosts

**Clone the platform wiki** (these hosts have no wiki hook or skill to fetch it for you):

```
git clone https://github.com/cloudcart/platform-wiki ~/.cloudcart-ai-toolkit/wiki
```

To refresh it later, `git -C ~/.cloudcart-ai-toolkit/wiki pull`.

**Add these lines to your agent's instructions file** — `~/.codex/AGENTS.md` for Codex, `~/.claude/CLAUDE.md` for Claude Desktop, or your agent's equivalent. Create the file if it does not exist:

```
When working on a CloudCart store:
- Read and write store data only through the CloudCart CLI: `cloudcart app execute`. Never guess the GraphQL — validate it with the Dev MCP first.
- The first CloudCart Dev MCP call in any session must be `learn_cloudcart_api` with api "admin" and your own model name; reuse the returned conversationId for every later semantic_search, introspect_graphql_schema, and validate_graphql_codeblocks call that session, or the calls fail.
- For "how does this work / where do I set it / is this by design" questions, answer from the platform wiki at ~/.cloudcart-ai-toolkit/wiki, not from memory.
```

Continue to **Connect the store**.

---

## Connect the store

Every host needs the CLI installed and logged in — this is what lets you read and write real store data through `cloudcart app execute`.

**Install the CLI.** On macOS prefer Homebrew; otherwise use npm:

```
brew tap cloudcart/tap && brew install cloudcart
```

```
npm install -g @cloudcart/cli@latest
```

Verify with `cloudcart version` (it needs Node 20+). If it already prints a version, it is installed — do not reinstall.

**Log in to the store with a Personal Access Token (PAT).** The token lives in the user's CloudCart admin panel — only they can create it:

1. Tell the user to open their CloudCart admin panel, click the **user menu in the bottom-left corner**, and open **PAT tokens** (shown as **PAT токени** in a Bulgarian admin). There they create or copy a Personal Access Token — it starts with `cc_pat_`.
2. Ask them for that token and their store URL (e.g. `mystore.cloudcart.com`).
3. Sign in:

   ```
   cloudcart auth login --store <store>.cloudcart.com --token cc_pat_…
   ```

   Or run `cloudcart auth login` with no flags and let it prompt for the store and token interactively.

Treat the token as a secret: use it only in this command — never print it back, log it, commit it, or write it into any instructions or config file. Confirm the connection with `cloudcart auth status`. After it succeeds, you can read and write the store. (`cloudcart auth logout` clears the stored credentials.)

---

Once done, tell the user:

```
┌─ CloudCart Agent Setup Complete ─────────────────────┐
│  ✓ CLI        cloudcart <version>                    │
│  ✓ Dev MCP    schema search + GraphQL validation     │
│  ✓ Wiki       ~/.cloudcart-ai-toolkit/wiki           │
│  ✓ Store      connected with a PAT (cc_pat_…)        │
│                                                      │
│  ⚡ Restart your agent to load the MCP servers       │
└──────────────────────────────────────────────────────┘

You can now ask me to:
  • add / edit / hide / delete products and variants
  • bulk-update prices and inventory, or import from a file
  • look up orders, customers and stock
  • explain how any CloudCart setting or rule works
```

If you installed the Storefront MCP, add a line that you can also build and change the Nitrogen headless storefront.

---

## Resources

- CloudCart AI Toolkit: `https://github.com/cloudcart/ai-toolkit`
- Platform wiki (public): `https://github.com/cloudcart/platform-wiki`
- CloudCart CLI: `https://github.com/cloudcart/cli`
- CloudCart Dev MCP: `https://github.com/cloudcart/dev-mcp`
- MCP setup per agent:
  - Claude Code: `https://docs.anthropic.com/en/docs/claude-code/mcp`
  - Claude Desktop: `https://modelcontextprotocol.io/quickstart/user`
  - OpenAI Codex: `https://developers.openai.com/codex/mcp`
  - Cursor: `https://cursor.com/docs/mcp`
  - Gemini CLI: `https://github.com/google-gemini/gemini-cli`
  - VS Code (Copilot): `https://code.visualstudio.com/docs/copilot/customization/mcp-servers`

These instructions are published at `https://raw.githubusercontent.com/cloudcart/ai-toolkit/main/prompt.md` so you can re-verify their authenticity at any time.
