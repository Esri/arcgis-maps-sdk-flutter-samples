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

class MeasureDistanceInScene extends StatefulWidget {
  const MeasureDistanceInScene({super.key});

  @override
  State<MeasureDistanceInScene> createState() => _MeasureDistanceInSceneState();
}

class _MeasureDistanceInSceneState extends State<MeasureDistanceInScene>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  //fixme comment
  final _locationDistanceMeasurement = ExploratoryLocationDistanceMeasurement(
    startLocation: ArcGISPoint(
      x: -4.494677,
      y: 48.384472,
      z: 24.772694,
      spatialReference: .wgs84,
    ),
    endLocation: ArcGISPoint(
      x: -4.495646,
      y: 48.384377,
      z: 58.501115,
      spatialReference: .wgs84,
    ),
  );

  // A flag for when the scene view is ready and controls can be used.
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
    // Create a scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(.arcGISTopographic);
    _sceneViewController.arcGISScene = scene;

    //fixme comment
    final lookAtPoint = Envelope.fromPoints(
      _locationDistanceMeasurement.startLocation,
      _locationDistanceMeasurement.endLocation,
    ).center;
    final camera = Camera.withLookAtPoint(
      lookAtPoint: lookAtPoint,
      distance: 200,
      heading: 0,
      pitch: 45,
      roll: 0,
    );
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: lookAtPoint,
      scale: 1,
      camera: camera,
    );

    // Add world elevation source to the scene's surface.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    //fixme brest layer

    //fixme analysis overlay

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  //fixme longpress-and-drag
  //fixme unit system
  //fixme distance text
  //fixme review README
  //fixme screen shot
}
