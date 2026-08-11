---
name: cloudcart-dev-mcp-install
description: "Install or register the CloudCart Dev MCP server (@cloudcart/dev-mcp) with the current AI host. Use when the user wants to: install cloudcart dev mcp, set up cloudcart mcp, register cloudcart mcp, add cloudcart mcp to claude desktop, add cloudcart mcp to cursor, my cloudcart mcp is not loading, my cloudcart mcp tools are missing, fix cloudcart mcp, instalirai cloudcart mcp, dobavi cloudcart mcp, configure cloudcart mcp server."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
context: fork
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.1.0"
---

Make sure the CloudCart Dev MCP server (`@cloudcart/dev-mcp`, binary `cloudcart-dev-mcp`) is available and registered with the user's AI host.

**Core principle:** The MCP exposes four tools — `learn_cloudcart_api`, `semantic_search`, `introspect_graphql_schema`, `validate_graphql_codeblocks`. If those four are visible to you in the current session, the MCP is already wired up — confirm and stop. Otherwise, register it.

---

## Step 1 — Identify the host

Determine the host AI tool from system context:

- Claude Code (this plugin's primary target)
- Cursor
- Claude Desktop
- OpenAI Codex
- Gemini CLI
- VS Code (Copilot)
- Generic / unknown MCP client

If you can't tell, ask: "Which AI tool are you running this in?"

---

## Step 2 — Check whether the MCP is already available

If the four CloudCart MCP tools (`learn_cloudcart_api`, `semantic_search`, `introspect_graphql_schema`, `validate_graphql_codeblocks`) are already in your tool list, the MCP is registered. Confirm with the user:

"CloudCart Dev MCP is already loaded — you have schema search and GraphQL validation."

Then jump to **Step 5 — Reminder**.

If they aren't visible, continue.

---

## Step 3 — Smoke-test the binary

State what you're about to do, then run:

```
npx -y @cloudcart/dev-mcp@latest --help
```

A clean exit means the package downloads and runs. If this fails with a Node/npm error, install the CLI prerequisites first by handing off to `cloudcart-cli-install` (which covers Node 20+ guidance), then come back here.

---

## Step 4 — Register with the host

### Claude Code (this plugin active)

If this skill was invoked from Claude Code with the CloudCart plugin installed, the MCP is registered automatically via the plugin's `.mcp.json`. Tell the user to run `/mcp` in Claude Code and confirm `cloudcart-dev-mcp` is listed. If it isn't, ask them to re-install the plugin:

```
/plugin install cloudcart-plugin@cloudcart-ai-toolkit
```

### Claude Desktop

Edit `claude_desktop_config.json` (locations: macOS `~/Library/Application Support/Claude/claude_desktop_config.json`, Windows `%APPDATA%\Claude\claude_desktop_config.json`) and merge:

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

Then restart Claude Desktop.

### Cursor (without the plugin marketplace)

Open Cursor settings → MCP → add a new server:

- Name: `cloudcart-dev-mcp`
- Command: `npx`
- Args: `-y @cloudcart/dev-mcp@latest`

Or merge into the user's MCP settings JSON the same snippet shown for Claude Desktop.

### OpenAI Codex / Gemini CLI / VS Code

If the host's plugin marketplace already lists CloudCart, prefer that. Otherwise, use the host's MCP-server registration UI/file with the same `npx -y @cloudcart/dev-mcp@latest` command.

### Generic MCP client

Same command. Stdin/stdout JSON-RPC. Server name reports as `cloudcart-dev-mcp`.

---

## Step 5 — Reminder

Tell the user:

"The Dev MCP only handles **discovery** (semantic search, schema introspection) and **validation**. Reading and writing actual store data still goes through `cloudcart app execute`, which needs CLI auth. If you haven't logged in yet, just say 'set up my CloudCart store' and I'll handle it."

---

## Operational rule for the AI (not visible to the user)

The MCP tools share a session via `conversationId`:

1. The **first** CloudCart MCP call in any session must be `learn_cloudcart_api` (`api: "admin"`, `model: <your model name>`).
2. Save the returned `conversationId`.
3. Pass that same `conversationId` to every subsequent `semantic_search`, `introspect_graphql_schema`, and `validate_graphql_codeblocks` call for the rest of the session.

This is enforced by the server — calls without a valid `conversationId` will fail.

---

## Behavioral rules

- Never invent registration steps. Use only the snippets in this file.
- If a registration UI in the host doesn't match the layout described here, describe the matching JSON snippet and let the user paste it.
- If the MCP responds but auth-dependent flows fail later, the gap is on the CLI side — point at `cloudcart-cli-install` / `cloudcart-product-management`.
- After successful registration, confirm in one sentence and offer the hand-off to `cloudcart-product-management` (catalog work) or `cloudcart-platform-expert` (how the platform works).
