# Show device location history

Display your device's location history on the map.

![Image of show device location history](show_device_location_history.png)

## Use case

You can track device location history and display it as lines and points on the map. The history can be used to visualize how the user moved through the world, to retrace their steps, or to create new feature geometry. An unmapped trail, for example, could be added to the map using this technique.

## How to use the sample

Tap 'Start Tracking' to start tracking your location, which will appear as points on the map. A line will connect the points for easier visualization. Tap 'Stop Tracking' to stop updating the location history. This sample uses a simulated data source to allow the sample to be useful on desktop/non-mobile devices. To track a user's real position, use the `LocationDataSource` instead.

## How it works

1. Create a graphics overlay to show each point and another graphics overlay for displaying the route line.
2. Create a `SimulatedLocationDataSource` and initialize it with a polyline. Start the `SimulatedLocationDataSource` to begin receiving location updates.
 - NOTE: To track a user's real position, use `LocationDataSource` instead.
3. Subscribe to the `onLocationChanged` event to handle location updates.
4. Every time the location updates, store that location, display a point on the map, and recreate the route line.

## Relevant API

* LocationDataSource
* LocationDisplay
* LocationDisplayAutoPanMode
* PolylineBuilder
* SimpleLineSymbol
* SimpleMarkerSymbol
* SimpleRenderer
* SimulatedLocationDataSource
* Graphic
* GraphicsOverlay

## About the data

A custom set of points is used to create a `Polyline` and initialize a `SimulatedLocationDataSource`. This simulated location data source enables easier testing and allows the sample to be used on devices without an actively updating GPS signal.

## Tags

bread crumb, breadcrumb, GPS, history, movement, navigation, real-time, trace, track, trail
