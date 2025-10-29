# Filter building scene layer

Explore details of a building scene layer using filters.

![Image of a building scene layer](filter_building_scene_layer.png)

## Use case

Buildings in a building scene layer can be composed of sublayers containing internal and external details of the structure. Sublayers may include structural components like columns, architectural components like floors and windows, and electrical components. The sublayers of the building scene layer can be shown or hidden by using filters.

## How to use the sample

In the filter controls, select floor and category options to filter what parts of the building scene layer are displayed in the scene. Click on any of the building items to identify them.

## How it works

1. Create an `ArcGISScene` with the URL to a building scene layer service.
2. Create an `ArcGISLocalSceneView` and add the scene.
3. Extract the `BuildingSceneLayer` from the scene.
4. Tap the "Scene Settings" button to view the filtering options.
5. Select a floor from the "Floor" dropdown to view the internal details of each floor.
6. Expand the categories to show or hide individual items in the building model. The entire category may be show or hidden as well.

## Relevant API

* ArcGISLocalSceneView
* ArcGISScene
* BuildingFilter
* BuildingFilterBlock
* BuildingSceneLayer

## About the data

This Building Scene Layer represents the new Building E on the Esri Campus in Redlands CA.
The Revit BIM model was brought into ArcGIS using the BIM capabilities in ArcGIS Pro and published to the web as Building Scene Layer.

## Tags

3D, building scene layer, layers
