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

## What you get

- **Schema discovery**: Semantic search over CloudCart's Admin GraphQL schema, in any language
- **Query validation**: Validate GraphQL queries and mutations against the live schema before they run against your store
- **Store management**: Add products, manage inventory, view orders, customers, and more — through the CloudCart CLI's `app execute` capabilities
- **Auto-updates**: The CLI and Dev MCP track `@latest`, so new capabilities are picked up automatically

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
