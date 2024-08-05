//
// Copyright 2024 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class AddFeatureCollectionLayerFromTable extends StatefulWidget {
  const AddFeatureCollectionLayerFromTable({super.key});
  @override
  State<AddFeatureCollectionLayerFromTable> createState() =>
      _AddFeatureCollectionLayerFromTableState();
}

class _AddFeatureCollectionLayerFromTableState
    extends State<AddFeatureCollectionLayerFromTable> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() {
    // Create a feature collection table for each of the geometry types Point, Polyline, and Polygon.
    final pointTable = createPointTable();
    final polylineTable = createPolylineTable();
    final polygonTable = createPolygonTable();

    // Create a new feature collection and add the feature collection tables.
    final featureCollection = FeatureCollection()
      ..tables.addAll([pointTable, polylineTable, polygonTable]);

    // Create a feature collection layer from the feature collection.
    final featureCollectionLayer =
        FeatureCollectionLayer.withFeatureCollection(featureCollection);

    // Create a map with a basemap style and initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans)
      ..initialViewpoint = Viewpoint.fromTargetExtent(
        Envelope.fromXY(
          xMin: -8917856.590171767,
          yMin: 903277.583136797,
          xMax: -8800611.655131537,
          yMax: 1100327.8941287803,
          spatialReference: SpatialReference(wkid: 102100),
        ),
      );

    // Add the feature collection layer to the map's operational layers.
    map.operationalLayers.add(featureCollectionLayer);

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;
  }

  // Create a feature collection table using a point geometry.
  FeatureCollectionTable createPointTable() {
    // Create a feature collection table for the geometry type with a list of fields and a spatial reference.
    final pointTable = FeatureCollectionTable(
      fields: [Field.text(name: 'Place', alias: 'Place Name', length: 50)],
      geometryType: GeometryType.point,
      spatialReference: SpatialReference(wkid: 4326),
    );

    // Set a simple renderer to style features from the table.
    pointTable.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.triangle,
        color: Colors.red,
        size: 10,
      ),
    );

    // Create a point.
    final point = ArcGISPoint(
      x: -79.497238,
      y: 8.849289,
      spatialReference: SpatialReference.wgs84,
    );

    // Create a feature with the point and add it to the table.
    final feature = pointTable.createFeature(
      attributes: {'Place': 'Current location'},
      geometry: point,
    );
    pointTable.addFeature(feature);

    return pointTable;
  }

  // Create a feature collection table using a polyline geometry.
  FeatureCollectionTable createPolylineTable() {
    // Create a feature collection table for the geometry type with a list of fields and a spatial reference.
    final polylineTable = FeatureCollectionTable(
      fields: [
        Field.text(name: 'Boundary', alias: 'Boundary Name', length: 50),
      ],
      geometryType: GeometryType.polyline,
      spatialReference: SpatialReference(wkid: 4326),
    );

    // Set a simple renderer to style features from the table.
    polylineTable.renderer = SimpleRenderer(
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dash,
        color: Colors.green,
        width: 3,
      ),
    );

    // Build a polyline.
    final polylineBuilder =
        PolylineBuilder.fromSpatialReference(SpatialReference(wkid: 4326));
    polylineBuilder.addPoint(
      ArcGISPoint(
        x: -79.497238,
        y: 8.849289,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    polylineBuilder.addPoint(
      ArcGISPoint(
        x: -80.035568,
        y: 9.432302,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    final polyline = polylineBuilder.toGeometry();

    // Create a feature using the polyline and add it to the table.
    final feature = polylineTable.createFeature(
      attributes: {'Boundary': 'AManAPlanACanalPanama'},
      geometry: polyline,
    );
    polylineTable.addFeature(feature);

    return polylineTable;
  }

  // Create a feature collection table using a polygon geometry.
  FeatureCollectionTable createPolygonTable() {
    // Create a feature collection table for the geometry type with a list of fields and a spatial reference.
    final polygonTable = FeatureCollectionTable(
      fields: [Field.text(name: 'Area', alias: 'Area Name', length: 50)],
      geometryType: GeometryType.polygon,
      spatialReference: SpatialReference(wkid: 4326),
    );

    // Set a simple renderer to style features from the table.
    polygonTable.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.diagonalCross,
        color: Colors.cyan,
        outline: SimpleLineSymbol(
          style: SimpleLineSymbolStyle.solid,
          color: Colors.blue,
          width: 2,
        ),
      ),
    );

    // Build a polygon.
    final polygonBuilder =
        PolygonBuilder.fromSpatialReference(SpatialReference(wkid: 4326));
    polygonBuilder.addPoint(
      ArcGISPoint(
        x: -79.497238,
        y: 8.849289,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    polygonBuilder.addPoint(
      ArcGISPoint(
        x: -79.337936,
        y: 8.638903,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    polygonBuilder.addPoint(
      ArcGISPoint(
        x: -79.11409,
        y: 8.895422,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    final polygon = polygonBuilder.toGeometry();

    // Create a feature using the polygon and add it to the table.
    final feature = polygonTable.createFeature(
      attributes: {'Area': 'Restricted area'},
      geometry: polygon,
    );
    polygonTable.addFeature(feature);

    return polygonTable;
  }
}
