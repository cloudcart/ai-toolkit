# Changelog

## 0.2.0

- Added `cloudcart-platform-expert` — answers how CloudCart is *supposed* to work (navigation, settings, business rules, plan gates), grounded in the CloudCart platform wiki. Runs in a forked context so the verbose wiki reading stays out of the main conversation.
- Added the platform wiki sync: `scripts/sync-wiki.sh` clones [`cloudcart/platform-wiki`](https://github.com/cloudcart/platform-wiki) to `~/.cloudcart-ai-toolkit/wiki`, with a `SessionStart` hook (`hooks/hooks.json`) that refreshes it in the background on Claude Code and a skill-side check that covers every other host. The source is public, so no account or token is required. Freshness is checked with a single `ls-remote` against the remote head, so an up-to-date session pays a fraction of a second instead of a clone.
- Removed `cloudcart-onboarding-merchant`. Store connection (URL parsing, browser sign-in, PAT) now lives in `cloudcart-product-management` Step 0; `cloudcart-cli-install` and `cloudcart-dev-mcp-install` hand off there instead.
- Added `cloudcart-product-management` (previously unreleased) — create, edit, delete, and bulk-import products, with bulk-transform primitives and dry-run/snapshot rules for large sets.

## 0.1.0

Initial release.

- Plugin manifests for Claude Code, Cursor, OpenAI Codex, Gemini CLI, and VS Code (GitHub Copilot).
- Auto-registration of the CloudCart Dev MCP server (`@cloudcart/dev-mcp`) via `.mcp.json`.
- Three skills:
  - `cloudcart-cli-install` — installs `@cloudcart/cli` on demand.
  - `cloudcart-dev-mcp-install` — registers the Dev MCP with hosts that don't support plugin auto-install.
  - `cloudcart-onboarding-merchant` — guides merchants through CLI install, store auth, and day-to-day operations via the MCP-first GraphQL workflow.
