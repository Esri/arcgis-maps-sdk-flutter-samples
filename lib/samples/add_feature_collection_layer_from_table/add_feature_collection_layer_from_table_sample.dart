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

class AddFeatureCollectionLayerFromTableSample extends StatefulWidget {
  const AddFeatureCollectionLayerFromTableSample({super.key});
  @override
  State<AddFeatureCollectionLayerFromTableSample> createState() =>
      _AddFeatureCollectionLayerFromTableSampleState();
}

class _AddFeatureCollectionLayerFromTableSampleState
    extends State<AddFeatureCollectionLayerFromTableSample>
    with SampleStateSupport {
  final _featureCollection = FeatureCollection();
  final _mapViewController = ArcGISMapView.createController();

  _AddFeatureCollectionLayerFromTableSampleState() {
    createPointTable();
    createPolylineTable();
    createPolygonTable();
  }

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);

    map.initialViewpoint = Viewpoint.fromTargetExtent(
      Envelope.fromXY(
        xMin: -8917856.590171767,
        yMin: 903277.583136797,
        xMax: -8800611.655131537,
        yMax: 1100327.8941287803,
        spatialReference: SpatialReference(wkid: 102100),
      ),
    );

    map.operationalLayers
        .add(FeatureCollectionLayer.withFeatureCollection(_featureCollection));

    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }

  void createPointTable() {
    final pointTable = FeatureCollectionTable(
      fields: [
        Field.text(name: 'Place', alias: 'Place Name', length: 50),
      ],
      geometryType: GeometryType.point,
      spatialReference: SpatialReference(wkid: 4326),
    );

    pointTable.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.triangle,
        color: Colors.red,
        size: 10,
      ),
    );

    final feature = pointTable.createFeature(
      attributes: {
        'Place': 'Current location',
      },
      geometry: ArcGISPoint(
        x: -79.497238,
        y: 8.849289,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    pointTable.addFeature(feature);

    _featureCollection.tables.add(pointTable);
  }

  void createPolylineTable() {
    final linesTable = FeatureCollectionTable(
      fields: [
        Field.text(name: 'Boundary', alias: 'Boundary Name', length: 50),
      ],
      geometryType: GeometryType.polyline,
      spatialReference: SpatialReference(wkid: 4326),
    );

    linesTable.renderer = SimpleRenderer(
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dash,
        color: Colors.green,
        width: 3,
      ),
    );

    final builder =
        PolylineBuilder.fromSpatialReference(SpatialReference(wkid: 4326));
    builder.addPoint(
      ArcGISPoint(
        x: -79.497238,
        y: 8.849289,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    builder.addPoint(
      ArcGISPoint(
        x: -80.035568,
        y: 9.432302,
        spatialReference: SpatialReference.wgs84,
      ),
    );

    final feature = linesTable.createFeature(
      attributes: {
        'Boundary': 'AManAPlanACanalPanama',
      },
      geometry: builder.toGeometry(),
    );
    linesTable.addFeature(feature);

    _featureCollection.tables.add(linesTable);
  }

  void createPolygonTable() {
    final polygonTable = FeatureCollectionTable(
      fields: [
        Field.text(name: 'Area', alias: 'Area Name', length: 50),
      ],
      geometryType: GeometryType.polygon,
      spatialReference: SpatialReference(wkid: 4326),
    );

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

    final builder =
        PolygonBuilder.fromSpatialReference(SpatialReference(wkid: 4326));
    builder.addPoint(
      ArcGISPoint(
        x: -79.497238,
        y: 8.849289,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    builder.addPoint(
      ArcGISPoint(
        x: -79.337936,
        y: 8.638903,
        spatialReference: SpatialReference.wgs84,
      ),
    );
    builder.addPoint(
      ArcGISPoint(
        x: -79.11409,
        y: 8.895422,
        spatialReference: SpatialReference.wgs84,
      ),
    );

    final feature = polygonTable.createFeature(
      attributes: {
        'Area': 'Restricted area',
      },
      geometry: builder.toGeometry(),
    );
    polygonTable.addFeature(feature);

    _featureCollection.tables.add(polygonTable);
  }
}
