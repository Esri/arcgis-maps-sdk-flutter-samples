# Add feature collection layer from table

Create a Feature Collection Layer from a Feature Collection Table, and add it to a map.

![Image of add feature collection layer from table](add_feature_collection_layer_from_table.png)

## Use case

A Feature Collection allows easily importing external data (such as CSV files), as well as creating custom schema for data that is in non-standardized format. This data can then be used to populate a Feature Collection Table, and displayed in a Feature Collection Layer using the attributes and geometries provided in the external data source. For example, an electricity supplier could use this functionality to visualize existing location data of coverage areas (polygons), power stations (points), transmission lines (polylines), and others.

## How to use the sample

When launched, this sample displays a `FeatureCollectionLayer` with a `Point`, `Polyline` and `Polygon` geometry. Pan and zoom to explore the scene.

## How it works

1. Create a `FeatureCollectionTable` for the `GeometryType`s `Point`, `Polyline`, and `Polygon`, using `FeatureCollectionTable(fields, geometryType, spatialReference)`. Pass in a list of `Field` objects to represent the table's schema, the `GeometryType` and a `SpatialReference`.
2. Assign a `SimpleRenderer` to each table to render any `Feature`s from that table using the `Symbol` that was set.
3. Use the `FeatureCollectionTable.createFeature(attributes, geometry)` method to create a feature from the feature collection table, passing an attribute and geometry for that feature.
4. Add new features to the table, `FeatureCollectionTable.addFeature(feature)`.
5. Add the feature collection table to the feature collection, `FeatureCollection.tables.add(featureCollectionTable)`.
6. Create a `FeatureCollectionLayer` using the feature collection, `FeatureCollectionLayer.withFeatureCollection(featureCollection)`.
7. Add the feature collection layer to the map, `ArcGISMap.operationalLayers.add(featureCollectionLayer)`.

## Relevant API

* Feature
* FeatureCollection
* FeatureCollectionLayer
* FeatureCollectionTable
* Field
* SimpleRenderer

## Tags

collection, feature, layers, table
