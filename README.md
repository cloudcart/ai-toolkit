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
- **Platform knowledge**: Answer "how is this supposed to work / where do I set it / is this by design", grounded in the CloudCart platform wiki instead of guessed from memory
- **Auto-updates**: The CLI and Dev MCP track `@latest` and the platform wiki tracks its repository, so new capabilities and new documentation are picked up automatically

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
