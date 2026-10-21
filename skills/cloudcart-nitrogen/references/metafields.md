# Metafields and metaobjects

The merchant's own data model. **Metafields** are typed fields the store adds to its products, categories and customers: a product's material, a category's banner, a customer's loyalty tier. **Metaobjects** are content types the store invents — a size chart, a designer, an FAQ, a home page section — whose **entries** metafields reference. A storefront reads both through the Storefront API and decides itself how to show them, so they let it show what the platform has no field for, without waiting for a change to the API. For now they are for Nitrogen storefronts: the platform's own themes do not show them.

## The wiki: what they are, and a model for each need

The CloudCart platform wiki documents them, with a data model for the common needs. This plugin keeps a copy at `~/.cloudcart-ai-toolkit/wiki` (`$CLOUDCART_WIKI_HOME` overrides the folder). Each link below opens the page on GitHub; the same path, under that folder, is the local copy.

- **The chapter, Metafields and metaobjects — [`metafields-metaobjects`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects.md):** what they are, the two layers (a definition, then its values), how they differ from category properties, customer custom fields and CMS pages, and where they live in the admin. Its pages:
  - [On a Nitrogen storefront](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-nitrogen.md): the queries, what references resolve to, what a storefront can rely on;
  - [Types and validations](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-types.md): every type, its value's format and its `list.` form;
  - [Metafield definitions](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-definitions.md), [Metaobject definitions and entries](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metaobjects-definitions.md), [Capabilities](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-capabilities.md) (the admin filter, smart collections), [Limits](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-limits.md), [Permissions](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-permissions.md) (what the storefront and a signed-in customer may read).
- **The use cases (case studies) — [`metafields-use-cases`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases.md):** 22 data models. Each gives the metaobject definition, the metafields and their types, the native feature it builds beside, and how a storefront reads it. Find the one for a task by a few words:

**Product information**

| The need, in a few words | На български | The case |
|---|---|---|
| Typed specs with units beside the native dimensions, weight and energy class; comparison tables | Технически характеристики, Спецификации на продукт | [`metafields-use-case-specifications`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-specifications.md) |
| Structured charts and fit hints, beside the Size Chart app | Таблица с размери, Размерна таблица | [`metafields-use-case-size-charts`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-size-charts.md) |
| Ingredients, materials, allergens and nutrition as reusable entries | Съставки, Алергени | [`metafields-use-case-ingredients`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-ingredients.md) |
| Typed, shared, multilingual documents beside the product's public files | Инструкция за употреба, Сертификат | [`metafields-use-case-documents`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-documents.md) |
| What's in the box, with links to items sold separately | Какво има в кутията, Съдържание на комплекта | [`metafields-use-case-box-contents`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-box-contents.md) |
| Lead times, pre-order and restock dates, delivery notes beside product statuses | Срок за доставка, Предварителна поръчка | [`metafields-use-case-availability-notes`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-availability-notes.md) |

**Merchandising**

| The need, in a few words | На български | The case |
|---|---|---|
| Typed relationships (accessories, consumables, successors) beside Linked products | Аксесоари, Резервни части | [`metafields-use-case-related-products`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-related-products.md) |
| Colour families across separate products | Цветове мостри, Сродни продукти | [`metafields-use-case-color-swatches`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-color-swatches.md) |
| Compatibility beyond brand → model, beside the Brand-Model app | Съвместимост, Подходящ за модел | [`metafields-use-case-compatibility`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-compatibility.md) |
| Certification and quality icons; flags that build smart collections | Сертификати, Иконки с предимства | [`metafields-use-case-highlights`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-highlights.md) |
| Hero, intro, SEO text and featured products on category pages | Съдържание на категория, Банер на категория | [`metafields-use-case-category-content`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-category-content.md) |

**Content**

| The need, in a few words | На български | The case |
|---|---|---|
| Homepage and landing pages composed of section entries | Секции на начална страница, Лендинг страница в Nitrogen | [`metafields-use-case-page-sections`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-page-sections.md) |
| Scheduled banners, announcements and a singleton settings entry | Банер, Лента с обява | [`metafields-use-case-banners`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-banners.md) |
| Shared questions on products, categories and a help centre | Често задавани въпроси, Въпроси и отговори | [`metafields-use-case-faq`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-faq.md) |
| Designer, author and maker profiles with their product pages | Профил на дизайнер, Автор | [`metafields-use-case-designers`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-designers.md) |
| Store testimonials, press mentions, case studies | Отзиви на клиенти за магазина, Споменавания в медии | [`metafields-use-case-testimonials`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-testimonials.md) |
| Recipes, lookbooks, routines and guides linked to products | Рецепти, Лукбук | [`metafields-use-case-recipes-guides`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-recipes-guides.md) |
| Events and workshops, with dates the storefront filters | Събития, Работилници | [`metafields-use-case-events`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-events.md) |

**Customers and operations**

| The need, in a few words | На български | The case |
|---|---|---|
| Loyalty tier, points, preferences; what the customer sees on their account page | Лоялна програма, Ниво на клиента | [`metafields-use-case-customer-profile`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-customer-profile.md) |
| Payment terms, credit limit, account manager, contract on business customers | Данни за фирмен клиент, Кредитен лимит | [`metafields-use-case-b2b-accounts`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-b2b-accounts.md) |
| ERP, PIM and supplier keys kept off the storefront | Код от ERP, Код на доставчик | [`metafields-use-case-integration-data`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-integration-data.md) |
| Three patterns for content in several languages | Превод на метаполета, Метаполета на няколко езика | [`metafields-use-case-multilanguage`](https://github.com/cloudcart/platform-wiki/blob/master/wiki/concepts/metafields-metaobjects/metafields-use-cases/metafields-use-case-multilanguage.md) |

**Open a page:** read the file in the local copy. If `~/.cloudcart-ai-toolkit/wiki/index.md` is missing, run the plugin's `scripts/sync-wiki.sh --ensure` (in Claude Code, `"$CLAUDE_PLUGIN_ROOT"/scripts/sync-wiki.sh`); if the wiki is there but these pages are not, the copy is older than they are: `sync-wiki.sh --force`. If a page has moved, find it by its name (`**/metafields-use-case-size-charts.md`). Without the local copy, read the link. Read the use case and the chapter before you model anything: they name the native feature to use first and the limits to plan within. A merchant's question about the admin's screens is the platform expert's (`cloudcart-platform-expert`).

## Which tool for which need

From the wiki's use cases:

| The need | Use |
|---|---|
| Something the platform already has: dimensions, linked products, labels, the Size Chart app, reviews, bundles | the native feature |
| Shoppers filter listings by it | a category property (`Product.properties`; the listing filter `productMetafield` filters by a property, despite its name) |
| One more fact about each product, category or customer | a metafield |
| The same content on many records, or a new kind of content | a metaobject, referenced by metafields |
| A product list that keeps itself up to date by a value | a smart collection with a metafield condition |

## What the merchant sets up

The merchant makes the definitions and fills the values in the admin (Settings → Metaobjects, and the Metafields card on a product's, category's or customer's page). A storefront reads them and never writes them. Before you build:

- **Get each definition's `namespace.key` and type** from the merchant, or read them through the Admin API (`metafieldDefinitions`, `metaobjectDefinitions`, with the Dev MCP and `cloudcart app execute`). Never guess a key. Definitions made in the admin are in `custom`, and the admin makes a key from the name (`Размерна таблица` → `razmerna_tablica`).
- **The storefront sees only what is open to it:** a definition with storefront access `PUBLIC_READ` (the default), and only the **Active** entries of a metaobject. Anything else answers `null` or an empty list, not an error: when a value does not show, check this first.
- **A model the store does not have yet:** propose it from the wiki's use case — the definitions, their types, which fields are required — for the merchant to create in the admin, or through the Admin API (the Dev MCP's guide shows how to make them as the admin does).

## Reading them

- **In the page's existing query, never in a call of its own:** `metafield(namespace:, key:)` with an alias for each, or `metafields(identifiers: [{namespace, key}, …])`, which answers one per identifier, in their order, `null` where there is none. Always pass `namespace`: without it nothing is found.
- **A reference** is followed in the same query: `reference { ... on Metaobject { name: field(key: "name") { value } } }`, `... on MediaImage { image { url altText width height } }`, and `references(first:)` for a `list.` type. Only the fields the page renders.
- **Metaobjects:** `metaobject(handle: {type:, handle:})` for one entry, `metaobjects(type:, first:, after:)` for a type's entries, paged as any list (`getPaginationVariables`, `PaginatedResourceSection`). `query: "fields.topic:delivery"` filters only by fields that have the admin filter on (other terms are ignored), and `sortKey` is `id` or `updated_at`. An entry's `fields` come in no fixed order: read each with `field(key:)`.
- **A page for each entry** (a designer, a recipe, an event): a route by type and handle, its own `meta` (`seoMeta`), and a 404 when `metaobject` answers `null`.
- **The cost:** each identifier, and each item of `metaobjects` and `references`, counts toward the query's complexity (at most 1000). Ask for small pages; a list inside a list asks each item's first few.
- **Caching:** a metafield follows the data around it — a product's with the product page, the page cache included (a `PUBLIC_READ` value is the same for every visitor). An entry the merchant edits and every page reads (a settings or announcement entry) is `CacheSettings()`. A customer's metafields come only to that customer, through `customerAccount.query`, on a private page, and only for definitions the merchant opened to customer accounts.
- **Validate** each document with the storefront MCP, then `npm run codegen`. Codegen needs Nitrogen **2.2** or later: 2.1 and 2.0 ship a schema without these fields and refuse them (`Cannot query field "metafield" on type "Product"`). Move the project to `^2.2.0`; never add a schema of your own beside Nitrogen's to get past it.

## Showing them

`value` is always a string. Read it with `parseMetafield(metafield)` from `@cloudcart/nitrogen-react`, which gives the value its type names, and render it with Nitrogen's components:

| Type | `parseMetafield` gives | Render it with |
|---|---|---|
| `single_line_text_field`, `multi_line_text_field` | the string | text; a multi-line value keeps its line breaks (`whitespace-pre-line`) |
| `rich_text_field` | the tree (`RichTextRoot`) | `<MetafieldRichText data={metafield.value} headingStart={…} />` — never `<RichText>`, which renders HTML and would show the JSON |
| `number_integer`, `number_decimal` | a number | `Intl.NumberFormat` in the page's locale |
| `rating` | `{value, scaleMin, scaleMax}` | stars, or the number on its scale |
| `money` | `{amount, currencyCode}` | `<Money data={moneyWithFormat(amount, currencyCode, shop.currencyFormat)} />`: the store's own format |
| `weight`, `dimension`, `volume` and the other measurements | `{value, unit}`, the unit in lower case (`kilograms`) | the number, and the unit's name from `app/locales/` |
| `date` | a `Date` at midnight UTC | formatted with `timeZone: 'UTC'`, or a time zone west of UTC shows the day before |
| `date_time` | a `Date` | formatted in the store's zone (`Shop.ianaTimezone`) |
| `boolean` | `true` or `false` | a badge or a flag |
| `color` | `#rrggbb` | a swatch, with the colour's name as text |
| `url`; `link` | the string; `{text, url}` | a link, only for `http`, `https`, `mailto`, `sms` and `tel` |
| `file_reference` | the file's global ID | its `reference`: a `MediaImage` with `<Image>`, a `Video` with `<Video>`, a `GenericFile` as a link to its `url` |
| `product_reference`, `collection_reference`, `page_reference`, `metaobject_reference` … | the global ID | its `reference` (`references` for a list), with the starter's card or link for that kind |
| `json` | the parsed value | in the shape its use case gives it (a size chart's table) |
| `list.` types | an array, each item as its type above | a list |

An empty value renders nothing: no label without its value, and no placeholder (`references/store-kinds.md`). A view of a metaobject that several pages show — a designer card, an FAQ, a size chart dialog — is a building block (`references/building-block.md`).
