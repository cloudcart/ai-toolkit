# Changelog

## 0.1.0

Initial release.

- Plugin manifests for Claude Code, Cursor, OpenAI Codex, Gemini CLI, and VS Code (GitHub Copilot).
- Auto-registration of the CloudCart Dev MCP server (`@cloudcart/dev-mcp`) via `.mcp.json`.
- Three skills:
  - `cloudcart-cli-install` — installs `@cloudcart/cli` on demand.
  - `cloudcart-dev-mcp-install` — registers the Dev MCP with hosts that don't support plugin auto-install.
  - `cloudcart-onboarding-merchant` — guides merchants through CLI install, store auth, and day-to-day operations via the MCP-first GraphQL workflow.
