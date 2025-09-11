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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddPointCloudLayerFromFile extends StatefulWidget {
  const AddPointCloudLayerFromFile({super.key});

  @override
  State<AddPointCloudLayerFromFile> createState() =>
      _AddPointCloudLayerFromFileState();
}

class _AddPointCloudLayerFromFileState extends State<AddPointCloudLayerFromFile>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISSceneView(
            controllerProvider: () => _sceneViewController,
            onSceneViewReady: onSceneViewReady,
          ),      
    );
  }

  Future<void> onSceneViewReady() async {
    // Add the scene to the view controller.
    _sceneViewController.arcGISScene = _setupScene();

    // Load the point cloud layer.
    await loadCloudPointLayerFromFile();
  }

  ArcGISScene _setupScene() {
    // Create a scene with an imagery basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Set the scene's initial viewpoint.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: Camera.withLatLong(
        latitude: 32.720195,
        longitude: -117.155593,
        altitude: 1050,
        heading: 23,
        pitch: 70,
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

    return scene;
  }

  Future<void> loadCloudPointLayerFromFile() async {
    // Download the sample data.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final sanDiegoPointCloudFile = File(listPaths.first);

    // Create a Point Cloud Layer from the file URI.
    final pointCloudLayer = PointCloudLayer.withUri(sanDiegoPointCloudFile.uri);
    await pointCloudLayer.load();
    // Add the point cloud layer to the map's operational layers.
    _sceneViewController.arcGISScene?.operationalLayers.add(pointCloudLayer);
  }
}
