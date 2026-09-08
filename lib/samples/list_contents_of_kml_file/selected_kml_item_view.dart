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

class SelectedKmlItemView extends StatefulWidget {
  const SelectedKmlItemView({
    required this._kmlDataset,
    required this._selectedKmlNode,
    super.key,
  });

  final KmlDataset _kmlDataset;
  final KmlNode _selectedKmlNode;

  @override
  State<SelectedKmlItemView> createState() => _SelectedKmlItemViewState();
}

class _SelectedKmlItemViewState extends State<SelectedKmlItemView>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget._selectedKmlNode.name)),
      body: SafeArea(
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

    final kmlLayer = KmlLayer(widget._kmlDataset);
    scene.operationalLayers.add(kmlLayer);

    // Center on the selected KML node.
    final nodeCenterPoint = widget._selectedKmlNode.extent!.center;

    // final viewpoint = Viewpoint.fromTargetExtent(widget._selectedKmlNode.extent!);

    final viewpoint = Viewpoint.withExtentCamera(
      targetExtent: widget._selectedKmlNode.extent!,
      camera: Camera.withLookAtPoint(
        lookAtPoint: nodeCenterPoint,
        distance: 500,
        heading: 0,
        pitch: 30,
        roll: 0,
      ),
    );

    _sceneViewController.setViewpoint(viewpoint);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
