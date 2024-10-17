# Change viewpoint

Set the map view to a new viewpoint.

![Image of change viewpoint](change_viewpoint.png)

## Use case

Programmatically navigate to a specified location in the map or scene. Use this to focus on a
particular point or area of interest.

## How to use the sample

The map view has several methods for setting its current viewpoint. Select a viewpoint from the UI
to see the viewpoint changed using that method.

## How it works

1. Create a new `ArcGISMapView` with an `ArcGISMapViewController`, and assign an `ArcGISMap` to
   the `ArcGISMapViewController.arcGISMap` property.
2. Change the map's `Viewpoint` using one of the available methods:

* Use `ArcGISMapViewController.setViewpointGeometry()` to set the viewpoint to a given `Geometry`.
* Use `ArcGISMapViewController.setViewpointCenter()` to center the viewpoint on a `ArcGISPoint` and
  set a distance from the ground using a scale.
* Use `ArcGISMapViewController.setViewpointAnimated()` to pan to a viewpoint over the specified
  length of time.

## Relevant API

* ArcGISMap
* ArcGISMapView
* ArcGISPoint
* Geometry
* Viewpoint

## Additional information

Below are some other ways to set a viewpoint:

* ArcGISMapViewController.setViewpoint
* ArcGISMapViewController.setViewpointRotation
* ArcGISMapViewController.setViewpointScale
* ArcGISMapViewController.setViewpointWithDurationAndCurve

## Tags

animate, extent, pan, rotate, scale, view, zoom
