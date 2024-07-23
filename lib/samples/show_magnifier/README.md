# Show magnifier

Tap and hold on a map to show a magnifier.

![Image of show magnifier](show_magnifier.png)

## Use case

Due to the limited screen size of some mobile devices, it may be difficult to identify individual features on a map where there is a high density of information, or the scale is very small. This can be the case when a mobile device is used for navigation, and the user wishes to magnify a particular area to better identify a road intersection.

## How to use the sample

Tap and hold on the map to show a magnifier, then drag across the map to move the magnifier. You can also pan the map while holding the magnifier, by dragging the magnifier to the edge of the map.

## How it works

1. Create a new `ArcGISMapView` with an `ArcGISMapViewController`, and assign an `ArcGISMap` to the `ArcGISMapViewController.arcGISMap` property.
2. Enable the magnifier using by setting the `ArcGISMapViewController.magnifiedEnabled` property to `true`. This will set the magnifier to be shown on the `ArcGISMap` when the user performs a long press gesture. Note: The default value is `false`.
3. Optionally, set the `ArcGISMapViewController.allowMagnifierToPanMap` property to `true` to allow the map to be panned automatically when the magnifier gets near the edge of the `ArcGISMap`. Note: The default value is `true`.

## Relevant API

* ArcGISMap
* ArcGISMapView
* ArcGISMapViewController
* ArcGISMapViewController.allowMagnifierToPanMap
* ArcGISMapViewController.magnifiedEnabled

## Tags

magnify, map, zoom
