# Set surface navigation constraint

See through terrain in a scene and move the camera underground.

![Image of set surface navigation constraint](set_surface_navigation_constraint.png)

## Use case

By default, a scene's terrain is fully opaque and the camera cannot go underground. To see underground features such as pipes in a utility network, you can lower the opacity of the terrain surface and set the navigation constraint on the surface to allow underground navigation.

## How to use the sample

The sample loads a scene with underground features. Pan and zoom to explore the scene. Observe how the opacity of the base surface is reduced and the navigation constraint is removed, allowing you to pan and zoom through the base surface.

## How it works

1. Display an `ArcGISScene` in an `ArcGISSceneView` which contains layers with underground features.
2. To see underground, get the scene's base surface and set its opacity to a value between 0 and 1.
3. To allow the camera to go underground, set the surface's navigation constraint to `NavigationConstraint.none`.

## Relevant API

* Surface
* Surface.navigationConstraint

## About the data

This data is a point scene layer showing underground wellbore paths (green polylines) and seismic events (brown points).

## Tags

3D, subsurface, underground, utilities
