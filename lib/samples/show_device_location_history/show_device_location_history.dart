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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/sample_state_support.dart';

class ShowDeviceLocationHistory extends StatefulWidget {
  const ShowDeviceLocationHistory({super.key});

  @override
  State<ShowDeviceLocationHistory> createState() =>
      _ShowDeviceLocationHistoryState();
}

class _ShowDeviceLocationHistoryState extends State<ShowDeviceLocationHistory>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A location data source to simulate location updates.
  final _locationDataSource = SimulatedLocationDataSource();
  // Subscription to listen for location changes.
  StreamSubscription? _locationSubscription;
  // A GraphicsOverlay to display the location history polyline.
  final _locationHistoryLineOverlay = GraphicsOverlay();
  // A GraphicsOverlay to display the location history points.
  final _locationHistoryPointOverlay = GraphicsOverlay();
  // A PolylineBuilder to build the location history polyline.
  final _polylineBuilder =
      PolylineBuilder.fromSpatialReference(SpatialReference.wgs84);
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for toggling location tracking.
  var _enableTracking = false;

  @override
  void dispose() {
    // When exiting, stop the location data source and cancel subscriptions.
    _locationDataSource.stop();
    _locationSubscription?.cancel();
    _locationHistoryLineOverlay.graphics.clear();
    _locationHistoryPointOverlay.graphics.clear();

    super.dispose();
  }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to enable or disable location tracking.
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _enableTracking = !_enableTracking);
                      },
                      child: Text(
                        _enableTracking ? 'Stop Tracking' : 'Start Tracking',
                      ),
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
    );
  }

  // The method is called when the map view is ready to be used.
  void onMapViewReady() async {
    // Create a map with the ArcGIS Navigation basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
    // Set the initial viewpoint.
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -110.8258,
        y: 32.154089,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 2e4,
    );
    // Add the map to the map view controller.
    _mapViewController.arcGISMap = map;
    // Add the graphics overlays to the map view.
    _mapViewController.graphicsOverlays.addAll([
      _locationHistoryLineOverlay,
      _locationHistoryPointOverlay,
    ]);
    // Set the renderers for the graphics overlays.
    _locationHistoryLineOverlay.renderer = SimpleRenderer(
      symbol: SimpleLineSymbol(
        color: Colors.red[100]!,
        width: 2.0,
      ),
    );
    _locationHistoryPointOverlay.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        color: Colors.red,
        size: 10.0,
      ),
    );
    // Wait for the map to be displayed before starting the location display.
    _mapViewController.onDrawStatusChanged.listen((status) async {
      if (status == DrawStatus.completed &&
          _locationDataSource.status == LocationDataSourceStatus.stopped) {
        await _initLocationDisplay();
      }
    });
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Initialize the location display with the location data source.
  Future<void> _initLocationDisplay() async {
    final locationDisplay = _mapViewController.locationDisplay;
    locationDisplay.dataSource = _locationDataSource;
    locationDisplay.autoPanMode = LocationDisplayAutoPanMode.recenter;
    locationDisplay.useCourseSymbolOnMovement = true;
    await _startLocationDataSource();
  }

  // Start the location data source and listen for location changes.
  Future<void> _startLocationDataSource() async {
    final routeLineJson =
        await rootBundle.loadString('assets/SimulatedRoute.json');
    final routeLine = Geometry.fromJsonString(routeLineJson) as Polyline;
    _locationDataSource.setLocationsWithPolyline(routeLine);

    // Start the location data source.
    try {
      await _locationDataSource.start();
    } on ArcGISException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text(e.message),
          ),
        );
      }
    }

    // Listen for location changes.
    if (_locationDataSource.status == LocationDataSourceStatus.started) {
      _locationSubscription = _locationDataSource.onLocationChanged
          .listen(_handleLdsLocationChange);
    }
  }

  // Handle location changes from the location data source.
  void _handleLdsLocationChange(ArcGISLocation location) {
    if (!_enableTracking) return;
    // Add the location to the location history as a graphic point.
    final point = location.position;
    _locationHistoryPointOverlay.graphics.add(Graphic(geometry: point));
    // Add the location to the location history as a polyline.
    _polylineBuilder.addPoint(point);
    // Visualize the location history polyline on the map.
    _locationHistoryLineOverlay.graphics.clear();
    _locationHistoryLineOverlay.graphics
        .add(Graphic(geometry: _polylineBuilder.toGeometry() as Polyline));
  }
}
