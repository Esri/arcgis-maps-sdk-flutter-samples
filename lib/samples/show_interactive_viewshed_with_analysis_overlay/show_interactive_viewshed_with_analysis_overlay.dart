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

  //fixme
  final _observerGraphic = Graphic(
    symbol: SimpleMarkerSymbol(
      color: const Color.fromARGB(255, 0, 94, 255),
      size: 10,
    ),
  );

  //fixme comments
  late final ViewshedParameters _viewshedParameters;

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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: performTask,
                      child: const Text('Perform Task'),
                    ),
                  ],
                ),
              ],
            ),
            //fixme copyright message
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

    // Disable map pan to allow for tap and drag interactions.
    _mapViewController.interactionOptions.panEnabled = false;
    //fixme necessary?

    // Create the continuous field from the elevation file.
    final continuousField = await ContinuousField.createFromFiles(
      filePaths: [_elevationFile.uri],
      band: 0,
    );

    //fixme comment
    final continuousFieldFunction = ContinuousFieldFunction.create(
      continuousField,
    );

    // Initialize the viewshed parameters.
    _viewshedParameters = ViewshedParameters()
      ..targetHeight = 20.0
      ..maxRadius = 8000
      ..fieldOfView = 150
      ..heading = 10;

    //fixme comment
    final viewshedFunction = ViewshedFunction.withContinuousFieldFunction(
      elevation: continuousFieldFunction,
      parameters: _viewshedParameters,
    );

    //fixme comment
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

    // Set the initial geometry of the observer graphic to the observer position.
    _observerGraphic.geometry = _observerPosition;
    // Set the initial observer position in the viewshed parameters.
    _viewshedParameters.observerPosition = _observerPosition;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void performTask() {}
}
