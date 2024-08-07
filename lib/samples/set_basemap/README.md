# Set basemap

Change a map's basemap. A basemap is beneath all layers on a map and is used to provide visual reference for the operational layers.

![Image of set basemap](set_basemap.png)

## Use case

Basemaps should be selected contextually. For example, in maritime applications, it would be more appropriate to use a basemap of the world's oceans as opposed to a basemap of the world's streets.

## How to use the sample

Use the drawer to select the active basemap from the list of available basemaps.

## How it works

1. Create an `ArcGISMap` object.
2. Set the map to the `ArcGISMapViewController` object.
3. Choose a new basemap type and set it on the map.

## Relevant API

* ArcGISMap
* ArcGISMapViewController
* Basemap

## Tags

basemap, map
