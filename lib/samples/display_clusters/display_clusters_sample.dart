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

class DisplayClustersSample extends StatefulWidget {
  const DisplayClustersSample({super.key});

  @override
  State<DisplayClustersSample> createState() => _DisplayClustersSampleState();
}

class _DisplayClustersSampleState extends State<DisplayClustersSample> {
  // create a map view controller
  final _mapViewController = ArcGISMapView.createController();
  late ArcGISMap _map;
  // create a flag to check if the map is ready
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        // create a column widget
        child: Column(
          children: [
            Expanded(
              // add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            Center(
              // create a button to toggle feature clustering
              child: ElevatedButton(
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
    // Get the power plants web map from the default portal.
    final portal = Portal.arcGISOnline();
    final portalItem = PortalItem.withPortalAndItemId(
        portal: portal, itemId: '8916d50c44c746c1aafae001552bad23');
    // load the portal item.
    await portalItem.load();
    // create a map from the portal item
    _map = ArcGISMap.withItem(portalItem);
    // set the map to the map view controller
    _mapViewController.arcGISMap = _map;
    // load the map
    await _map.load();
    // set the flag to true
    setState(() => _ready = true);
  }

  void toggleFeatureClustering() {
    // check if the map has operational layers and the first layer is a feature layer
    if (_map.operationalLayers.isNotEmpty &&
        _map.operationalLayers.first is FeatureLayer) {
      // get the first layer as a feature layer
      final featureLayer = _map.operationalLayers.first as FeatureLayer;
      // check if the feature layer has feature reduction
      if (featureLayer.featureReduction != null) {
        // toggle the feature reduction
        featureLayer.featureReduction!.enabled =
            !featureLayer.featureReduction!.enabled;
      }
    }
  }
}
