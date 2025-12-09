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

class AddBuildingSceneLayer extends StatefulWidget {
  const AddBuildingSceneLayer({super.key});

  @override
  State<AddBuildingSceneLayer> createState() => _AddBuildingSceneLayerState();
}

class _AddBuildingSceneLayerState extends State<AddBuildingSceneLayer>
    with SampleStateSupport {
  // Create a controller for the local scene view.
  final _localSceneViewController = ArcGISLocalSceneView.createController();
  // A flag for when the local scene view is ready and controls can be used.
  var _ready = false;

  late final BuildingSublayer _overviewSublayer;
  late final BuildingSublayer _fullModelSublayer;
  var _showFullModel = false;

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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISLocalSceneView(
                    controllerProvider: () => _localSceneViewController,
                    onLocalSceneViewReady: onLocalSceneViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: toggleModelView,
                      child: Text(_showFullModel ? 'Overview' : 'Full Model'),
                    ),
                  ],
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

  Future<void> onLocalSceneViewReady() async {
    // Initialize the Scene.
    final scene = await _initializeScene();

    // Load the BuildingSceneLayer.
    final buildingSceneLayer = BuildingSceneLayer.withUri(
      Uri.parse(
        'https://www.arcgis.com/home/item.html?id=669f6279c579486eb4a0acc7eb59d7ca',
      ),
    );
    await buildingSceneLayer.load();

    // Add the BuildingSceneLayer to the Scene.
    scene.operationalLayers.add(buildingSceneLayer);

    // Extract the overview and full model sublayers
    _overviewSublayer = buildingSceneLayer.sublayers.firstWhere(
      (sublayer) => sublayer.name == 'Overview',
    );
    _fullModelSublayer = buildingSceneLayer.sublayers.firstWhere(
      (sublayer) => sublayer.name == 'Full Model',
    );

    // Add the Scene to the LocalSceneViewController.
    _localSceneViewController.arcGISScene = scene;

    // Set an initial viewpoint camera.
    final viewpointCamera = Camera.withLocation(
      location: ArcGISPoint(
        x: -13045109,
        y: 4036614,
        z: 511,
        spatialReference: SpatialReference.webMercator,
      ),
      heading: 343,
      pitch: 64,
      roll: 0,
    );
    _localSceneViewController.setViewpointCamera(viewpointCamera);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<ArcGISScene> _initializeScene() async {
    // Create a Scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(
      BasemapStyle.arcGISTopographic,
      viewingMode: SceneViewingMode.local,
    );

    // Add an ElevationSource to the Scene.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    return scene;
  }

  Future<void> toggleModelView() async {
    // Toggle the visibilities for the sublayers.
    _overviewSublayer.isVisible = _showFullModel;
    _fullModelSublayer.isVisible = !_showFullModel;

    // Set the state for the new full model visibility.
    setState(() => _showFullModel = !_showFullModel);
  }
}
