# CloudCart AI Toolkit

Connect your AI assistant to your CloudCart store.

This toolkit gives Claude, Cursor, OpenAI Codex, Gemini, and VS Code Copilot one-command access to the CloudCart CLI and Dev MCP server — so your assistant can search the Admin GraphQL schema, validate queries before running them, and manage your store through natural language.

## Install

* **For Claude Code**: Run these two commands in a chat:

    ```
    /plugin marketplace add cloudcart/AI-Toolkit
    /plugin install cloudcart-plugin@cloudcart-ai-toolkit
    ```

* **For Cursor**: Open the Command Palette and run **Cursor: Install Plugin From URL**, then paste:

    ```
    https://github.com/cloudcart/AI-Toolkit
    ```

* **For Gemini CLI**: Run this command in your terminal:

    ```
    gemini extensions install https://github.com/cloudcart/AI-Toolkit
    ```

* **For OpenAI Codex**: In the Codex CLI, run `/plugins`, search for **CloudCart**, and select **Add to Codex**.

* **For VS Code**: Open the Command Palette (`CMD+SHIFT+P` / `CTRL+SHIFT+P`) and run **Chat: Install Plugin From Source**, then paste:

    ```
    https://github.com/cloudcart/AI-Toolkit
    ```

After installation, the CloudCart Dev MCP is registered automatically. The CloudCart CLI is installed on demand the first time you ask the assistant to set up or connect a store.

## What you get

- **CLI on demand** — the assistant installs `@cloudcart/cli` (binary `cloudcart`) the moment you ask to set up or connect a store. macOS gets Homebrew, everywhere else gets npm.
- **Dev MCP, auto-registered** — `@cloudcart/dev-mcp` is wired up via `.mcp.json`, exposing four tools: `learn_cloudcart_api`, `semantic_search`, `introspect_graphql_schema`, and `validate_graphql_codeblocks`.
- **Schema discovery in any language** — `semantic_search` accepts natural-language queries in English, Bulgarian, or anything else, and returns the right types, fields, and operations.
- **Validate before you execute** — every generated query is checked against the live CloudCart schema before it runs against your store, with built-in retry tracking.
- **Store management from chat** — once authenticated, the assistant routes "add a product", "show last week's orders", "give a 10% discount to first-time buyers" through the Admin GraphQL API.
- **Auto-updates** — both the CLI and MCP track `@latest`, so you get new capabilities without re-installing.

## Skills included

| Skill | Triggers when |
| --- | --- |
| `cloudcart-cli-install` | The CloudCart CLI is missing or out of date |
| `cloudcart-dev-mcp-install` | The Dev MCP isn't registered with the host |
| `cloudcart-onboarding-merchant` | A merchant wants to set up, connect, or manage their store |

## Other install methods

If your platform doesn't support plugins, you can install the CLI and MCP directly:

```bash
# CLI
npm install -g @cloudcart/cli@latest    # or: brew tap cloudcart/tap && brew install cloudcart

# Dev MCP (register as an MCP server in your host of choice)
# .e.g. claude_desktop_config.json:
# {
#   "mcpServers": {
#     "cloudcart-dev-mcp": {
#       "command": "npx",
#       "args": ["-y", "@cloudcart/dev-mcp@latest"]
#     }
#   }
# }
```

## Contributing

Issues and discussions are welcome. The CLI lives at [`cloudcart/cli`](https://github.com/cloudcart/cli) and the Dev MCP at [`cloudcart/dev-mcp`](https://github.com/cloudcart/dev-mcp); please file bugs against those repos when they relate to the underlying tools rather than the plugin manifests here.
