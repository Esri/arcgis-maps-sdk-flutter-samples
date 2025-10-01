# Display local scene

Display a local scene with a topographic surface and 3d buildings clipped to a local area.

![Image of display local scene](display_local_scene.png)

## Use case

A local scene view is a user interface that displays 3d basemaps and layers. Unlike a global scene, a local scene can use any `SpatialReference` and can be clipped to a specific area. The view controls the area of the scene that is visible, supports user interactions such as pan and zoom, and provides access to the underlying layer data in the local scene.

## How to use the sample

When loaded, the sample will display a local scene clipped to a extent. Pan and zoom to explore the scene.

## How it works

1. Create a scene object with the `arcGISTopographic` basemap style and `local` scene viewing mode.
2. Create an `ArcGISTiledElevationSource` object and add it to the local scene's base surface.
3. Create an `ArcGISSceneLayer` with 3d buildings and add it to the local scene's operational layers.
4. Create and apply a clipping area for the local scene and enable clipping.
5. Create a `LocalSceneView` object to display the map.
6. Set the initial viewpoint for the local scene.
7. Set the local scene to the local scene view.

## Relevant API

* ArcGISSceneLayer
* ArcGISTiledElevationSource
* LocalSceneView
* Scene

## Tags

3D, basemap, elevation, scene, surface
