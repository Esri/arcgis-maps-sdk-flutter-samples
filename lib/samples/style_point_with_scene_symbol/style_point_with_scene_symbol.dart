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

class StylePointWithSceneSymbol extends StatefulWidget {
  const StylePointWithSceneSymbol({super.key});

  @override
  State<StylePointWithSceneSymbol> createState() =>
      _StylePointWithSceneSymbolState();
}

class _StylePointWithSceneSymbolState extends State<StylePointWithSceneSymbol>
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
          // Add a scene view to the widget tree and set a controller.
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
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _sceneViewController.arcGISScene = scene;

    // Create an ArcGIS tiled elevation.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );

    // Add the ArcGIS tiled elevation source to the surface's elevated sources collection.
    scene.baseSurface.elevationSources.add(elevationSource);

    // Create the graphics overlay.
    final overlay = GraphicsOverlay();

    // Set the surface placement mode for the overlay.
    overlay.sceneProperties.surfacePlacement = SurfacePlacement.absolute;

    // A list of colors used to visually differentiate each symbol style.
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.cyan,
      Colors.blueGrey,
    ];

    for (var i = 0; i < SimpleMarkerSceneSymbolStyle.values.length; i++) {
      final symbolStyle = SimpleMarkerSceneSymbolStyle.values[i];

      // Create the symbol.
      final symbol = SimpleMarkerSceneSymbol(
        style: symbolStyle,
        color: colors[i],
        height: 200,
        width: 200,
        depth: 200,
        anchorPosition: SceneSymbolAnchorPosition.center,
      );

      // Offset each symbol so that they aren't in the same spot.
      final offset = 4.975 + 0.01 * i;
      final point = ArcGISPoint(
        x: offset,
        y: 49,
        z: 500,
        spatialReference: SpatialReference.wgs84,
      );

      // Create the graphic from the geometry and the symbol.
      final graphic = Graphic(geometry: point, symbol: symbol);

      // Add the graphic to the overlay.
      overlay.graphics.add(graphic);
    }

    // Show the graphics overlay in the scene.
    _sceneViewController.graphicsOverlays.add(overlay);

    // Create camera with an initial camera position.
    final camera = Camera.withLatLong(
      latitude: 48.973,
      longitude: 4.92,
      altitude: 2082,
      heading: 60,
      pitch: 75,
      roll: 0,
    );

    // Set the scene view's camera position.
    await _sceneViewController.setViewpointCameraAnimated(camera: camera);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
