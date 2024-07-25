# Show device location

Display your current position on the map, as well as switch between different types of auto pan modes.

![Image of show device location](show_device_location.png)

## Use case

When using a map within a GIS, it may be helpful for a user to know their own location within a map, whether that's to aid the user's navigation or to provide an easy means of identifying/collecting geospatial information at their location.

## How to use the sample

Tap the "Location Settings" button to open the settings. Toggle "Show Location" to turn on or off the location display. The "Auto-Pan Mode" menu has the following options to control how the viewpoint changes as the location changes:

* Off - Turns off `autoPanMode`.
* Recenter - Sets the `autoPanMode` to `recenter`.
* Navigation - Sets the `autoPanMode` to `navigation`.
* Compass - Sets the `autoPanMode` to `compassNavigation`.

## How it works

1. Create an `ArcGISMapViewController`.
2. Get the `LocationDisplay` object from the `locationDisplay` property on the controller.
3. Use `start()` and `stop()` on the `LocationDisplay` object as necessary.

## Relevant API

* ArcGISMap
* ArcGISMapViewController
* LocationDisplay
* LocationDisplay.autoPanMode

## Additional information

Location permissions are required for this sample.

## Tags

compass, GPS, location, map, mobile, navigation
