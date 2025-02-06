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

  // Create the NMEA location data source.
  final _locationDataSource = NmeaLocationDataSource();

  // Subscriptions to location data source events and members to keep current data.
  StreamSubscription? _locationSubscription;
  NmeaLocation? _currentNmeaLocation;
  StreamSubscription? _satelliteSubscription;
  var _currentSatelliteInfos = <NmeaSatelliteInfo>[];

  // Create the simulated NMEA data provider.
  final _nmeaDataSimulator = NmeaSourceSimulator();
  StreamSubscription? _nmeaDataSubscription;

  // Enables or disables the Recenter button.
  var _enableRecenter = false;
  StreamSubscription? _autopanSubscription;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void dispose() {
    // Cancel all the subscriptions.
    _nmeaDataSubscription?.cancel();
    _autopanSubscription?.cancel();
    _locationSubscription?.cancel();
    _satelliteSubscription?.cancel();

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
                              // Set the autoPanMode to recenter.
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
            // Current Section and POIs display.
            Column(
              children: [
                ColoredBox(
                  color: const Color.fromARGB(220, 255, 255, 255),
                  child: SafeArea(
                    left: false,
                    right: false,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: NmeaLocationDetails(
                          nmeaLocation: _currentNmeaLocation,
                          nmeaSatelliteInfos: _currentSatelliteInfos,
                        ),
                      ),
                    ),
                  ),
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
    // Create a map and set it to the MapView.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Use the NMEA location data source as the data source for the map.
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
    // Subscribe to the simulator data.
    _nmeaDataSubscription ??=
        _nmeaDataSimulator.nmeaMessages.listen((nmeaDataString) {
      final nmeaData = utf8.encoder.convert(nmeaDataString);
      _locationDataSource.pushData(nmeaData);
    });

    // Subscribe to the location stream of the location data source.
    _locationSubscription ??=
        _locationDataSource.onLocationChanged.listen((location) {
      setState(() => _currentNmeaLocation = location as NmeaLocation);
    });

    // Subscribe to the location data source's satellite changed stream.
    _satelliteSubscription ??=
        _locationDataSource.onSatellitesChanged.listen((satelliteInfos) {
      setState(() => _currentSatelliteInfos = satelliteInfos);
    });

    await _locationDataSource.start();
  }
}

class NmeaLocationDetails extends StatelessWidget {
  const NmeaLocationDetails({
    required this.nmeaLocation,
    required this.nmeaSatelliteInfos,
    super.key,
  });

  final NmeaLocation? nmeaLocation;
  final List<NmeaSatelliteInfo> nmeaSatelliteInfos;

  @override
  Widget build(BuildContext context) {
    if (nmeaLocation == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accuracy will be shown here.'),
          Text('Satellite information will be shown here'),
        ],
      );
    }

    final accuracy =
        'Accuracy: Horizontal: ${nmeaLocation!.horizontalAccuracy.toStringAsFixed(3)}, Vertical: ${nmeaLocation!.verticalAccuracy.toStringAsFixed(3)}';
    final satellitesInView =
        '${nmeaLocation!.satellites.length} satellites are in view.';

    final children = [
      Text(accuracy),
      Text(satellitesInView),
    ];

    final navigationSystems = <String>{};
    final satelliteIds = <int>[];
    if (nmeaSatelliteInfos.isNotEmpty) {
      for (final satellite in nmeaSatelliteInfos) {
        // Navigation system.
        navigationSystems.add(satellite.system.toString());
        // Satellite Ids.
        satelliteIds.add(satellite.id);
      }

      children.add(Text('System(s): ${navigationSystems.join(', ')}'));
      children.add(Text('IDs: ${satelliteIds.join(', ')}'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
