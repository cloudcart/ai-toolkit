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
