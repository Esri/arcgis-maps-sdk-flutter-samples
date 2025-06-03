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
import 'package:path_provider/path_provider.dart';

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

  Future<void> onSceneViewReady() async {
    // Create a scene with the imagery standard basemap style.
    final scene = ArcGISScene.withBasemapStyle(
      BasemapStyle.arcGISImageryStandard,
    );

    // Load the point cloud layer.
    final pointCloudLayer = await loadCloudPointLayerFromFile();

    // Add the point cloud layer to the map's operational layers.
    scene.operationalLayers.add(pointCloudLayer);

    // Add the scene to the scene view's scene property.
    _sceneViewController.arcGISScene = scene;

    // Create a new surface.
    final surface = Surface();

    // Create a Uri from the elevation image service.
    final myUri = Uri.parse(
      'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
    );

    // Create an ArcGIS tiled elevation.
    final arcGISTiledElevationSource = ArcGISTiledElevationSource.withUri(
      myUri,
    );

    // Add the ArcGIS tiled elevation source to the surface's elevated sources collection.
    surface.elevationSources.add(arcGISTiledElevationSource);

    // Set the scene's base surface to the surface with the ArcGIS tiled elevation source.
    scene.baseSurface = surface;

    // Create camera with an initial camera position (Mount Everest in the Alps mountains).
    final camera = Camera.withLatLong(
      latitude: 32.720195,
      longitude: -117.155593,
      altitude: 1050,
      heading: 23,
      pitch: 70,
      roll: 0,
    );

    // Set the scene view's camera position.
    await _sceneViewController.setViewpointCameraAnimated(camera: camera);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<PointCloudLayer> loadCloudPointLayerFromFile() async {
    // Download the sample data.
    await downloadSampleData(['34da965ca51d4c68aa9b3a38edb29e00']);
    // Get the temp directory.
    final directory = await getApplicationDocumentsDirectory();
    // Create a file reference to the scene layer package for Balboa Park, San Diego, CA.
    final sanDiegoPointCloudFile = File(
      '${directory.absolute.path}/sandiego-north-balboa-pointcloud.slpk',
    );
    // Create a Point Cloud Layer from the file URI.
    final pointCloud = PointCloudLayer.withUri(sanDiegoPointCloudFile.uri);
    return pointCloud;
  }
}
