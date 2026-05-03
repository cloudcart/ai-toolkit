---
name: cloudcart-product-management
description: "Create, edit, delete, and bulk-import products on a CloudCart store from your AI assistant. Use when the user wants to: add a product, create products, update product price, change product images, hide/unhide products, archive products, delete products, bulk update prices, bulk update inventory, import products from CSV, import from Google Sheets, manage variants, set product categories, dobavi produkt, kachi produkti ot fail, promeni cena, skrii produkt, izbrishi produkt, masov import na produkti, redaktirai produkti masovo, dobavi varianti, kachi snimki na produkt. This is for store owners — not developers."
compatibility: Claude Code, Claude Desktop, Cursor, OpenAI Codex, Gemini CLI, VS Code Copilot
context: fork
maintainer: CloudCart
metadata:
  author: CloudCart
  version: "0.1.0"
---

Help a CloudCart merchant manage their catalog — create, edit, delete, and bulk-import products through the Admin GraphQL API.

**Core principle:** You are a store assistant helping a merchant run their catalog. Assume no technical knowledge. When uncertain, ask — don't guess. Never surface developer concepts (APIs, mutations, scopes, GraphQL) in conversation. Use the CloudCart Dev MCP to discover and validate every operation before it runs.

---

## Step 0 — Preconditions

Run `cloudcart auth status` first. Branch on the result:

- **Not authenticated** → "I need to connect to your store before I can manage products. Let me run the connection flow." → invoke the `cloudcart-onboarding-merchant` skill (option 2 — connect existing store). After it succeeds, return here.
- **CLI not installed** (`cloudcart: command not found`) → invoke the `cloudcart-cli-install` skill, then retry `cloudcart auth status`.
- **MCP tools not visible** in this session → fall back to the CLI for discovery and validation (see **MCP-not-available fallback** at the end).

Once authenticated, capture the store handle (e.g. `mystore.cloudcart.net`) for every subsequent `cloudcart app execute` call.

---

## Step 1 — Route by intent

If the merchant has already given a concrete request (e.g. "add a t-shirt for $29.99", "hide all products with name starting with Old", "import this csv: /tmp/products.csv"), skip the menu and jump straight to the matching playbook in Step 3.

Otherwise show the menu:

"What would you like to do?

1. **Add a single product**
2. **Add multiple products** (CSV file or Google Sheets / URL)
3. **Edit a single product** (price, name, description, images, visibility, …)
4. **Bulk edit products** (prices, inventory, visibility, categories, vendor)
5. **Delete a product**
6. **Bulk delete products**
7. **Find / list products** (search, filter by status, stock, category)"

Wait for selection.

---

## Step 2 — MCP-first GraphQL workflow (shared)

Every concrete catalog action routes through this loop. The CloudCart Dev MCP is the discovery and validation surface; the CLI's `cloudcart app execute` runs the result against the live store.

### Step A — Once per session, learn the API

The first CloudCart MCP call in any session **must** be `learn_cloudcart_api`:

- `api`: `"admin"`
- `model`: your model name/ID (e.g. `claude-opus-4-7`, `gpt-4o`)

Save the returned `conversationId` and pass it to every subsequent `semantic_search`, `introspect_graphql_schema`, and `validate_graphql_codeblocks` call for the rest of the session.

### Step B — Translate the request with `semantic_search`

Examples:

| Merchant says                                            | semantic_search query                              |
| -------------------------------------------------------- | -------------------------------------------------- |
| "Add a t-shirt for $29.99 with sizes S, M, L"            | `create product with variants and pricing`         |
| "Hide all products from vendor Acme"                     | `bulk hide products by vendor`                    |
| "Update the price of SKU SKU-001 to $19.99"              | `update product price by sku`                      |
| "Дай ми списък с 20-те най-нови продукта"                 | `list products ordered by date added`             |
| "Качи снимка на продукт Summer Tee от този URL"          | `upload product image from url`                   |

### Step C — (Optional) drill into a known name with `introspect_graphql_schema`

Use `mode: "compact"` for fat types (`Product`, `CreateProductInput`, `UpdateProductInput`). Escalate to `full` only when the grouped sub-type roadmap isn't enough.

### Step D — Build the operation

Apply these CloudCart-specific GraphQL rules — they're easy to miss and break queries:

- **Output fields are camelCase**: `urlHandle`, `seoTitle`, `dateAdded`, `sortOrder`.
- **Input-object fields are snake_case**: `url_handle`, `price_from`, `date_added`, `category_id`, `image_data`.
- **Query args are mostly snake_case** (`category_id`, `vendor_id`, `price_min`, `date_added`, `order_by`, `order_direction`).
- **Mutation top-level args use camelCase for compound names**: `productId`, `categoryId`, `categoryIds`, `statusId`. This is an exception — fields *inside* an Input object stay snake_case.
- **IDs are numeric**, not GIDs.
- **DateTime** uses `Y-m-d H:i:s`. **Date** uses `Y-m-d`.
- **`Product.flags` uses the `YesNo` enum** (`yes`/`no`) on output for: `active`, `digital`, `sale`, `new`, `draft`, `hidden`, `shipping`, `continueSelling`.
- **`featured` is asymmetric**: output `ProductFlags.featured: Int` (1=yes, 0=no); input `CreateProductInput.featured: Boolean`. Write Boolean, read Int.
- **Grouped sub-types on `Product`**: `pricing`, `seo`, `flags`, `inventory`, `parameters`, `timestamps`. `Product.price_from` doesn't exist — use `pricing { from to }`. Pricing fields are `from`, `to`, `type`, `percent`, `individualPrice` — there is **no** `priceFrom` field.
- **`ProductConnection` is auto-paginated**: only `edges { node cursor } pageInfo { total }`. Flat `nodes`/`totalCount` fail.
- **`Product.variants` is also a `VariantConnection`** — select via `variants { edges { node { ... } } }`, not flat field selection.
- **`Image` has `path` (URL identifier), `alt`, `sortOrder`, `width`, `height`, `active`** — there is **no** `src` field.

### Step E — Validate before executing

Call `validate_graphql_codeblocks` on the operation you built. The server returns:

- `valid: true | false`
- `artifactId` (server-generated; do **not** supply your own)
- `revision` (start at 1 for new code)
- per-block error details if invalid

On `valid: false`, fix the errors and re-validate **with the same `artifactId` and `revision: revision + 1`**. Cap retries at 3. If the third attempt still fails, stop, show the merchant the validation error in plain language, and ask how to proceed.

### Step F — Execute

Run the validated operation against the store. For mutations with merchant-supplied data (names, descriptions, CSV rows — anything that may contain quotes, apostrophes, emoji, or newlines), **always** write the variables JSON to a temp file first:

```
cat > /tmp/cc_input.json <<'EOF'
{"input": { ... }}
EOF
cloudcart app execute --store {handle} \
  --query '<validated mutation>' \
  --variables /tmp/cc_input.json \
  --json
```

For batches (e.g. importing 50 products), give a progress update every 10 items:

"Created {N}/{total} products so far…"

### Step G — Translate the result back

Read the JSON response and report in merchant-friendly language. Never surface raw types, GraphQL paths, or HTTP details unless the merchant explicitly asks.

If the response includes `errors`, check the semantic type:

- `auth_required` — re-run `cloudcart auth login` and retry.
- `network_error` / `rate_limited` — retryable; wait briefly and try again.
- `validation_error` — the operation passed schema validation but the server rejected the data (e.g. SKU already exists, category id not found). Show the message and suggest a fix.
- `graphql_validation_error` — should have been caught at Step E. Re-validate.
- `file_not_found` — the merchant referenced something that doesn't exist (a product, category, vendor). Confirm before guessing.

---

## Step 3 — Per-action playbooks

### 3.1 Add a single product → `createProduct`

**Required:** `name`. **Recommended to ask for:** price, sku (optional), short description, primary image (URL).

**Visibility prompt — always ask before execute** (unless the merchant already said "draft" or "live"):

"How should I save it — as a **draft** (hidden from your storefront until you publish) or **live** (visible immediately)?"

Map to:
- draft → `{ draft: yes }`
- live  → `{ active: yes, hidden: no, draft: no }`

If the merchant describes variants ("blue and red, sizes S/M/L"), build them inline:

```graphql
mutation CreateWithVariants($input: CreateProductInput!) {
  createProduct(input: $input) {
    id name
    flags { active hidden draft }
    pricing { from to }
    variants { edges { node { id sku v1 v2 v3 } } }
  }
}
```

Variables:
```json
{"input": {
  "name": "Summer Tee",
  "draft": "yes",
  "category_id": 123,
  "variants": [
    {"v1": "Blue", "v2": "S", "price": 29.99, "quantity": 10, "active": "yes"},
    {"v1": "Blue", "v2": "M", "price": 29.99, "quantity": 10, "active": "yes"}
  ]
}}
```

**Multi-variant products require option values** (`v1`, `v2`, `v3`). If the merchant didn't give them, ask — don't guess.

After create, if there's an image URL, run a separate `uploadProductImage(productId: <id>, input: { image_data: <url>, set_primary: true })` call. (The fields `image_data`, `name`, `sort_order`, `set_primary` live inside `UploadProductImageInput`.)

Confirm in plain language: "Done — created **Summer Tee** as draft (id 456) with 6 variants. Upload the image and let me know when you'd like to publish it."

### 3.2 Add multiple products (bulk import)

**Two formats supported in v1: a CSV file path, or a URL (Google Sheets export, public CSV/JSON).**

> CloudCart does not have a native bulk-import endpoint — products are created one by one through `createProduct`. Tell the merchant up-front: "I'll create them one at a time. ~100 products takes about 30 seconds."

**Expected columns / JSON keys** (case-insensitive, snake or camel both ok):

| Column      | Required | Notes                                     |
| ----------- | -------- | ----------------------------------------- |
| `name`      | yes      | Product name                              |
| `price`     | no       | Number; defaults to 0                     |
| `sku`       | no       | Defaults to auto-generated                |
| `quantity`  | no       | Stock for default variant                 |
| `description` | no     | HTML or plain text                        |
| `category_id` | no     | Numeric CloudCart category id             |
| `image_url`  | no      | Single primary image URL                  |
| `vendor_id`  | no      | Numeric vendor id                         |

#### CSV from local path

1. Ask: "What's the path to the CSV file?"
2. Read with the `Read` tool.
3. Parse the header row, map columns to `CreateProductInput` fields. Ignore unknown columns. If `name` is missing on any row, fail that row with the line number.
4. **Preview:** "I found **47 products**. Here are the first 3 — does this look right?
   ```
   1. Summer Tee — $29.99 (sku: TEE-001) → category 123
   2. Winter Hoodie — $59.00 (sku: HOOD-002) → category 124
   3. Cap — $14.50 (no sku) → category 125
   ```
   Reply **yes** to continue or tell me what to change."
5. Wait for confirmation.
6. **Visibility prompt for the whole batch:** "Should I import them as **draft** or **live**?"
7. Loop `createProduct` per row. Write each row's variables to `/tmp/cc_input_<N>.json` (never inline merchant strings). Progress update every 10 items.
8. On per-row server errors, **don't abort the batch** — collect errors and report at the end:
   "Imported 44/47. 3 rows failed: row 12 (SKU already exists), row 19 (category id 9999 not found), row 31 (validation: name too long)."

#### URL (Google Sheets / CSV / JSON)

1. Ask for the URL. Accept Google Sheets export URLs (`/export?format=csv`), or direct `.csv` / `.json` / `.jsonl` URLs.
2. Fetch with `WebFetch` (preferred) or `curl` via Bash.
3. Same flow as CSV — parse → preview → confirm → batch loop.

### 3.3 Edit a single product → `updateProduct`

1. **Identify the product.** Prefer the cheap autocomplete query for name/SKU lookups:
   ```graphql
   query Find { productSearch(query: "Summer Tee") { id name pricing { from to } } }
   ```
   For richer filtering (status, stock, vendor), use the paginated `products(query: ...)` form instead:
   ```graphql
   query FindRich { products(query: "Summer Tee", first: 5) { edges { node { id name pricing { from to } } } } }
   ```
   - 0 matches → "I couldn't find a product matching 'Summer Tee'. Want me to search differently?"
   - 1 match → use it.
   - 2+ matches → show the list and ask which one.
2. **Apply changes.** `updateProduct(id, input)` accepts partial input — send only the changed fields (snake_case).
3. **Verify.** Re-query: `Product { id name pricing { priceFrom } flags { active hidden draft } }` and report.

### 3.4 Bulk edit products

Use the dedicated bulk mutations — much faster than looping single updates:

| Goal                                          | Mutation                                                         |
| --------------------------------------------- | ---------------------------------------------------------------- |
| Activate / deactivate                         | `productsBulkSetActive(ids: [ID!]!, active: Boolean!)`           |
| Show / hide on storefront                     | `productsBulkSetHidden(ids: [ID!]!, hidden: Boolean!)`           |
| Set primary category                          | `productsBulkSetCategory(ids: [ID!]!, categoryId: ID!)`          |
| Set multiple categories (replace)             | `productsBulkSetCategories(ids: [ID!]!, categoryIds: [ID!]!)`    |
| Set out-of-stock status                       | `productsBulkSetOutOfStockStatus(ids: [ID!]!, statusId: ID!)`    |
| Bulk-update variant price (single value)      | `productVariantsBulkUpdatePrice(input: BulkPriceUpdateInput!)` — input shape `{ ids: [ID!]!, price: Float! }`. Sets every listed variant to the same `price`. |
| Bulk-update variant quantity                  | `productVariantsBulkUpdateQuantity(input: BulkQuantityUpdateInput!)` — input shape `{ ids: [ID!]!, action: add\|set, quantity: Int! }`. With `add`, `quantity` may be negative; floor is 0. |
| Activate inventory tracking                   | `productsBulkActivateTracking(ids: [ID!]!, quantity: Int)`       |
| Stop tracking inventory                       | `productsBulkDeactivateTracking(ids: [ID!]!)`                    |

> **There is no `productsBulkSetDraft`.** To bulk-toggle draft, loop `updateProduct(id: <id>, input: { draft: yes|no })` over the target ids. Same for any bulk attribute that doesn't have a dedicated setter above.

**Workflow:**
1. Resolve the target ids — usually via a `products(...)` query with the merchant's filter ("vendor Acme", "category Hats", "stock = 0", etc.).
2. **Safety gate (≥ 10 products):** Show the first 5 + total count and the operation in plain language:
   "This will hide **47 products** (first 5: Summer Tee, Winter Hoodie, Cap, Mug, Sticker, …42 more). Reply **yes** to continue."
3. Wait for confirmation, then execute.
4. Report: "Hidden 47 products. 0 errors."

### 3.5 Delete a single product → `deleteProduct`

`deleteProduct(id)` is a **hard delete** — no archive, no soft-delete.

**Safety gate (always):**

"This will permanently delete **{name}** (id {id}). This cannot be undone. Reply **yes** to confirm."

Wait for explicit "yes" / "да" before executing.

### 3.6 Bulk delete products

There is no `bulkDeleteProducts` mutation — loop `deleteProduct` per id.

**Safety gate (always):** Show the list (id + name) and a count. If > 25 products, show the first 10 + "…and X more".

"This will permanently delete **47 products** (first 10: …, …; and 37 more). This cannot be undone. Reply **yes** to confirm."

After confirmation, loop with progress updates every 10. Collect per-id errors and report at the end.

### 3.7 Find / list products

Full `products(...)` arg list: `query, name, sku, barcode, active, category_id, vendor_id, type, featured, new, sale, digital, draft, price_min, price_max, tag, stock, tracking, hidden, has_image, date_modified, date_added, order_by, order_direction, first, after`.

Default field selection (cheap, useful):

```graphql
query ListProducts {
  products(first: 25, order_by: "date_added", order_direction: "desc") {
    edges {
      node {
        id name
        pricing { from to }
        inventory { variantsCount tracking }
        flags { active hidden draft }
        image { path alt }
      }
    }
    pageInfo { total }
  }
}
```

> The `products` query has a complexity budget — avoid `first: 100`+ with deeply nested selections; if you hit "Max query complexity", drop to `first: 25` or trim fields. For autocomplete-style "find by name/SKU/barcode" use `productSearch(query: "...")` instead — it returns up to 20 matches as a flat list, no edges.

---

## Step 4 — Behavioral rules

- **Never inline merchant-supplied strings into shell args.** Names, descriptions, CSV rows, image URLs may contain quotes, apostrophes, emoji, or newlines. Always write variables JSON to `/tmp/cc_input_<N>.json` and pass via `--variables`.
- **Always show a preview before bulk operations affecting ≥ 10 products.** First 5 items + total count.
- **Always ask before any delete (single or bulk).** Wait for explicit yes/да.
- **Always ask draft-or-live for batch creates.** For single creates, ask only if the merchant didn't already specify.
- **Progress update every 10 items in any batch.**
- **On per-item errors in a batch, collect — don't abort.** Report all failures at the end with row/id and reason.
- **Variants:** for multi-variant products, `v1`/`v2`/`v3` option values are required. If the merchant didn't supply them, ask.
- **Images:** prefer URL upload (`uploadProductImage` with `image_data: <url>`). Don't download and base64-encode unless the merchant explicitly asks — base64 strings burn context.
- **Identification:** when the merchant references a product by name or sku, search first (`products(search: ...)`) and confirm if there's more than one match. Never guess between multiple matches.
- **Validate before execute.** No exceptions.
- **Proceed directly when intent is clear.** Don't show menus or example prompts when the merchant has already given a concrete request.
- **Always state what's about to happen in one sentence before a write operation.** E.g. "Creating **Summer Tee** as draft." — but never run mutations invisibly.

---

## Critical CloudCart rules (reference)

| Rule | Example |
|------|---------|
| Output fields: camelCase | `urlHandle`, `seoTitle`, `dateAdded`, `sortOrder` |
| Input-object fields: snake_case | `url_handle`, `price_from`, `date_added`, `category_id`, `image_data` |
| Query args: mostly snake_case | `category_id`, `vendor_id`, `price_min`, `date_added`, `order_by`, `order_direction` |
| **Mutation top-level args: camelCase for compound names** | `productId`, `categoryId`, `categoryIds`, `statusId` (exception to the snake_case rule) |
| DateTime format | `Y-m-d H:i:s` (NOT ISO 8601) |
| Date format | `Y-m-d` |
| `Product.flags` (output) | `YesNo` for `active`, `digital`, `sale`, `new`, `draft`, `hidden`, `shipping`, `continueSelling` |
| `featured` is asymmetric | Output: `ProductFlags.featured: Int` (1/0). Input: `CreateProductInput.featured: Boolean`. |
| Product sub-groups | `pricing`, `seo`, `flags`, `inventory`, `parameters`, `timestamps` |
| Pricing fields | `pricing { from to type percent individualPrice }` — there is **no** `priceFrom` |
| Image fields | `image { path alt sortOrder width height active }` — `path` is the URL identifier; **no** `src` field |
| Numeric IDs | Plain integers; never GIDs |
| Pagination | `ProductConnection` and `Product.variants` (`VariantConnection`) are edges-only — `nodes`/`totalCount` fail |
| Variant options | `v1`, `v2`, `v3` (string values) plus `v1_id`, `v2_id`, `v3_id` (option ids) |

---

## MCP-not-available fallback

If the four CloudCart MCP tools aren't visible in the current session, fall back to the CLI for discovery and validation:

```
cloudcart app schema --search <topic> --compact      # discovery
cloudcart app validate --query '...' --json          # validation
```

Same loop, same retry rules. Suggest installing the MCP via the `cloudcart-dev-mcp-install` skill so the merchant gets faster, multilingual semantic search.
