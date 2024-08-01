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

class DisplayClusters extends StatefulWidget {
  const DisplayClusters({super.key});

  @override
  State<DisplayClusters> createState() => _DisplayClustersState();
}

class _DisplayClustersState extends State<DisplayClusters>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  late ArcGISMap _map;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Center(
                  // Create a button to toggle feature clustering.
                  child: ElevatedButton(
                    onPressed: toggleFeatureClustering,
                    child: const Text('Toggle feature clustering'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
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
    // Load the portal item.
    await portalItem.load();
    // Create a map from the portal item.
    _map = ArcGISMap.withItem(portalItem);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = _map;
    // Load the map.
    await _map.load();
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void toggleFeatureClustering() {
    // Check if the map has operational layers and the first layer is a feature layer.
    if (_map.operationalLayers.isNotEmpty &&
        _map.operationalLayers.first is FeatureLayer) {
      // Get the first layer as a feature layer.
      final featureLayer = _map.operationalLayers.first as FeatureLayer;
      // Check if the feature layer has feature reduction.
      if (featureLayer.featureReduction != null) {
        // Toggle the feature reduction.
        featureLayer.featureReduction!.enabled =
            !featureLayer.featureReduction!.enabled;
      }
    }
  }
}
