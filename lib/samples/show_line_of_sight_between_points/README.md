# Show line of sight between points

Perform a line of sight analysis between two points in real time.

![Image of show line of sight between points](show_line_of_sight_between_points.png)

## Use case

A line of sight analysis can be used to assess whether a view is obstructed between an observer and a target. Obstructing features could either be natural, like topography, or man-made, like buildings. Consider an events planning company wanting to commemorate a national event by lighting sequential beacons across hill summits or roof tops. To guarantee a successful event, ensuring an unobstructed line of sight between neighboring beacons would allow each beacon to be activated as intended.

## How to use the sample

The sample loads with a preset observer and target location, linked by a colored line. A red segment on the line means the view between observer and target is obstructed, whereas green means the view is unobstructed.

Tap the scene to set the location of the observer. Long press to set the line-of-sight target location.

## How it works

1. Create an `AnalysisOverlay` and add it to the scene view.
2. Create a `LocationLineOfSight` with initial observer and target locations and add it to the analysis overlay.
3. Set `onTap` and `onLongPress` handler functions when creating the `ArcGISSceneView`. Use the `ArcGISSceneViewController.screenToBaseSurface(Offset screenOffset)` function to convert the screen offset to an `ArcGISPoint` on the scene.
   - In the `onTap` function, set the `LocationLineOfSight.observerLocation` property.
   - In the `onLongPress` function, set the `LocationLineOfSight.targetLocation` property.
4. The `AnalysisOverlay` will automatically update when either of the locations are updated.

## Relevant API

* AnalysisOverlay
* ArcGISSceneView
* LocationLineOfSight

## Tags

3D, line of sight, visibility, visibility analysis
