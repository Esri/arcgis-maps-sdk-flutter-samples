# Display OGC API collection

Display an OGC API feature collection and query features while navigating the map view.

![Image of display OGC API collection](display_ogc_api_collection.png)

## Use case

When panning the map view, it may be necessary to query the OGC API feature table for additional features within the new visible extent.

## How to use the sample

Pan the map and observe how new features are loaded from the OGC API feature service.

## How it works

1. Create an `OgcFeatureCollectionTable` object using a URL to an OGC API feature service and a collection ID.
2. Set the feature table's `featureRequestMode` property to `FeatureRequestMode.manualCache`.
3. Call `OgcFeatureCollectionTable.load()`.
4. Create a `FeatureLayer` using the feature table and add it to the map view.
5. Every time the map view navigation completes:
   1. Create `QueryParameters`.
   2. Set the parameter's `geometry` property to the current extent of the map view.
   3. Set the parameter's `spatialRelationship` property to `SpatialRelationship.intersects`.
   4. Set the `maxFeatures` property to 5000 (some services have a low default value for maximum features).
   5. Call `OgcFeatureCollectionTable.populateFromService()` using the query parameters from the previous steps.

## Relevant API

* OgcFeatureCollectionTable
* QueryParameters

## About the data

The [Daraa, Syria test data](https://demo.ldproxy.net/daraa) is OpenStreetMap data converted to the Topographic Data Store schema of NGA.

## Additional information

See the [OGC API website](https://ogcapi.ogc.org/) for more information on the OGC API family of standards.

## Tags

feature, feature layer, feature table, OGC, OGC API, service, table, web
