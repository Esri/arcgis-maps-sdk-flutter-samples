//
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class CreatePlanarAndGeodeticBuffers extends StatefulWidget {
  const CreatePlanarAndGeodeticBuffers({super.key});

  @override
  State<CreatePlanarAndGeodeticBuffers> createState() =>
      _CreatePlanarAndGeodeticBuffersState();
}

class _CreatePlanarAndGeodeticBuffersState
    extends State<CreatePlanarAndGeodeticBuffers>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The graphics overlay for the geodetic buffers.
  final _geodeticOverlay = GraphicsOverlay();
  // The graphics overlay for the planar buffers.
  final _planarOverlay = GraphicsOverlay();
  // The graphics overlay for the tapped points.
  final _pointOverlay = GraphicsOverlay();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;
  // The buffer radius in miles.
  var _bufferRadius = 500.0;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: () => setState(() => _settingsVisible = true),
                      child: const Text('Settings'),
                    ),
                    // A button to clear the buffers.
                    ElevatedButton(
                      onPressed: clear,
                      child: const Text('Clear'),
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
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets:
          (context) => [
            Row(
              children: [
                const Text('Buffer Radius (miles)'),
                const Spacer(),
                Text(
                  _bufferRadius.round().toString(),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  // A slider to adjust the buffer radius.
                  child: Slider(
                    value: _bufferRadius,
                    min: 200,
                    max: 2000,
                    onChanged: (value) => setState(() => _bufferRadius = value),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 2),
                        color: Colors.red.withAlpha(127),
                      ),
                    ),
                  ),
                ),
                const Text('Planar Buffer'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 2),
                      color: Colors.green,
                    ),
                  ),
                ),
                const Text('Geodetic Buffer'),
              ],
            ),
          ],
    );
  }

  void onMapViewReady() {
    // Configure the graphics overlay for the geodetic buffers.
    _geodeticOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        color: Colors.green,
        outline: SimpleLineSymbol(color: Colors.black, width: 2),
      ),
    );
    _geodeticOverlay.opacity = 0.5;

    // Configure the graphics overlay for the planar buffers.
    _planarOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        color: Colors.red,
        outline: SimpleLineSymbol(color: Colors.black, width: 2),
      ),
    );
    _planarOverlay.opacity = 0.5;

    // Configure the graphics overlay for the tapped points.
    _pointOverlay.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.cross,
        color: Colors.white,
        size: 14,
      ),
    );

    // Add the overlays to the map view.
    _mapViewController.graphicsOverlays.addAll([
      _geodeticOverlay,
      _planarOverlay,
      _pointOverlay,
    ]);

    // Create a map with the topographic basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset screenPoint) {
    // Capture the tapped point and convert it to a map point.
    final mapPoint = _mapViewController.screenToLocation(screen: screenPoint);
    if (mapPoint == null) return;

    // Create a geodetic buffer around the tapped point at the specified distance.
    final geodeticGeometry = GeometryEngine.bufferGeodetic(
      geometry: mapPoint,
      distance: _bufferRadius,
      distanceUnit: LinearUnit(unitId: LinearUnitId.miles),
      maxDeviation: double.nan,
      curveType: GeodeticCurveType.geodesic,
    );
    // Create and add a graphic to the geodetic overlay.
    final geodeticGraphic = Graphic(geometry: geodeticGeometry);
    _geodeticOverlay.graphics.add(geodeticGraphic);

    // Create a planar buffer around the tapped point at the specified distance.
    final planarGeometry = GeometryEngine.buffer(
      geometry: mapPoint,
      distance: _bufferRadius * 1609.344, // Convert miles to meters.
    );
    // Create and add a graphic to the planar overlay.
    final planarGraphic = Graphic(geometry: planarGeometry);
    _planarOverlay.graphics.add(planarGraphic);

    // Create and add a graphic to the point overlay.
    final pointGraphic = Graphic(geometry: mapPoint);
    _pointOverlay.graphics.add(pointGraphic);
  }

  // Clear the graphics overlays.
  void clear() {
    _geodeticOverlay.graphics.clear();
    _planarOverlay.graphics.clear();
    _pointOverlay.graphics.clear();
  }
}
