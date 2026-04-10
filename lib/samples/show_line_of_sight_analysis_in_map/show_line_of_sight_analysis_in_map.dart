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

class ShowLineOfSightAnalysisInMap extends StatefulWidget {
  const ShowLineOfSightAnalysisInMap({super.key});

  @override
  State<ShowLineOfSightAnalysisInMap> createState() =>
      _ShowLineOfSightAnalysisInMapState();
}

class _ShowLineOfSightAnalysisInMapState
    extends State<ShowLineOfSightAnalysisInMap>
    with SampleStateSupport {
  // The elevation file used in the analysis.
  late File _elevationFile;

  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    // Get the elevation data used in the sample.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _elevationFile = File(listPaths.first);

    super.initState();
  }
  //fixme review README
  //fixme screenshot

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
                    onTap: onTap,
                  ),
                ),
                Text(
                  'Raster data Copyright Scottish Government and SEPA (2014)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

  Future<void> onMapViewReady() async {
    // Create a map with the hillshade dark style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISHillshadeDark);
    _mapViewController.arcGISMap = map;

    // Create a graphics overlay to display the target and observers.
    final positionsGraphicsOverlay = GraphicsOverlay();
    _mapViewController.graphicsOverlays.add(positionsGraphicsOverlay);

    // Load an image that represents the target (e.g., a radio mast or receiver).
    final beaconImage = await ArcGISImage.fromAsset('assets/beacon.png');
    final beaconSymbol = PictureMarkerSymbol.withImage(beaconImage)
      ..width = 24
      ..height = 24;

    // Create a graphic for the target and add it to the graphics overlay.
    final targetPosition = ArcGISPoint(
      x: -577955.365,
      y: 7484288.220,
      z: 5,
      spatialReference: .webMercator,
    );
    final targetGraphic = Graphic(
      geometry: targetPosition,
      symbol: beaconSymbol,
    );
    positionsGraphicsOverlay.graphics.add(targetGraphic);

    // Create the continuous field from the elevation file.
    final continuousField = await ContinuousField.createFromFiles(
      filePaths: [_elevationFile.uri],
      band: 0,
    );

    // Set an initial viewpoint centered on the target position.
    map.initialViewpoint = Viewpoint.fromCenter(targetPosition, scale: 90000);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    // Do something with a tap.
    // ignore: avoid_print
    print('Tapped at $offset');
  }
}
