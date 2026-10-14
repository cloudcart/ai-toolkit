# By kind of store

What a storefront shows for each kind of store, built from what the Storefront API already returns. Ask the user which kind the store is, or read it from the catalogue. The merchant chooses the store's kinds in the admin, from the top level of Google's product taxonomy. Most stores are more than one kind: apply each section that fits.

Two rules hold for every kind:

- **The data is the merchant's.** Show what the API returns, and show nothing when a field is empty. Never invent a value, a default or a placeholder that looks like data: no made-up size chart, energy class or composition.
- **What has no field of its own lives in `properties`.** `Product.properties` (`name`, `values`) holds the merchant's product properties: fibre composition, ingredients, allergens, specifications, warranty, age range, compatibility. Render them as the product's specification table, in the merchant's order. Do not parse them for meaning; a property the merchant named is shown under that name.

## Every kind

- The product's gallery from `media`, in the merchant's order, with the selected variant's pictures first (`mediaIds`); a YouTube video plays in place (`ExternalVideo`).
- The price with `<Money>` from `formatted`; a discount from `discount` and `compareAtPrice`, shown only as `ProductPrice` shows it (`hideDiscountPrice` hides it).
- Availability from `availableForSale` and the variant's `statusName` (the store's own words: "in stock", "on request"…), and back-in-stock sign-up (`productBackInStockSubscribe`) when a variant is sold out and the store offers it.
- Reviews (`reviewSummary`, `reviews`) when the store runs them: both are empty otherwise.
- Volume prices (`quantityDiscounts`), the minimum quantity (`minimumQuantity`), and consumer credit (`creditOffers`) when the merchant offers them.
- Stock in the merchant's physical stores (`stockByStore`) when the store has them.

## Fashion: apparel, accessories, shoes, bags

- **Options as swatches:** a colour option shows its `swatch` (`color` or `image`), and a size option shows its values in the merchant's order. A sold-out combination stays visible but disabled (`getProductOptions` gives each value's `available` and `exists`).
- **The size chart:** `sizeChart` names a content page (`pageHandle`). Open it next to the size option, in a dialog or a link; show nothing when there is none.
- **The variant's pictures** change with the colour (`mediaIds`).
- **Fibre composition and care** from `properties`, on the product page, before the buyer adds to the cart.

## Electronics, cameras and software

- **The energy class:** `energyClass` gives the `label`, the label's picture (`imageUrl`), and links to the label (`documentUrl`) and the product information sheet (`productSheetUrl`). Show the class next to the price, linking to the label, and link the sheet, on the product page and wherever the product is listed with a price.
- **Specifications** from `properties`, as a table, and comparison (`productComparison`) for the same kind of product.
- **Manuals and downloads** from `files`.
- **Software and digital goods:** `requiresShipping` is false; after purchase the customer finds the files in their account (`customer.downloads`).

## Home, garden, furniture and hardware

- **Dimensions and weight:** `dimensions` (length, width, height, unit) and the variant's `weight` and `weightUnit`.
- **Made to order:** `customizations` (the buyer's choices beyond the variant, with their prices), and a sold-out item with `statusType` `REQUEST`, which the store takes on request.
- **Delivery:** large items often have their own couriers and slots. The cart's delivery quote and options come from the API (`cartDeliveryQuote`, `cartDeliverySlots`); never promise a delivery date the API did not give.

## Health and beauty

- **Ingredients** from `properties`, on the product page.
- **Subscriptions:** `sellingPlanGroups`, the repeat deliveries the merchant offers, when the store has them.
- **The unit price** when the product is sold by volume or weight (`unitPrice`, below).

## Food and drink

- **The unit price:** `ProductVariant.unitPrice` with `unitPriceMeasurement` (the price per kg, per litre…). Show it next to the price, wherever the price is shown.
- **The food information** from `properties` and the description: ingredients, allergens, net quantity, storage, the producer, on the product page, before the purchase.
- **Delivery slots** (`cartDeliverySlots`) for fresh goods, and the minimum quantity (`minimumQuantity`).

## Baby, toys and games

- **The age range** and warnings from `properties`, on the product page, before the purchase.
- **Bundles and sets:** `bundle` lists what a set contains.

## Sporting goods

- Sizes and swatches as in fashion; specifications and comparison as in electronics.

## Pets

- **Repeat purchases:** subscriptions (`sellingPlanGroups`) and volume prices (`quantityDiscounts`).
- **The unit price** for food sold by weight.

## Vehicles and parts

- **Compatibility and the part number** from `properties` and the variant's `sku` and `barcode`.

## Books, media, office and art

- **The ISBN or EAN** from the variant's `barcode`; the publisher or maker as the brand (`vendorDetails`).
- **Digital editions** as in software.

## A gap in the data

If a kind needs something the API does not return (a field, not a property the merchant could fill), do not work around it in the storefront: tell the user what is missing and why it matters, so it can be added to the API.
