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

class ShowInteractiveViewshedWithAnalysisOverlay extends StatefulWidget {
  const ShowInteractiveViewshedWithAnalysisOverlay({super.key});

  @override
  State<ShowInteractiveViewshedWithAnalysisOverlay> createState() =>
      _ShowInteractiveViewshedWithAnalysisOverlayState();
}

class _ShowInteractiveViewshedWithAnalysisOverlayState
    extends State<ShowInteractiveViewshedWithAnalysisOverlay>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The elevation file used in the analysis.
  late File _elevationFile;

  // Set the initial observer position on the Isle of Arran, Scotland.
  var _observerPosition = ArcGISPoint(
    x: -579246.504,
    y: 7479619.947,
    z: 20,
    spatialReference: SpatialReference.webMercator,
  );

  // A graphic to represent the observer position on the map.
  final _observerGraphic = Graphic(
    symbol: SimpleMarkerSymbol(color: Colors.blue, size: 10),
  );

  // The parameters for the viewshed analysis.
  late final ViewshedParameters _viewshedParameters;

  // The screen point of the observer when a long-press gesture starts (null when not moving).
  Offset? _moveStartScreenPoint;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    // Get the elevation data used in the sample.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _elevationFile = File(listPaths.first);

    super.initState();
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
                  child: Stack(
                    children: [
                      // Add a map view to the widget tree and set a controller.
                      ArcGISMapView(
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                        onTap: onTap,
                      ),
                      // Add a detector to handle long-press gestures for moving the observer position.
                      GestureDetector(
                        onLongPressStart: onLongPressStart,
                        onLongPressMoveUpdate: onLongPressMoveUpdate,
                        onLongPressEnd: onLongPressEnd,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Perform Task'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a banner with a copyright notice.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Raster data Copyright Scottish Government and SEPA (2014)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the imagery style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
    _mapViewController.arcGISMap = map;

    // Set an initial viewpoint centered over the observer position.
    map.initialViewpoint = Viewpoint.fromCenter(
      _observerPosition,
      scale: 100000,
    );

    // Add the graphic for the observer position.
    final graphicsOverlay = GraphicsOverlay();
    graphicsOverlay.graphics.add(_observerGraphic);
    _mapViewController.graphicsOverlays.add(graphicsOverlay);

    // Create the continuous field from the elevation file.
    final continuousField = await ContinuousField.createFromFiles(
      filePaths: [_elevationFile.uri],
      band: 0,
    );

    // Create the continuous field function for the viewshed analysis from the continuous field.
    final continuousFieldFunction = ContinuousFieldFunction.create(
      continuousField,
    );

    // Initialize the viewshed parameters.
    _viewshedParameters = ViewshedParameters()
      ..targetHeight = 20.0
      ..maxRadius = 8000
      ..fieldOfView = 150
      ..heading = 10;

    // Create the viewshed function with the continuous field function and parameters.
    final viewshedFunction = ViewshedFunction.withContinuousFieldFunction(
      elevation: continuousFieldFunction,
      parameters: _viewshedParameters,
    );

    // Convert the viewshed function to a discrete field function.
    final discreteViewshed = viewshedFunction.toDiscreteFieldFunction();

    // Create colormap renderer for displaying the viewshed result.
    final colormap = Colormap([
      Colors.grey,
      const Color.fromRGBO(136, 204, 132, 0.371), // translucent green
    ]);
    final colormapRenderer = ColormapRenderer.withColormap(colormap);

    // Create the field analysis with the discrete viewshed function and renderer.
    final analysis = FieldAnalysis.withDiscreteFieldFunction(
      function: discreteViewshed,
      renderer: colormapRenderer,
    );

    // Create an analysis overlay and add the analysis to it.
    final analysisOverlay = AnalysisOverlay();
    analysisOverlay.analyses.add(analysis);
    _mapViewController.analysisOverlays.add(analysisOverlay);

    // Synchronize the viewshed parameters and graphic to the initial observer position.
    syncObserverPosition();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void syncObserverPosition() {
    // Update the observer graphic geometry to the current observer position.
    _observerGraphic.geometry = _observerPosition;

    // Update the viewshed parameters to the current observer position (triggers analysis).
    _viewshedParameters.observerPosition = _observerPosition;
  }

  void onTap(Offset screenPoint) {
    // Find the map position corresponding to the tapped screen point.
    final mapPosition = _mapViewController.screenToLocation(
      screen: screenPoint,
    );
    if (mapPosition == null) return;

    // Update the observer position to the tapped location.
    _observerPosition = mapPosition;
    syncObserverPosition();
  }

  void onLongPressStart(LongPressStartDetails details) {
    // Store the screen point of the observer when the long-press gesture starts.
    _moveStartScreenPoint = _mapViewController.locationToScreen(
      mapPoint: _observerPosition,
    );

    // Change the observer graphic color to indicate it is being moved.
    (_observerGraphic.symbol as SimpleMarkerSymbol?)?.color = Colors.yellow;
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_moveStartScreenPoint == null) return;

    // Calculate the new screen point by adding the gesture movement to the stored screen point.
    final newScreenPoint =
        _moveStartScreenPoint! + details.localOffsetFromOrigin;

    // Convert the screen point to a map point for the new observer position.
    final newObserverPosition = _mapViewController.screenToLocation(
      screen: newScreenPoint,
    );
    if (newObserverPosition == null) return;

    // Update to the new observer position.
    _observerPosition = newObserverPosition;
    syncObserverPosition();
  }

  void onLongPressEnd(LongPressEndDetails details) {
    // Change the observer graphic color back to indicate it is no longer being moved.
    (_observerGraphic.symbol as SimpleMarkerSymbol?)?.color = Colors.blue;

    // Clear the stored screen point when the long-press gesture ends.
    _moveStartScreenPoint = null;
  }
}
