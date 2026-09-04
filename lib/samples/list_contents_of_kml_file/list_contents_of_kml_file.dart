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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListContentsOfKmlFile extends StatefulWidget {
  const ListContentsOfKmlFile({super.key});

  @override
  State<ListContentsOfKmlFile> createState() => _ListContentsOfKmlFileState();
}

class _ListContentsOfKmlFileState extends State<ListContentsOfKmlFile>
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
                  ),
                ),
                Row(
                  mainAxisAlignment: .spaceEvenly,
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
    // Create a scene with an imagery basemap style and add it to the scene view.
    final scene = ArcGISScene.withBasemapStyle(.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Add a surface to the scene based on elevation data.
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );

    // Create a KML layer from a local .kmz file.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final kmzFile = File(listPaths.first);
    final kmlDataset = KmlDataset(kmzFile.uri);
    final kmlLayer = KmlLayer(kmlDataset);

    // Load the dataset and add the layer to the scene.
    await kmlDataset.load();
    scene.operationalLayers.add(kmlLayer);

    // Perform some long-running setup task.
    await Future<void>.delayed(const Duration(seconds: 10));

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> performTask() async {
    setState(() => _ready = false);

    // Perform some task.
    // ignore: avoid_print
    print('Perform task');
    await Future<void>.delayed(const Duration(seconds: 5));

    setState(() => _ready = true);
  }
}
