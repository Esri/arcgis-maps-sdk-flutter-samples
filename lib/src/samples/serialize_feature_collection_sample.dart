//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
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
