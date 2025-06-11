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

class AddIntegratedMeshLayer extends StatefulWidget {
  const AddIntegratedMeshLayer({super.key});

  @override
  State<AddIntegratedMeshLayer> createState() => _AddIntegratedMeshLayerState();
}

class _AddIntegratedMeshLayerState extends State<AddIntegratedMeshLayer>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // A flag for when the scene view is ready.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISSceneView(
            controllerProvider: () => _sceneViewController,
            onSceneViewReady: onSceneViewReady,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  void onSceneViewReady()  {
    // Create a scene.
    _setupScene();

    setState(() => _ready = true);
  }

  void _setupScene() {
    // Create a scene.
    final scene = ArcGISScene.withBasemapStyle(
      BasemapStyle.arcGISImageryStandard,
    );
    // Create an ArcGISTiledElevationSource with the URI to an elevation service.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
     // Create an IntegratedMeshLayer with the URI to an integrated mesh layer scene service.
    final integratedMeshLayer = IntegratedMeshLayer.withUri(
      Uri.parse(
        'https://tiles.arcgis.com/tiles/z2tnIkrLQ2BRzr6P/arcgis/rest/services/Girona_Spain/SceneServer',
      ),
    );

    // Add the elevation source to surface to show terrain.
    scene.baseSurface.elevationSources.add(elevationSource);
    // Add the layer to the scene's operational layers.
    scene.operationalLayers.add(integratedMeshLayer);
    // Set the scene to the scene view controller.
    _sceneViewController.arcGISScene = scene;

    // Set controller viewpoint to camera.
    _sceneViewController.setViewpointCamera(Camera.withLatLong(
      latitude: 41.9906,
      longitude: 2.8259,
      altitude: 200,
      heading: 190,
      pitch: 65,
      roll: 0,
    ));
  }
}
