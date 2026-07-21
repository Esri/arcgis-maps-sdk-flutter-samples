// Copyright 2026 Esri
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

class Add3dTilesLayer extends StatefulWidget {
  const Add3dTilesLayer({super.key});

  @override
  State<Add3dTilesLayer> createState() => _Add3dTilesLayerState();
}

class _Add3dTilesLayerState extends State<Add3dTilesLayer>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a scene view to the widget tree and set the controller.
      body: ArcGISSceneView(
        controllerProvider: () => _sceneViewController,
        onSceneViewReady: onSceneViewReady,
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    // Add the scene to the view controller.
    _sceneViewController.arcGISScene = _setupScene();
  }

  ArcGISScene _setupScene() {
    // Create a scene.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISDarkGray);

    // Set the scene's initial viewpoint.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: Camera.withLatLong(
        latitude: 48.84553,
        longitude: 9.16275,
        altitude: 350,
        heading: 0,
        pitch: 75,
        roll: 0,
      ),
    );

    // Add surface elevation to the scene.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    // Add 3D tiles to the scene.
    final stuttgart3Dtiles = Ogc3DTilesLayer.withUri(
      Uri.parse(
        'https://tiles.arcgis.com/tiles/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Stuttgart/3DTilesServer/tileset.json',
      ),
    );
    scene.operationalLayers.add(stuttgart3Dtiles);

    return scene;
  }
}
