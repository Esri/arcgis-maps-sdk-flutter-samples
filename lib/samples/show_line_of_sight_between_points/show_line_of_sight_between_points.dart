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

class ShowLineOfSightBetweenPoints extends StatefulWidget {
  const ShowLineOfSightBetweenPoints({super.key});

  @override
  State<ShowLineOfSightBetweenPoints> createState() =>
      _ShowLineOfSightBetweenPointsState();
}

class _ShowLineOfSightBetweenPointsState
    extends State<ShowLineOfSightBetweenPoints>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // Origin location for the line-of-sight calculation.
  ArcGISPoint? _originPoint;

  // Target location for the line-of-sight calculation.
  ArcGISPoint? _targetPoint;

  // The AnalysisOverlay that will show the line-of-sight results.
  final _analysisOverlay = AnalysisOverlay();

  // final _locationLineOfSight = LocationLineOfSight(observerLocation: observerLocation, targetLocation: targetLocation)

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
                    onTap: onTap,
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'The green line segment is visible from the origin point, the red segment is not.',
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
    // Create a scene with a topographic basemap style.
    final scene = _setupScene();
    _sceneViewController.arcGISScene = scene;

    // Add an AnalysisOverlay to the view controller
    _sceneViewController.analysisOverlays.add(_analysisOverlay);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    _originPoint = _sceneViewController.screenToBaseSurface(screen: offset);
  }

  ArcGISScene _setupScene() {
    // Create a scene with an imagery basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Set the scene's initial viewpoint.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: Camera.withLookAtPoint(
        lookAtPoint: ArcGISPoint(
          x: -73.0870,
          y: -49.3460,
          z: 5046,
          spatialReference: SpatialReference.wgs84,
        ),
        distance: 10000,
        heading: 150,
        pitch: 20,
        roll: 0,
      ),
    );

    // Add surface elevation to the scene.
    final surface = Surface();
    final worldElevationService = Uri.parse(
      'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
    );
    final elevationSource = ArcGISTiledElevationSource.withUri(
      worldElevationService,
    );
    surface.elevationSources.add(elevationSource);
    scene.baseSurface = surface;

    return scene;
  }
}
