// Copyright 2025 Esri
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
import 'dart:convert';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location_with_nmea_data_sources/nmea_source_simulator.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class ShowDeviceLocationWithNmeaDataSources extends StatefulWidget {
  const ShowDeviceLocationWithNmeaDataSources({super.key});

  @override
  State<ShowDeviceLocationWithNmeaDataSources> createState() =>
      _ShowDeviceLocationWithNmeaDataSourcesState();
}

class _ShowDeviceLocationWithNmeaDataSourcesState
    extends State<ShowDeviceLocationWithNmeaDataSources>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create the NMEA location data source
  final _locationDataSource = NmeaLocationDataSource();

  // Create the simulated NMEA data provider
  final _nmeaDataSimulator = NmeaSourceSimulator();
  StreamSubscription? _nmeaDataSubscription;

  // Enables or disables the Recenter button
  var _enableRecenter = false;
  StreamSubscription? _autopanSubscription;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void dispose() {
    _nmeaDataSubscription?.cancel();
    _autopanSubscription?.cancel();

    super.dispose();
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
                    // Start the Location Data Source.
                    ElevatedButton(
                      onPressed: _locationDataSource.status ==
                              LocationDataSourceStatus.stopped
                          ? _startNmeaDataSource
                          : null,
                      child: const Text('Start'),
                    ),
                    // Recenter the map on the blue dot.
                    ElevatedButton(
                      onPressed: _enableRecenter
                          ? () {
                              // Set the autoPanMode to recenter
                              _mapViewController.locationDisplay.autoPanMode =
                                  LocationDisplayAutoPanMode.recenter;
                            }
                          : null,
                      child: const Text('Recenter'),
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
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map and set it to the MapView
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Use the NMEA location data source as the data source for the map
    _mapViewController.locationDisplay.dataSource = _locationDataSource;

    // Set the autoPanMode to recenter and listen for any changes.
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.recenter;
    _autopanSubscription = _mapViewController
        .locationDisplay.onAutoPanModeChanged
        .listen((autoPanMode) {
      setState(() {
        // Activates/deactivates the Recenter button based on the new auto pan mode.
        _enableRecenter = autoPanMode != LocationDisplayAutoPanMode.recenter;
      });
    });

    // Set the ready state variable to true to enable the UI.
    setState(() => _ready = true);
  }

  Future<void> _startNmeaDataSource() async {
    // Subscribe to the simulator
    _nmeaDataSubscription ??=
        _nmeaDataSimulator.nmeaMessages.listen((nmeaDataString) {
      final nmeaData = utf8.encoder.convert(nmeaDataString);
      _locationDataSource.pushData(nmeaData);
    });

    await _locationDataSource.start();
  }
}
