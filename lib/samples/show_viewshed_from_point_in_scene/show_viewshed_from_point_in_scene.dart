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

class ShowViewshedFromPointInScene extends StatefulWidget {
  const ShowViewshedFromPointInScene({super.key});

  @override
  State<ShowViewshedFromPointInScene> createState() =>
      _ShowViewshedFromPointInSceneState();
}

class _ShowViewshedFromPointInSceneState
    extends State<ShowViewshedFromPointInScene>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
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
            Column(
              children: [
                Expanded(
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                    onTap: onTap,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: performTask,
                      child: const Text('Perform Task'),
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

  Future<void> onSceneViewReady() async {
    // Get scene with basemap, surface, and initial viewpoint.
    final scene = _setupScene();

    // Add a buildings scene layer
    final buildingLayerUri = Uri.parse(
      'https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0',
    );
    final buildingsLayer = ArcGISSceneLayer.withUri(buildingLayerUri);
    scene.operationalLayers.add(buildingsLayer);

    // Add scene to view controller.
    _sceneViewController.arcGISScene = scene;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    // Do something with a tap.
    // ignore: avoid_print
    print('Tapped at $offset');
  }

  Future<void> performTask() async {
    setState(() => _ready = false);

    // Perform some task.
    // ignore: avoid_print
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));

    setState(() => _ready = true);
  }

  ArcGISScene _setupScene() {
    // Create a scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Setup the initial viewpoint for the scene.
    final camera = Camera.withLookAtPoint(
      lookAtPoint: ArcGISPoint(
        x: -4.50,
        y: 48.4,
        z: 100,
        spatialReference: SpatialReference.wgs84,
      ),
      distance: 200,
      heading: 20,
      pitch: 70,
      roll: 0,
    );
    scene.initialViewpoint = Viewpoint.withExtentCamera(
      targetExtent: camera.location,
      camera: camera,
    );

    // Add surface elevation to the scene.
    final surface = Surface();
    final worldElevationService = Uri.parse(
      'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
    );
    final elevationSource = ArcGISTiledElevationSource.withUri(
      worldElevationService,
    );
    surface.elevationSources.add(elevationSource);
    scene.baseSurface = surface;

    return scene;
  }
}
