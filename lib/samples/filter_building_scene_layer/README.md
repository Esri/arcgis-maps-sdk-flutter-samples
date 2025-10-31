# Filter building scene layer

Explore details of a building scene by using filters and sublayer visiblity.

![Image of a building scene layer](filter_building_scene_layer.png)

## Use case

Buildings in a building scene layer are composed of sublayers containing internal and external details of the structure. Sublayers may include structural components like columns, architectural components like floors and windows, and electrical components. The features in the building scene layer can be filtered using building filters. These filters are built using filter blocks, which can be used to define a set of conditions to customize the filter. In addition, toggling the visibility of each sublayer can be helpful to show or hide parts of the entire sublayer. Individual features of the building can be selected to view the feature's attributes.

## How to use the sample

In the filter controls, select floor and category options to filter what parts of the building scene layer are displayed in the scene. Click on any of the building features to identify them.

## How it works

1. Create an `ArcGISScene` with the URL to a building scene layer service.
2. Create an `ArcGISLocalSceneView` and add the scene.
3. Retrieve the `BuildingSceneLayer` from the scene's operational layers.
4. Click the "Scene Settings" button to view the filtering options.
5. Select a floor from the "Floor" dropdown to view the internal details of each floor or "All" to view the entire model.
6. Expand the categories to show or hide individual items in the building model. The entire category may be shown or hidden as well.
7. Click on any of the building features to view the attributes of the feature.

## Relevant API

* ArcGISLocalSceneView
* ArcGISScene
* BuildingComponentSublayer
* BuildingFilter
* BuildingFilterBlock
* BuildingSceneLayer

## About the data

This building scene layer represents Building E on the Esri Campus in Redlands CA.

The Revit BIM model was brought into ArcGIS using the BIM capabilities in ArcGIS Pro and published to the web as a Building Scene Layer.

## Tags

3D, building scene layer, layers
