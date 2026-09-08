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

class SetKmlGroundOverlayProperties extends StatefulWidget {
  const SetKmlGroundOverlayProperties({super.key});

  @override
  State<SetKmlGroundOverlayProperties> createState() =>
      _SetKmlGroundOverlayPropertiesState();
}

class _SetKmlGroundOverlayPropertiesState
    extends State<SetKmlGroundOverlayProperties>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // The KML ground overlay used in the sample.
  late KmlGroundOverlay _kmlGroundOverlay;

  // A local file used to construct the KML Icon.
  late File _kmlIconFile;

  // The opacity of the KML ground overlay set to an initial value.
  var _opacity = 0.5;

  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();
    // Get the resources required for the sample.
    _initDownloadResources();
  }

  void _initDownloadResources() {
    // Get the image used in the sample to create the KML Icon.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _kmlIconFile = File(listPaths.first);
  }

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
                    // Add a slider to adjust the opacity of the KML ground overlay.
                    Slider(
                      value: _opacity,
                      onChanged: (opacity) {
                        // Capture the new opacity value.
                        setState(() => _opacity = opacity);
                        // Update the opacity of the KML ground overlay.
                        _updateOverlay(opacity);
                      },
                    ),
                    // Display a label with percentage opacity.
                    Text('Opacity: ${(_opacity * 100).floor()}%'),
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
    // Create a scene with an imagery basemap style and set to the scene view.
    final scene = ArcGISScene.withBasemapStyle(.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Create a geometry for the ground overlay.
    final overlayGeometry = Envelope.fromXY(
      xMin: -123.0796942287304,
      yMin: 44.03878298600624,
      xMax: -123.066227926904,
      yMax: 44.04736963555683,
      spatialReference: SpatialReference.wgs84,
    );

    // Create a KML Icon for the overlay image using the path to an image file.
    final kmlIcon = KmlIcon(_kmlIconFile.uri);

    // Create a KML ground overlay using the geometry and icon.
    _kmlGroundOverlay = KmlGroundOverlay.create(
      geometry: overlayGeometry,
      icon: kmlIcon,
    )!;

    // Set the rotation of the ground overlay.
    _kmlGroundOverlay.rotation = -3.046024799346924;

    // Set the initial opacity.
    _updateOverlay(_opacity);

    // Create a KML dataset with the ground overlay as the root node.
    final kmlDataset = KmlDataset.withRootNode(_kmlGroundOverlay);

    // Create a KML layer using the dataset.
    final kmlLayer = KmlLayer(kmlDataset);

    // Add the layer to the scene.
    scene.operationalLayers.add(kmlLayer);

    // Set the viewpoint to the ground overlay.
    _sceneViewController.setViewpoint(
      Viewpoint.withExtentCamera(
        targetExtent: overlayGeometry,
        camera: Camera.withLookAtPoint(
          lookAtPoint: overlayGeometry.center,
          distance: 1250,
          heading: 45,
          pitch: 60,
          roll: 0,
        ),
      ),
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void _updateOverlay(double opacity) {
    // Change the opacity of the overlay according to the provided value.
    _kmlGroundOverlay.color = Colors.black.withValues(alpha: opacity);
  }
}
