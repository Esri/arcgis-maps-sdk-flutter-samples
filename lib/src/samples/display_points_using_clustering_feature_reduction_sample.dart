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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class DisplayPointsUsingClusteringFeatureReductionSample
    extends StatefulWidget {
  const DisplayPointsUsingClusteringFeatureReductionSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  DisplayPointsUsingClusteringFeatureReductionSampleState createState() =>
      DisplayPointsUsingClusteringFeatureReductionSampleState();
}

class DisplayPointsUsingClusteringFeatureReductionSampleState
    extends State<DisplayPointsUsingClusteringFeatureReductionSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _map = ArcGISMap.withUri(
    Uri.parse(
        'https://www.arcgis.com/home/item.html?id=8916d50c44c746c1aafae001552bad23'),
  )!;

  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _ready ? toggleFeatureClustering : null,
                child: const Text('Toggle feature clustering'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    _mapViewController.arcGISMap = _map;
    await _map.load();
    if (_map.loadStatus == LoadStatus.loaded) {
      setState(() => _ready = true);
    }
  }

  void toggleFeatureClustering() {
    if (_map.operationalLayers.isNotEmpty &&
        _map.operationalLayers.first is FeatureLayer) {
      final featureLayer = _map.operationalLayers.first as FeatureLayer;
      if (featureLayer.featureReduction != null) {
        featureLayer.featureReduction!.enabled =
            !featureLayer.featureReduction!.enabled;
      }
    }
  }
}
