# Add feature layers

Display feature layers from various data sources.

![Image of add feature layers](add_feature_layers.png)

## Use case

Feature layers, like all layers, are visual representations of data and are used on a map or scene. In the case of feature layers, the underlying data is held in a feature table or feature service.

Feature services are useful for sharing vector GIS data with clients so that individual features can be queried, displayed, and edited. There are various online and offline methods to load feature services.

## How to use the sample

Tap the button on the toolbar to add feature layers, from different sources, to the map. Pan and zoom the map to view the feature layers.

## How it works

1. Set the basemap with a `BasemapStyle`.
2. Load a feature layer with a URL.  
    i. Create a `ServiceFeatureTable` from a URL.  
    ii. Create a `FeatureLayer` with the feature table.
3. Load a feature layer with a portal item.  
    i. Create a `PortalItem` with the portal and item ID.  
    ii. Create a `FeatureLayer` with the portal item and layer ID.
4. Load a feature layer with a geodatabase.  
    i. Instantiate and load a `Geodatabase` using the file name.  
    ii. Get the feature table from the geodatabase with the feature table's name.  
    iii. Create a `FeatureLayer` from the feature table.
5. Load a feature layer with a geopackage.  
    i. Instantiate and load a geopackage using its file name.  
    ii. Get the first `GeoPackageFeatureTable` from the `GeoPackageFeatureTables` list.  
    iii. Create a `FeatureLayer` from the feature table.
6. Add the feature layer to the map's `operationalLayers`.

## Relevant API

* FeatureLayer
* Geodatabase
* GeoPackage
* Portal
* ServiceFeatureTable

## About the data

This sample uses the [Naperville damage assessment service](https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer/0), [Trees of Portland portal item](https://www.arcgis.com/home/item.html?id=1759fd3e8a324358a0c58d9a687a8578), [Los Angeles Trailheads geodatabase](https://www.arcgis.com/home/item.html?id=cb1b20748a9f4d128dad8a87244e3e37), and [Aurora, Colorado GeoPackage](https://www.arcgis.com/home/item.html?id=68ec42517cdd439e81b036210483e8e7).

## Tags

feature, geodatabase, geopackage, layers, service, table
