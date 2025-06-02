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

class DisplayWebSceneFromPortalItem extends StatefulWidget {
  const DisplayWebSceneFromPortalItem({super.key});

  @override
  State<DisplayWebSceneFromPortalItem> createState() =>
      _DisplayWebSceneFromPortalItemState();
}

class _DisplayWebSceneFromPortalItemState
    extends State<DisplayWebSceneFromPortalItem>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add the scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  // Called when the scene view is ready to display a scene.
  void onSceneViewReady() {
    // Load the scene in the area of Geneva, Switzerland.
    _sceneViewController.arcGISScene = ArcGISScene.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'c6f90b19164c4283884361005faea852',
      ),
    );
  }
}
