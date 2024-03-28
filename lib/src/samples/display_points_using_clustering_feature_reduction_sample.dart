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
    if (_map.loadStatus == LoadStatus.loaded && mounted) {
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
