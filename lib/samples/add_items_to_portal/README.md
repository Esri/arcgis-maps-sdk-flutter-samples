# Add items to portal

This sample demonstrates how to add and delete items in a user's portal.

![Image of add items to portal](add_items_to_portal.png)

## Use case

Portals allow you to share and publish data with others. This sample creates a CSV item and uploads it to ArcGIS Online.

## How to use the sample

1. Tap the "Authenticate Portal" button and sign into your ArcGIS Online account.
2. Tap the "Add Item" button to add the CSV to your portal.
3. Tap the "Delete Item" button to delete that item from your portal.

## How it works

1. Create and load an authenticated `Portal`.
2. Create a `PortalItem` of type `CSV`.
3. Add the item with `PortalUser.addPortalItem` and URL content parameters.
4. Delete the item with `PortalUser.deletePortalItem`.

### fixme steps

## Relevant API

* Portal
* PortalItem
* PortalUser.addPortalItem
* PortalUser.deletePortalItem

## Tags

add item, cloud, portal
