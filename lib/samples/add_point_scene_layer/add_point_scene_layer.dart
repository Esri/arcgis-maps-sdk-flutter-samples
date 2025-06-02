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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class AddPointSceneLayer extends StatefulWidget {
  const AddPointSceneLayer({super.key});

  @override
  State<AddPointSceneLayer> createState() => _AddPointSceneLayerState();
}

class _AddPointSceneLayerState extends State<AddPointSceneLayer>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  late StreamSubscription<LoadStatus> _loadStatusSubscription;

  @override
  void dispose() {
    super.dispose();
    _loadStatusSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  void onSceneViewReady() {
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);
    _sceneViewController.arcGISScene = scene;
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    final surface = Surface()
      ..elevationSources.add(elevationSource);
      
    scene.baseSurface = surface;
    // Add a point scene layer to the scene.
    final pointSceneLayer = ArcGISSceneLayer.withUri(
      Uri.parse(
        'https://tiles.arcgis.com/tiles/V6ZHFr6zdgNZuVG0/arcgis/rest/services/Airports_PointSceneLayer/SceneServer/layers/0',
      ),
    );
    scene.operationalLayers.add(pointSceneLayer);
    _loadStatusSubscription = pointSceneLayer.onLoadStatusChanged.listen((status) {
      if (status == LoadStatus.loaded) {
        setState(() => _ready = true);
      }
    });
  }
}
