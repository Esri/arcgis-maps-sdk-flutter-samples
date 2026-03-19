# Show exploratory viewshed from point in scene

Perform an exploratory viewshed analysis from a defined vantage point.

![Image of show exploratory viewshed from point in scene](show_exploratory_viewshed_from_point_in_scene.png)

## Use case

An exploratory viewshed analysis is a type of visual analysis you can perform on a scene. The exploratory viewshed shows what can be seen from a given location. The output is an overlay with two different colors - one representing the visible areas (green) and the other representing the obstructed areas (red).

Note: This analysis is a form of "exploratory analysis", which means the results are calculated on the current scale of the data, and the results are generated very quickly but not persisted. If persisted analysis performed at the full resolution of the data is required, consider using a `ViewshedFunction` to perform a viewshed calculation instead.

## How to use the sample

Tap a location on the map to change the location of the exploratory viewshed observation point.

Tap the "Settings" button at the bottom of the screen to show the controls to change the exploratory viewshed settings. The rendered exploratory viewshed will update in real time as the values are adjusted.

## How it works

1. Create an `ExploratoryLocationViewshed` passing in the observer location, heading, pitch, horizontal/vertical angles, and min/max distances.
2. Set the property values on the viewshed instance for location, direction, range, and visibility properties.

## Relevant API

* AnalysisOverlay
* ArcGISSceneLayer
* ArcGISTiledElevationSource
* ExploratoryLocationViewshed
* ExploratoryViewshed

## About the data

The scene shows a [buildings layer in Brest, France](https://www.arcgis.com/home/item.html?id=b343e14455fe45b98a2c20ebbceec0b0) hosted on ArcGIS Online.

## Tags

3D, exploratory viewshed, frustum, scene, visibility analysis
