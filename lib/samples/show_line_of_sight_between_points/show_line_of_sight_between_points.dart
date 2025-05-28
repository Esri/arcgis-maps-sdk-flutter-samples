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

  // The LocationLineOfSight object that will provide line-of-sight analysis for this sample.
  // The object is initialized with the starting observer and target locations.
  final _locationLineOfSight = LocationLineOfSight(
    observerLocation: ArcGISPoint(
      x: -73.095827750063904,
      y: -49.319214695380957,
      z: 2697.4689045762643,
      spatialReference: SpatialReference.wgs84,
    ),
    targetLocation: ArcGISPoint(
      x: -73.125568047959803,
      y: -49.347049722534479,
      z: 1944.1079967124388,
      spatialReference: SpatialReference.wgs84,
    ),
  );

  // A flag for when the scene view is ready.
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
                    onLongPressEnd: onLongPressEnd,
                  ),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Tap to set new observation point.'),
                    Text('Long press to set new target point.'),
                    Divider(),
                    Text('Green: Visible from the observation point.'),
                    Text('Red: Not visible from the observation point.'),
                    Text('Hidden: Segment is obscured by terrain.'),
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

  void onSceneViewReady() {
    // Create the scene for this sample and set it on the view controller.
    final scene = _setupScene();
    _sceneViewController.arcGISScene = scene;

    // Create an AnalysisOverlay and add the LocationLineOfSight object to it.
    final analysisOverlay = AnalysisOverlay();
    analysisOverlay.analyses.add(_locationLineOfSight);

    // Add the AnalysisOverlay to the view controller.
    _sceneViewController.analysisOverlays.add(analysisOverlay);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    // Get the new observer point from the screen tap offset.
    final newObserverPoint = _sceneViewController.screenToBaseSurface(
      screen: offset,
    );
    // Return if a point could not be returned.
    if (newObserverPoint == null) return;

    // Set the new origin point on the analysis object.
    _locationLineOfSight.observerLocation = newObserverPoint;
  }

  void onLongPressEnd(Offset offset) {
    // Get the new target point from the long press offset.
    final newTargetPoint = _sceneViewController.screenToBaseSurface(
      screen: offset,
    );
    // Return if a point could not be returned.
    if (newTargetPoint == null) return;

    // Set the new origin point on the analysis object.
    _locationLineOfSight.targetLocation = newTargetPoint;
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
          x: -73.1094,
          y: -49.3325,
          z: 2210,
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
