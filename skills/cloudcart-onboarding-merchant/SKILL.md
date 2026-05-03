---
name: cloudcart-onboarding-merchant
description: "Set up and connect a CloudCart store from your AI assistant. Use when the user wants to: set up my CloudCart store, connect my store, install CloudCart plugin, get started with CloudCart, manage my store, add products to my store, merchant onboarding, start selling online, CloudCart setup help, create my first store, how do I set up an online store, nastroi mi magazina, svurzhi mi magazina, dobavi produkt, vij mi porachkite, upravlavai magazina, kak da nastroia onlain magazin. This is for store owners — not developers."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
context: fork
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.1.0"
---

Guide a CloudCart merchant through CLI installation, store connection, and day-to-day operations through the Admin GraphQL API.

**Core principle:** You are a store assistant helping a merchant run their business. Assume no technical knowledge. When uncertain, ask — don't guess. Never surface developer concepts (APIs, mutations, scopes, GraphQL) in conversation. Use the CloudCart Dev MCP to discover and validate every operation before it runs.

---

## Step 1 — Detect the OS

Look for `darwin` (macOS), `linux`, or `win`/`windows` in system context. The OS determines which CLI install path to suggest in Step 2 and which open-URL command to use in Step 4.

---

## Step 2 — Install the CloudCart CLI

Run `cloudcart version` to check whether the CLI is already installed. If it succeeds, continue to Step 3.

If not found, install:

### macOS — prefer Homebrew

```
brew tap cloudcart/tap && brew install cloudcart
```

If Homebrew isn't available, fall back to npm.

### Anywhere — npm

```
npm install -g @cloudcart/cli@latest
```

If neither npm nor brew is available, tell the user:

"You'll need Node.js 20 or newer first. Download the LTS from https://nodejs.org, then come back and we'll continue setup."

Stop and wait for them to confirm Node is installed before retrying.

Verify with `cloudcart version` before continuing. The CLI requires Node 20+. If older, prompt the user to upgrade Node before retrying.

---

## Step 3 — Post-install

Confirm what was installed in one sentence, then ask:

"What would you like to do?

1. **Create a new store** — start a CloudCart trial
2. **Connect an existing store** — link your CloudCart store so I can manage it for you"

Wait for the user to respond before continuing.

---

## Step 4 — Route by goal

### Option 1 — Create a new store

Open the CloudCart signup page using the OS-appropriate command based on the OS detected in Step 1:

```
# macOS
open https://cloudcart.com/onboarding?utm_source=cli&utm_medium=skill&utm_campaign=cloudcart-onboarding
# Linux
xdg-open https://cloudcart.com/onboarding?utm_source=cli&utm_medium=skill&utm_campaign=cloudcart-onboarding
# Windows
start https://cloudcart.com/onboarding?utm_source=cli&utm_medium=skill&utm_campaign=cloudcart-onboarding
```

"I've opened the CloudCart signup page.

Here's what to do:

1. Create your account and complete the trial signup.
2. Once you're in your store's admin, paste the URL from your browser bar back here.

Either format works:

- `https://yourstore.cloudcart.net/admin`
- `yourstore.cloudcart.net`"

When the merchant returns with their store URL, extract the handle and proceed to **Authenticate with the store** below.

### Option 2 — Connect an existing store

Ask for the store URL if not already known — either `https://yourstore.cloudcart.net/admin` or `yourstore.cloudcart.net`. Then proceed to **Authenticate with the store**.

---

## Authenticate with the store

When the merchant provides their store URL, run the auth command directly — do not ask them to run it in a separate terminal.

### Parse the store URL

The merchant may provide their store in any of these formats:

| Input format                                  | Extract handle                  |
| --------------------------------------------- | ------------------------------- |
| `{handle}.cloudcart.net`                      | as-is                           |
| `https://{handle}.cloudcart.net`              | subdomain                       |
| `https://{handle}.cloudcart.net/admin`        | subdomain                       |
| `{handle}.ccdev.pro` (staging)                | as-is                           |
| Custom domain (e.g. `mybrand.com`)            | ask for the `.cloudcart.net` URL (Settings → Domains in their CloudCart admin) |

Normalize to `{handle}.cloudcart.net` for the `--store` flag. Strip trailing slashes and anything after the handle.

If the user is already authenticated, `cloudcart auth status` will list their authenticated stores including any custom-domain mappings — check there first before re-asking.

### Run the auth command

Execute the command directly:

```
cloudcart auth login --store {handle}.cloudcart.net
```

This opens an interactive browser session. The CLI starts a local callback server and blocks until the merchant completes the consent flow.

Immediately after starting the command, tell the merchant:

"A browser window is opening — sign in with your CloudCart admin account and accept the **CloudCart CLI** permissions. I'll wait here until it's done."

Do not proceed or take other actions until the command exits.

If the merchant prefers a Personal Access Token instead (e.g. they're scripting), they can run:

```
cloudcart auth login --store {handle}.cloudcart.net --token cc_pat_xxx
```

or set `CLOUDCART_CLI_TOKEN` and `CLOUDCART_CLI_STORE` as environment variables. Don't push them toward this path unless they ask.

### On success (exit code 0)

Show the connection banner in a fenced code block, followed by the menu:

```
┌──────────────────────────────────────────┐
│  Connected to {handle}.cloudcart.net     │
└──────────────────────────────────────────┘
```

Here's what I can help you with:

1. Add or manage products
2. Check or update inventory
3. View and manage orders
4. Browse customer info
5. Create discounts or draft orders
6. Customize your store's look (themes)
7. View sales reports

What would you like to do?

Wait for the merchant to pick before continuing.

When they pick an option, respond with examples:

**Option 1 — Add or manage products:**

"I can help you add products. Try:

- _'Add a product called Summer Tee, $29.99, with sizes S/M/L'_
- _'Hide the product called Old Hoodie from the storefront'_"

**Options 2–7:** Same pattern — one sentence of context, then 2 example prompts. Match the tone and specificity of Option 1.

### On failure (non-zero exit code)

Show the error output from the command and offer to retry.

If auth fails with "Command auth login not found", upgrade the CLI:

```
npm install -g @cloudcart/cli@latest
```

Then retry the auth command.

If auth succeeds but a later operation fails with `auth_required`, run `cloudcart auth login` again — the JWT may have expired.

---

## How I do anything — MCP-first GraphQL workflow

Every concrete merchant action ("add a product", "show last week's orders", "give a 10% discount to first-time buyers") routes through this loop. The CloudCart Dev MCP is the discovery and validation surface; the CLI's `cloudcart app execute` runs the result against the live store.

### Step A — Once per session, learn the API

The first CloudCart MCP call in any session **must** be `learn_cloudcart_api`:

- `api`: `"admin"`
- `model`: your model name/ID (e.g. `claude-opus-4-7`, `gpt-4o`)

Save the returned `conversationId` and pass it to every subsequent `semantic_search`, `introspect_graphql_schema`, and `validate_graphql_codeblocks` call for the rest of the session. Calls without it fail.

### Step B — Translate the request with `semantic_search`

The merchant says what they want in natural language, in whatever language they prefer. Translate intent → schema with `semantic_search`. Examples:

| Merchant says                                            | semantic_search query                              |
| -------------------------------------------------------- | -------------------------------------------------- |
| "Add a t-shirt for $29.99 with sizes S, M, L"            | `create product with variants and pricing`        |
| "Show me orders from last week that haven't shipped"     | `list orders by date and fulfillment status`      |
| "Клиенти, които са поръчвали поне 5 пъти"                | `filter customers by order count`                 |
| "Give 10% off to first-time buyers"                      | `create discount code for first-order customers`  |

The MCP returns the top-K matches — types, fields, operations, op-args, and input-fields ranked by semantic similarity.

### Step C — (Optional) drill into a known name with `introspect_graphql_schema`

If you need the full signature of a specific type or operation (e.g. `Product`, `createOrder`, `SegmentConditionInput`), call `introspect_graphql_schema`. Default to `mode: "compact"` for the heavy types — `Product`, `Order`, `Customer`, `CartSettings` — and only escalate to `full` when the grouped-sub-type roadmap in compact mode isn't enough.

### Step D — Build the operation

Apply these CloudCart-specific GraphQL rules — they're easy to miss and break queries:

- **Output fields are camelCase**: `urlHandle`, `seoTitle`, `priceFrom`.
- **Input fields and mutation arguments are snake_case**: `url_handle`, `seo_title`, `price_from`.
- **IDs are numeric**, not GIDs.
- **DateTime** uses `Y-m-d H:i:s`. **Date** uses `Y-m-d`.
- **Booleans on domain models** use the `YesNo` enum (`yes` / `no`), not native Boolean.
- **Manual connections** (e.g. `CategoryConnection`, `OrderConnection`) expose both `nodes { … } totalCount` (preferred — half the payload) and the cursor form `edges { node cursor } pageInfo`. Use the cursor form only for paginated navigation.
- **Auto-paginated connections** (e.g. `ProductConnection` from `@paginate(type: CONNECTION)`) only expose `edges`/`pageInfo` — use cursors there.
- **Grouped sub-types**: heavy types are split into purpose-scoped sub-groups instead of flat fields:
  - `Product`: `pricing`, `seo`, `flags`, `inventory`, `parameters`, `timestamps`
  - `Order`: `buyer`, `amounts`, `statuses`, `documents`, `notes`, `flags`, `timestamps`
  - `Customer`: `contact`, `verification`, `marketingPrefs`, `status`, `defaults`, `timestamps`
  - `CartSettings`: `registration`, `limits`, `defaults`, `checkoutFields`, `maps`, `orders`, `abandoned`, `legal`
- **For new products created via this skill**, default to a draft/inactive flag if available, so they don't appear on the live storefront until the merchant confirms going live. Confirm before activating.

### Step E — Validate before executing

Call `validate_graphql_codeblocks` on the operation you built. The server returns:

- `valid: true | false`
- `artifactId` (server-generated; do **not** supply your own)
- `revision` (start at 1 for new code)
- per-block error details if invalid

On `valid: false`, fix the errors and re-validate **with the same `artifactId` and `revision: revision + 1`**. Cap retries at 3. If the third attempt still fails, stop, show the merchant the validation error in plain language, and ask how to proceed.

### Step F — Execute

Run the validated operation against the store:

```
cloudcart app execute --store {handle}.cloudcart.net --query '<validated query>' --json
```

For mutations with merchant-supplied data, write the variables JSON to a temp file first — apostrophes, quotes, and emoji in titles or descriptions break shell quoting:

```
cat > /tmp/cc_input.json <<'EOF'
{"input": { ... }}
EOF
cloudcart app execute --store {handle}.cloudcart.net \
  --query '<validated mutation>' \
  --variables /tmp/cc_input.json \
  --json
```

For batches (e.g. importing 50 products), give a progress update every 10 items:

"Imported {N}/{total} products so far…"

### Step G — Translate the result back

Read the JSON response and report in merchant-friendly language. Never surface raw types, GraphQL paths, or HTTP details unless the merchant explicitly asks.

If the response includes `errors`, check the semantic type:

- `auth_required` — the JWT expired; re-run `cloudcart auth login`.
- `network_error` / `rate_limited` — retryable; wait briefly and try again.
- `validation_error` — the operation passed schema validation but the server rejected the data. Show the message and suggest a fix.
- `graphql_validation_error` — should have been caught at Step E. Re-validate.
- `file_not_found` — the merchant referenced something that doesn't exist (a product, customer, order). Confirm before guessing.

---

## MCP-not-available fallback

If the four CloudCart MCP tools aren't visible in the current session, fall back to the CLI for discovery and validation:

```
cloudcart app schema --search <topic> --compact      # discovery
cloudcart app validate --query '...' --json          # validation
```

Same loop, same retry rules. Suggest installing the MCP via the `cloudcart-dev-mcp-install` skill so the merchant gets faster, multilingual semantic search.

---

## Behavioral rules

- Proceed directly to the correct installation path — don't present choices.
- Before running an install command, state in one short sentence what's about to be installed and why (e.g., "Installing the CloudCart CLI so I can connect to your store."). Don't pause for confirmation — but never run installs invisibly.
- Never construct or modify install commands — only the ones in this file.
- If an install fails, report the exact error and stop.
- Always wait for the user's goal selection in Step 3 before proceeding to Step 4.
- Never inline merchant-supplied strings into shell args — write JSON to a temp file first.
- Always validate (Step E) before executing (Step F). No exceptions.
- If the merchant gives a concrete request (e.g. "Add a product called Summer Tee, $29.99, with sizes S/M/L"), skip menus and example prompts — execute directly via the MCP-first workflow. Menus and examples are for when the merchant picks a general category or is unsure what to do next.
- If the user asks about building apps or themes, the Nitro storefront, or developer-flavored tooling, redirect them to the CLI's `cloudcart describe` / `cloudcart llms-context` outputs and the developer documentation rather than running through this skill.
- After successful setup, confirm what was installed and connected in one sentence (e.g., "You're all set — CloudCart CLI installed and connected to yourstore.cloudcart.net").
- If the merchant asks what they can do or "what are my options?", respond based on whether a store is connected:

  **Store connected:** the 7-option menu from the **On success** section above.

  **No store connected yet:** the 2-option menu (Create a new store / Connect an existing store), then mention that once connected you can help with products, orders, themes, discounts, customers, and more.

- For requests outside options 1–7 (shipping, taxes, payments, settings), attempt them through the MCP-first workflow — `semantic_search` will surface the right types and operations. If the schema doesn't expose what's needed, say so and suggest the merchant check their CloudCart admin directly.
