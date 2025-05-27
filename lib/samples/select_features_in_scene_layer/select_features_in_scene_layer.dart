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
      'https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0',
    ),
  );

  // A flag for when the scene view is ready.
  var _ready = false;

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
      latitude: 48.38282,
      longitude: -4.49779,
      altitude: 40,
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
    // Clear any previously selected feature.
    _sceneLayer.clearSelection();

    // Identify feature at the tapped screen location.
    final identifyLayerResult = await _sceneViewController.identifyLayer(
      _sceneLayer,
      screenPoint: offset,
      tolerance: 22,
    );

    // From the resulting IdentifyLayerResult, get the list of identified GeoElements with result.geoElements.
    final geoElements = identifyLayerResult.geoElements;

    // Get the first element in the list, checking that it is a feature.
    if (geoElements.isEmpty || geoElements.first is! ArcGISFeature) return;

    final feature = geoElements.first as ArcGISFeature;
    // Call sceneLayer.selectFeature(feature) to select it.
    _sceneLayer.selectFeature(feature);
  }
}
