// Copyright 2025 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class SelectFeaturesInSceneLayer extends StatefulWidget {
  const SelectFeaturesInSceneLayer({super.key});

  @override
  State<SelectFeaturesInSceneLayer> createState() =>
      _SelectFeaturesInSceneLayerState();
}

class _SelectFeaturesInSceneLayerState extends State<SelectFeaturesInSceneLayer>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // Define an ArcGISSceneLayer.
  late ArcGISSceneLayer _sceneLayer;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag to prevent multiple simultaneous identify operations.
  var _isIdentifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            ArcGISSceneView(
              controllerProvider: () => _sceneViewController,
              onSceneViewReady: onSceneViewReady,
              onTap: onTap,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with from the uri.
    final scene = ArcGISScene.withUri(
      Uri.parse(
        'https://www.arcgis.com/home/item.html?id=31874da8a16d45bfbc1273422f772270',
      ),
    );
    // Load the scene.
    await scene!.load();
    // Set the scene to ArcGISSceneViewController
    _sceneViewController.arcGISScene = scene;

    // Get the operational layers from ArcGISScene
    final operationalLayers = scene.operationalLayers;
    // There are two layers from the provided Berlin, Germany Scene. We need the ArcGISSceneLayer
    _sceneLayer =
        operationalLayers.firstWhere(
              (layer) => layer.runtimeType == ArcGISSceneLayer,
            )
            as ArcGISSceneLayer;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset offset) async {
    // If an identify operation is already in progress, ignore this tap.
    if (_isIdentifying) return;

    // Set the flag to indicate an identify operation is in progress.
    _isIdentifying = true;

    try {
      // Clear any previously selected features.
      _sceneLayer.clearSelection();

      // Identify features at the tapped screen location.
      final identifyLayerResult = await _sceneViewController.identifyLayer(
        _sceneLayer,
        screenPoint: offset,
        tolerance: 22,
      );

      // Filter the identified GeoElements to only include features.
      final features =
          identifyLayerResult.geoElements.whereType<Feature>().toList();

      // If no features were identified, clear any existing selection.
      if (features.isEmpty) {
        _sceneLayer.clearSelection();
      } else {
        // Otherwise, select the identified features to highlight them.
        _sceneLayer.selectFeatures(features);
      }
    } finally {
      // Reset the flag to allow future identify operations.
      _isIdentifying = false;
    }
  }
}
