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

class SetSurfacePlacementMode extends StatefulWidget {
  const SetSurfacePlacementMode({super.key});

  @override
  State<SetSurfacePlacementMode> createState() =>
      _SetSurfacePlacementModeState();
}

class _SetSurfacePlacementModeState extends State<SetSurfacePlacementMode>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // A flag for when the scene view is ready.
  var _ready = false;

  // The current z-value, in meters, applied to all graphics.
  var _zValue = 70.0;

  // Controls whether the billboarded or flat draped overlay is displayed.
  var _showBillboarded = true;

  // Graphics overlays organized by surface placement.
  final Map<SurfacePlacement, GraphicsOverlay> _overlays = {};

  // Multiplier for converting meters to feet.
  static const _metersToFeetMultiplier = 3.28084;

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
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Select which draped surface placement mode is displayed.
                      Row(
                        children: [
                          const Text('Draped Mode'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('Billboarded'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('Flat'),
                                ),
                              ],
                              selected: {_showBillboarded},
                              onSelectionChanged: (selection) {
                                // Update the selected draped mode.
                                setState(() {
                                  _showBillboarded = selection.first;
                                });
                                // Update the visible draped overlay.
                                _overlays[SurfacePlacement.drapedBillboarded]
                                        ?.isVisible =
                                    _showBillboarded;
                                _overlays[SurfacePlacement.drapedFlat]
                                        ?.isVisible =
                                    !_showBillboarded;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Adjust the z-value applied to all graphics.
                      Row(
                        children: [
                          Text(
                            "Z-value: ${(_zValue * _metersToFeetMultiplier).round()}'",
                          ),
                          const SizedBox(width: 16),
                          const Text("0'"),
                          Expanded(
                            child: Slider(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              max: 140,
                              value: _zValue,
                              onChanged: _updateGraphics,
                            ),
                          ),
                          const Text("459'"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator until the sample is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with an imagery basemap.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Add an elevation source to the scene's base surface.
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );

    // Add the Brest, France buildings scene layer.
    scene.operationalLayers.add(
      ArcGISSceneLayer.withUri(
        Uri.parse(
          'https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer',
        ),
      ),
    );

    // Set the scene on the scene view.
    _sceneViewController.arcGISScene = scene;

    // Create graphics overlays for each surface placement mode.
    _createGraphicsOverlays();

    // Create a camera showing Brest, France.
    final location = ArcGISPoint(
      x: -4.4595,
      y: 48.3889,
      z: 80,
      spatialReference: SpatialReference.wgs84,
    );
    final camera = Camera.withLocation(
      location: location,
      heading: 330,
      pitch: 97,
      roll: 0,
    );

    // Set the viewpoint using the camera.
    _sceneViewController.setViewpointCamera(camera);

    // Mark the scene as ready and refresh the UI.
    setState(() {
      _ready = true;
    });
  }

  // Creates graphics overlays for each surface placement mode.
  void _createGraphicsOverlays() {
    // Define the different surface placement modes used.
    final placements = [
      SurfacePlacement.absolute,
      SurfacePlacement.drapedBillboarded,
      SurfacePlacement.drapedFlat,
      SurfacePlacement.relative,
      SurfacePlacement.relativeToScene,
    ];

    // Create and configure an overlay for each placement mode.
    for (final placement in placements) {
      // Create a graphics overlay to display graphics in the scene.
      final overlay = GraphicsOverlay();

      // Set the surface placement mode.
      overlay.sceneProperties.surfacePlacement = placement;

      // Add graphics to the overlay.
      _addGraphicsForPlacement(
        overlay,
        placement,
        _labelForPlacement(placement),
      );

      // Store the overlay for later access.
      _overlays[placement] = overlay;

      // Add the overlay to the scene view.
      _sceneViewController.graphicsOverlays.add(overlay);
    }
  }

  // Adds graphics to an overlay for the specified surface placement mode.
  void _addGraphicsForPlacement(
    GraphicsOverlay overlay,
    SurfacePlacement placement,
    String label,
  ) {
    // Offset the RelativeToScene graphic slightly so it is easier to distinguish from the other graphics.
    final offset = placement == SurfacePlacement.relativeToScene ? 0.0002 : 0.0;

    // Create a point that determines where the graphic will show up on the map.
    final point = ArcGISPoint(
      x: -4.4609257 + offset,
      y: 48.3903965 + offset,
      z: _zValue,
      spatialReference: SpatialReference.wgs84,
    );

    // Create a red triangle at the specified location point.
    final markerGraphic = Graphic(
      geometry: point,
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.triangle,
        color: Colors.red,
        size: 20,
      ),
    );

    // Create a text symbol for the label and configure its appearance.
    final textSymbol = TextSymbol(
      text: label,
      color: Colors.blue,
      size: 18,
      horizontalAlignment: HorizontalAlignment.left,
    );
    // Offset the label above its location.
    textSymbol.offsetY = 20;
    
    // Add a cyan halo to improve label visibility.
    textSymbol.haloWidth = 1;
    textSymbol.haloColor = Colors.cyan;

    // Create a text graphic identifying the surface placement mode.
    final textGraphic = Graphic(geometry: point, symbol: textSymbol);

    // Add the marker and label graphics to the overlay.
    overlay.graphics.addAll([markerGraphic, textGraphic]);
  }

  // Returns the display label for a surface placement mode.
  String _labelForPlacement(SurfacePlacement placement) {
    switch (placement) {
      case SurfacePlacement.absolute:
        return 'Absolute';

      case SurfacePlacement.drapedBillboarded:
        return 'Draped Billboarded';

      case SurfacePlacement.drapedFlat:
        return 'Draped Flat';

      case SurfacePlacement.relative:
        return 'Relative';

      case SurfacePlacement.relativeToScene:
        return 'Relative To Scene';
    }
  }

  // Updates the z-value for all graphics.
  void _updateGraphics(double value) {
    setState(() {
      _zValue = value;
    });

    // Loop through every graphic overlay.
    for (final overlay in _overlays.values) {
      // Loop through every graphic inside of that specific overlay.
      for (final graphic in overlay.graphics) {
        // Get the graphic's current point geometry.
        final point = graphic.geometry! as ArcGISPoint;

        // Update the graphic with the new z-value.
        graphic.geometry = ArcGISPoint(
          x: point.x,
          y: point.y,
          z: value,
          spatialReference: point.spatialReference,
        );
      }
    }
  }
}
