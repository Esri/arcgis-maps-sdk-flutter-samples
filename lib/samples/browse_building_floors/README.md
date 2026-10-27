# Browse building floors

Display and browse through building floors from a floor-aware web map.

![Image of browse building floors](browse_building_floors.png)

## Use case

Having map data to aid indoor navigation in buildings with multiple floors such as airports, museums, or offices can be incredibly useful. For example, you may wish to browse through all available floor maps for an office in order to find the location of an upcoming meeting in advance.

## How to use the sample

Use the FloorFilter widget to browse different floor levels in the facility. Only the selected floor will be displayed.

## How it works

1. Create and load a floor-aware web map using the identifier of a `PortalItem`.
2. Call `refresh()` on the `FloorFilterController` to load the map and its floor information.
3. Check that the map has a `floorManager` property to ensure that the map is floor-aware.
4. Find the first site in `floorManager.sites`.
5. Find the first facility in that site's `site.facilities`.
6. Set `selectedSiteId` and `selectedFacilityId` on the `FloorFilterController` to select that facility, which automatically selects the first floor of the facility.

## Relevant API

* FloorManager

## About the data

This sample uses a [floor-aware web map](https://www.arcgis.com/home/item.html?id=f133a698536f44c8884ad81f80b6cfc7) that displays the floors of Building L on the Esri Redlands campus.

## Additional information

The `FloorManager` API also supports browsing different sites and facilities in addition to building floors.

Floor-awareness APIs support both maps and scenes. To learn more about floor-aware maps, read the [Configure floor-aware maps](https://pro.arcgis.com/en/pro-app/latest/help/data/indoors/configure-floor-aware-maps.htm) article.

## Tags

building, facility, floor, floor-aware, floors, ground floor, indoor, level, site, story
