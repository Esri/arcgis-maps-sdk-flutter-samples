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
  final _sceneLayer = ArcGISSceneLayer.withUri(
    Uri.parse(
      'https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Berlin/SceneServer/layers/0',
    ),
  );

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
    // Create a scene with Topographic basemap.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // Create camera with initial latitude and longitude (GBP College, Berlin).
    final camera = Camera.withLatLong(
      latitude: 52.52003000,
      longitude: 13.40489000,
      altitude: 200,
      heading: 41.65,
      pitch: 71.2,
      roll: 0,
    );

    // Set the initial viewpoint to camera position at point.
    _sceneViewController.setViewpoint(
      Viewpoint.withExtentCamera(targetExtent: camera.location, camera: camera),
    );

    // Create a surface and add an elevation source.
    final surface = Surface();
    surface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );
    // Set the surface to scene.
    scene.baseSurface = surface;

    await _sceneLayer.load();
    // Add buildings scene layer to the scene.
    scene.operationalLayers.add(_sceneLayer);

    // Set the scene to scene view controller.
    _sceneViewController.arcGISScene = scene;

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
