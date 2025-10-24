# Filter building scene layer

Explore details of a building scene layer using filters.

![Image of a building scene layer](filter_building_scene_layer.png)

## Use case

Buildings in a building scene layer can be composed of sublayers containing internal and external details of the structure. Sublayers may include structural components like columns, architectural components like floors and windows, and electrical components. The sublayers of the building scene layer can be shown or hidden by using filters.

## How to use the sample

In the filter controls, select floor and category options to filter what parts of the building scene layer are displayed in the scene. Click on any of the building items to identify them.

## How it works

1. Create a scene.
2. Create an `ArcGISLocalSceneLayer` with the URL to a building scene layer service.
3. Add the layer to the scene's operational layers collection.

## Relevant API

* ArcGISLocalSceneLayer
* ArcGISScene

## About the data

This dataset contains more than 40,000 points representing world airports. Points are retrieved on demand by the scene layer as the user navigates the scene.

## Additional information

Point scene layers can also be retrieved from scene layer packages (.slpk) and mobile scene packages (.mspk).

## Tags

3D, building scene layer, layers
