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

import 'dart:math';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

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
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
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
                  min: 200.0,
                  max: 2000.0,
                  onChanged: (value) => setState(() => _bufferRadius = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 30.0,
                height: 30.0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      color: Colors.red.withAlpha(127),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              const Text('Planar Buffer'),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(
                width: 30.0,
                height: 30.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.0),
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              const Text('Geodetic Buffer'),
            ],
          ),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Configure the graphics overlay for the geodetic buffers.
    _geodeticOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.green,
        outline: SimpleLineSymbol(
          style: SimpleLineSymbolStyle.solid,
          color: Colors.black,
          width: 2.0,
        ),
      ),
    );
    _geodeticOverlay.opacity = 0.5;

    // Configure the graphics overlay for the planar buffers.
    _planarOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.red,
        outline: SimpleLineSymbol(
          style: SimpleLineSymbolStyle.solid,
          color: Colors.black,
          width: 2.0,
        ),
      ),
    );
    _planarOverlay.opacity = 0.5;

    // Configure the graphics overlay for the tapped points.
    _pointOverlay.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.cross,
        color: Colors.white,
        size: 14.0,
      ),
    );

    // Add the overlays to the map view.
    _mapViewController.graphicsOverlays.addAll(
      [
        _geodeticOverlay,
        _planarOverlay,
        _pointOverlay,
      ],
    );

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
