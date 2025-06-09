//
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

class DisplaySceneFromMobileScenePackage extends StatefulWidget {
  const DisplaySceneFromMobileScenePackage({super.key});

  @override
  State<DisplaySceneFromMobileScenePackage> createState() =>
      _DisplaySceneFromMobileScenePackageState();
}

class _DisplaySceneFromMobileScenePackageState
    extends State<DisplaySceneFromMobileScenePackage>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a scene view to the widget tree and set a controller.
      body: Stack(
        children: [
          ArcGISSceneView(
            controllerProvider: () => _sceneViewController,
            onSceneViewReady: onSceneViewReady,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          Visibility(
            visible: !_ready,
            child: const Center(
              child: Column(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(backgroundColor: Colors.white),
                  Text('Downloading sample data...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    await downloadSampleData(['7dd2f97bb007466ea939160d0de96a9d']);
    final appDir = await getApplicationDocumentsDirectory();

    // Load the local mobile scene package.
    final mspkFile = File('${appDir.absolute.path}/philadelphia.mspk');
    final mspk = MobileScenePackage.withFileUri(mspkFile.uri);
    await mspk.load();

    if (mspk.scenes.isNotEmpty) {
      // Get the first scene in the mobile scene package and set to the scene view.
      _sceneViewController.arcGISScene = mspk.scenes.first;
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
