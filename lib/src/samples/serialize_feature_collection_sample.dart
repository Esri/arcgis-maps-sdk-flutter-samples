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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:path_provider/path_provider.dart';

class SerializeFeatureCollectionSample extends StatefulWidget {
  const SerializeFeatureCollectionSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SerializeFeatureCollectionSampleState createState() =>
      SerializeFeatureCollectionSampleState();
}

class SerializeFeatureCollectionSampleState
    extends State<SerializeFeatureCollectionSample> {
  static final _spatialReference = SpatialReference.webMercator;

  final _mapViewController = ArcGISMapView.createController();
  late File _file;
  late FeatureCollection _featureCollection;
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
        onTap: _ready ? onTap : null,
      ),
    );
  }

  void onMapViewReady() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File('${directory.absolute.path}/feature_collection.json');
    _featureCollection = await deserializeFeatureCollection();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);

    map.initialViewpoint = Viewpoint.fromTargetExtent(
      Envelope.fromXY(
        xMin: -8917856.590171767,
        yMin: 903277.583136797,
        xMax: -8800611.655131537,
        yMax: 1100327.8941287803,
        spatialReference: _spatialReference,
      ),
    );

    map.operationalLayers
        .add(FeatureCollectionLayer.withFeatureCollection(_featureCollection));

    _mapViewController.arcGISMap = map;

    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) {
    final point = _mapViewController.screenToLocation(screen: localPosition);

    final table = _featureCollection.tables.first;
    table.addFeature(table.createFeature(geometry: point));
    serializeFutureCollection();
  }

  Future<FeatureCollection> deserializeFeatureCollection() async {
    FeatureCollection? featureCollection;

    try {
      if (await _file.exists()) {
        final json = await _file.readAsString();
        featureCollection = FeatureCollection.fromJsonString(json);

        if (featureCollection.tables.length != 1 ||
            featureCollection.tables.first.geometryType != GeometryType.point) {
          // misconfigured -- throw it away
          featureCollection = null;
        }
      }
    } catch (e) {
      // failed to load from file
    }

    if (featureCollection == null) {
      // could not load from file -- create a fresh collection
      featureCollection = FeatureCollection();
      final table = FeatureCollectionTable(
        fields: [],
        geometryType: GeometryType.point,
        spatialReference: _spatialReference,
      );
      featureCollection.tables.add(table);
    }

    featureCollection.tables.first.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.triangle,
        color: Colors.red,
        size: 10,
      ),
    );

    return featureCollection;
  }

  void serializeFutureCollection() {
    _file.writeAsString(_featureCollection.toJsonString());
  }
}
