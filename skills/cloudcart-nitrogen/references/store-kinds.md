# By kind of store

What a storefront shows for each kind of store — on the product page, and in the search, the listings and the product cards — built from what the Storefront API already returns. Decide it in stage 1: it decides what each page's query selects. Ask the user which kind the store is, or read it from the catalogue. The merchant chooses the store's kinds in the admin, from the top level of Google's product taxonomy. Most stores are more than one kind: apply each section that fits.

Two rules hold for every kind:

- **The data is the merchant's.** Show what the API returns, and show nothing when a field is empty. Never invent a value, a default or a placeholder that looks like data: no made-up size chart, energy class or composition.
- **What has no field of its own lives in `properties`.** `Product.properties` (`name`, `values`) holds the merchant's product properties: fibre composition, ingredients, allergens, specifications, warranty, age range, compatibility. Render them as the product's specification table, in the merchant's order. Do not parse them for meaning; a property the merchant named is shown under that name.

## Every kind

- The product's gallery from `media`, in the merchant's order, with the selected variant's pictures first (`mediaIds`); a YouTube video plays in place (`ExternalVideo`).
- The price with `<Money>` from `formatted`; a discount from `discount` and `compareAtPrice`. `<ProductPrice>` shows the `compareAtPrice` it is given, so pass `null` when the merchant hides the old price (`discount.hideDiscountPrice`), as the starter's `shownCompareAtPrice` (`app/lib/variants.ts`) does for every price of a product.
- Availability from `availableForSale` and the variant's `statusName` (the store's own words: "in stock", "on request"…), and back-in-stock sign-up (`productBackInStockSubscribe`) when a variant is sold out and the store offers it.
- Reviews (`reviewSummary`, `reviews`) when the store runs them: both are empty otherwise.
- Volume prices (`quantityDiscounts`), the minimum quantity (`minimumQuantity`), and consumer credit (`creditOffers`) when the merchant offers them.
- Stock in the merchant's physical stores (`stockByStore`) when the store has them.
- **Search, listings and cards.** The search and the listings as `references/design.md` says. A listing's filters are the facets the API returns with its products (`products(…) { filters }`, a `ProductConnection` field), in the merchant's order. A card shows the picture, the title, the price (`<ProductPrice>`), a discount in the complementary colour, the merchant's labels (`labels`), "new" (`isNew`) and sold out. Each kind below names what can help to choose in it: options to pick from, not a list to add whole. Every field on a card is selected for every product of every listing, so add the one or two that matter most to that store's buyers.

## Fashion: apparel, accessories, shoes, bags

- **Options as swatches:** a colour option shows its `swatch` (`color` or `image`), and a size option shows its values in the merchant's order. A sold-out combination stays visible but disabled (`getProductOptions` gives each value's `available` and `exists`).
- **The size chart:** `sizeChart` names a content page (`pageHandle`). Open it next to the size option, in a dialog or a link; show nothing when there is none.
- **The variant's pictures** change with the colour (`mediaIds`).
- **Fibre composition and care** from `properties`, on the product page, before the buyer adds to the cart.
- **Listings and cards:** the colour swatches on the card (`options` → `optionValues` → `swatch`), and the size and colour filters first. A second photo on hover only where the device can hover.

## Electronics, cameras and software

- **The energy class:** `energyClass` gives the `label`, the label's picture (`imageUrl`), and links to the label (`documentUrl`) and the product information sheet (`productSheetUrl`). Show the class next to the price, linking to the label, and link the sheet, on the product page and wherever the product is listed with a price.
- **Specifications** from `properties`, as a table, and comparison (`productComparison`) for the same kind of product.
- **Manuals and downloads** from `files`.
- **Software and digital goods:** `requiresShipping` is false; after purchase the customer finds the files in their account (`customer.downloads`).
- **Listings and cards:** the brand (`vendor`) and the energy class next to the price on the card; comparison (`productComparison`) from the card; filters by brand and by the merchant's specification facets.

## Home, garden, furniture and hardware

- **Dimensions and weight:** `dimensions` (length, width, height, unit) and the variant's `weight` and `weightUnit`.
- **Made to order:** `customizations` (the buyer's choices beyond the variant, with their prices), and a sold-out item with `statusType` `REQUEST`, which the store takes on request.
- **Delivery:** large items often have their own couriers and slots, which the platform's checkout offers once the cart is handed over (`cart.checkoutUrl`); never promise a delivery date or price the API did not give. `cartDeliveryQuote` and `cartDeliverySlots` are steps of the API's own checkout for other clients — the first stores prices on the cart and needs an address, the second a chosen courier — not the storefront's.
- **Listings and cards:** pictures large enough to judge a piece (two a row on a phone, three on a desktop rather than four); filters by the merchant's material and colour facets.

## Health and beauty

- **Ingredients** from `properties`, on the product page.
- **Subscriptions:** `sellingPlanGroups`, the repeat deliveries the merchant offers, when the store has them.
- **The unit price** when the product is sold by volume or weight (`unitPrice`, below).
- **Listings and cards:** the brand and the unit price on the card.

## Food and drink

- **The unit price:** `ProductVariant.unitPrice` with `unitPriceMeasurement` (the price per kg, per litre…). Show it next to the price, wherever the price is shown.
- **The food information** from `properties` and the description: ingredients, allergens, net quantity, storage, the producer, on the product page, before the purchase.
- **Delivery slots** for fresh goods are chosen in the platform's checkout; on the storefront, the minimum quantity (`minimumQuantity`).
- **Listings and cards:** the unit price on the card, and an add to cart on the card (`AddToCartButton`) for a product with one variant, for the buyer who orders the same again.

## Baby, toys and games

- **The age range** and warnings from `properties`, on the product page, before the purchase.
- **Bundles and sets:** `bundle` lists what a set contains.
- **Listings and cards:** filters by the merchant's age facet when there is one.

## Sporting goods

- Sizes and swatches as in fashion; specifications and comparison as in electronics.

## Pets

- **Repeat purchases:** subscriptions (`sellingPlanGroups`) and volume prices (`quantityDiscounts`).
- **The unit price** for food sold by weight.
- **Listings and cards:** the unit price on the card, and an add to cart on the card for a product with one variant.

## Vehicles and parts

- **Compatibility and the part number** from `properties` and the variant's `sku` and `barcode`.
- **Listings and cards:** the part number (`sku`) on the card.

## Books, media, office and art

- **The ISBN or EAN** from the variant's `barcode`; the publisher or maker as the brand (`vendorDetails`).
- **Digital editions** as in software.
- **Listings and cards:** the author or publisher (`vendorDetails`) on the card.

## A gap in the data

If a kind needs something the API does not return (a field, not a property the merchant could fill), do not work around it in the storefront: tell the user what is missing and why it matters, so it can be added to the API.
