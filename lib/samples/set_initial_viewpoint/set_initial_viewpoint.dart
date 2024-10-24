// Copyright 2024 Esri
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
import 'package:flutter/material.dart';

class SetInitialViewpoint extends StatefulWidget {
  const SetInitialViewpoint({super.key});

  @override
  State<SetInitialViewpoint> createState() => _SetInitialViewpointState();
}

class _SetInitialViewpointState extends State<SetInitialViewpoint> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    // Create an initial envelope.
    final initialEnvelope = Envelope.fromXY(
      xMin: -118.805,
      yMin: 34.027,
      xMax: -118.795,
      yMax: 34.037,
      spatialReference: SpatialReference.wgs84,
    );
    // Create and set the initial viewpoint to the map
    final initialViewPoint = Viewpoint.fromTargetExtent(initialEnvelope.extent);
    map.initialViewpoint = initialViewPoint;
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
