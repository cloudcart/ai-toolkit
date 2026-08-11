# Changelog

## 0.2.2

Tightened `cloudcart-platform-expert` after reviewing a real answer against the wiki:

- **Invented interactions.** The answer stated that the order minimum is compared after discounts — plausible, useful, and not on any wiki page. The grounding rule now names that shape explicitly: a sentence describing how one feature interacts with another is where platforms genuinely differ, so it is exactly what cannot come from general knowledge.
- **Disambiguation ordering.** The answer resolved one reading in full, then disclosed that the question had three. Disambiguation is now a gate: if you are about to write "but if you actually meant X, don't use the above", lead with the question instead.
- **Hub frontmatter.** An aspect page can carry `plan_gates: []` while the hub that owns the screen carries real gates. Reading only the aspect reports a gated feature as ungated.
- **Label language.** Wiki labels are English; a translated nav path next to an untranslated field name leaves the merchant scanning for a string that is not on screen.

## 0.2.1

- Fixed skill routing: platform questions were dispatching to `cloudcart-dev-mcp-install` instead of `cloudcart-platform-expert`. The platform-expert description now leads with concrete phrasings and carries Bulgarian triggers in Cyrillic rather than only transliterated, trigger phrases moved to `when_to_use`, and each of the other three skills states explicitly when *not* to use it.
- `cloudcart-platform-expert` now states that the Dev MCP's `semantic_search` covers the Admin GraphQL schema, not platform behaviour, so it is not a substitute for the wiki on "how does it work" questions.

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
