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
import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ShowDeviceLocationSample extends StatefulWidget {
  const ShowDeviceLocationSample({super.key});

  @override
  State<ShowDeviceLocationSample> createState() =>
      _ShowDeviceLocationSampleState();
}

class _ShowDeviceLocationSampleState extends State<ShowDeviceLocationSample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;
  //fixme comments
  final _locationDataSource = SystemLocationDataSource();
  StreamSubscription? _statusSubscription;
  var _status = LocationDataSourceStatus.stopped;
  ArcGISException? _ldsException;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void dispose() {
    //fixme comment
    _locationDataSource.stop();
    _statusSubscription?.cancel();

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
                Visibility(
                  visible: _ldsException == null,
                  // An error message if the location data source fails to start.
                  replacement: Text('Exception: ${_ldsException?.message}'),
                  // A button to show the Settings bottom sheet.
                  child: ElevatedButton(
                    onPressed: () => setState(() => _settingsVisible = true),
                    child: const Text('Location Settings'),
                  ),
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

  // The build method for the Geometry Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
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
                'Location Settings',
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
              const Text('Show Location'),
              const Spacer(),
              Switch(
                value: (_status == LocationDataSourceStatus.started),
                onChanged: (_) {
                  if (_status == LocationDataSourceStatus.started) {
                    _mapViewController.locationDisplay.stop();
                  } else {
                    _mapViewController.locationDisplay.start();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    //fixme comments
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -110.8258,
        y: 32.154089,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 2e4,
    );

    _mapViewController.arcGISMap = map;
    await _initLocationDisplay();
    setState(() => _ready = true);
  }

  Future<void> _initLocationDisplay() async {
    final locationDisplay = _mapViewController.locationDisplay;
    locationDisplay.dataSource = _locationDataSource;
    locationDisplay.useCourseSymbolOnMovement = true;
    locationDisplay.autoPanMode = LocationDisplayAutoPanMode.compassNavigation;

    await _initLocationDataSource();
  }

  Future<void> _initLocationDataSource() async {
    _statusSubscription = _locationDataSource.onStatusChanged.listen((status) {
      setState(() => _status = status);
    });
    setState(() => _status = _locationDataSource.status);

    try {
      await _locationDataSource.start();
    } on ArcGISException catch (e) {
      setState(() => _ldsException = e);
    }
  }
}
