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
import '../../utils/sample_state_support.dart';

class ChangeViewpoint extends StatefulWidget {
  const ChangeViewpoint({super.key});

  @override
  State<ChangeViewpoint> createState() => _ChangeViewpointState();
}

class _ChangeViewpointState extends State<ChangeViewpoint> with SampleStateSupport {
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

  void onMapViewReady() async {
    // Coordinates for London
    // Coordinates for London
    final ArcGISPoint londonCoords = ArcGISPoint(
      x: -13881.7678417696,
      y: 6710726.57374296,
      spatialReference: SpatialReference.webMercator,
    );
    const double londonScale = 8762.7156655228955;

    // Coordinates for Redlands
    final redlandsEnvelope = PolygonBuilder(
      spatialReference: SpatialReference.webMercator,
    );
    redlandsEnvelope.addPoint(
      ArcGISPoint(
        x: -13049785.1566222,
        y: 4032064.6003424,
      ),
    );
    redlandsEnvelope.addPoint(
      ArcGISPoint(
        x: -13049785.1566222,
        y: -13049785.1566222,
      ),
    );
    redlandsEnvelope.addPoint(
      ArcGISPoint(
        x: -13037033.5780234,
        y: 4032064.6003424,
      ),
    );
    redlandsEnvelope.addPoint(
      ArcGISPoint(
        x: -13037033.5780234,
        y: 4040202.42595729,
      ),
    );

    // Coordinates for Edinburgh
    final edinburghEnvelope = PolygonBuilder(
      spatialReference: SpatialReference.webMercator,
    );
    edinburghEnvelope.addPoint(
      ArcGISPoint(
        x: -354262.156621384,
        y: 47548092.94093301,
      ),
    );
    edinburghEnvelope.addPoint(
      ArcGISPoint(
        x: -354262.156621384,
        y: 7548901.50684376,
      ),
    );
    edinburghEnvelope.addPoint(
      ArcGISPoint(
        x: -353039.164455303,
        y: 7548092.94093301,
      ),
    );
    edinburghEnvelope.addPoint(
      ArcGISPoint(
        x: -353039.164455303,
        y: 7548901.50684376,
      ),
    );

    // String array to store titles for the viewpoints specified above.
    const viewpointTitles = [
      'Geometry',
      'Center & Scale',
      'Animate',
    ];

    initializeViewpoint();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void initializeViewpoint() {
    // Create new Map with basemap and initial location
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // Assign the map to the MapView
    _mapViewController.arcGISMap = map;
  }
}
