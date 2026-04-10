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

class AddSceneLayerFromService extends StatefulWidget {
  const AddSceneLayerFromService({super.key});

  @override
  State<AddSceneLayerFromService> createState() =>
      _AddSceneLayerFromServiceState();
}

class _AddSceneLayerFromServiceState extends State<AddSceneLayerFromService>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a scene view to the widget tree and set a controller.
      body: ArcGISSceneView(
        controllerProvider: () => _sceneViewController,
        onSceneViewReady: onSceneViewReady,
      ),
    );
  }

  void onSceneViewReady() {
    // Create a scene with the imagery basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Add surface elevation to the scene.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    // Add a scene layer from a service URL.
    final sceneLayer = ArcGISSceneLayer.withUri(
      Uri.parse(
        'https://basemaps3d.arcgis.com/arcgis/rest/services/Esri3D_Buildings_v1/SceneServer',
      ),
    );
    scene.operationalLayers.add(sceneLayer);

    // Create a camera showing Portland, Oregon.
    final location = ArcGISPoint(
      x: -122.670,
      y: 45.517,
      z: 175,
      spatialReference: .wgs84,
    );
    final camera = Camera.withLocation(
      location: location,
      heading: 215,
      pitch: 75,
      roll: 0,
    );

    // Set the viewpoint of the scene using the camera.
    _sceneViewController.setViewpointCamera(camera);
  }
}
