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
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location_with_nmea_data_sources/simulated_nmea_data_source.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  StreamSubscription<ArcGISLocation>? _locationSubscription;
  ArcGISLocation? _currentNmeaLocation;
  StreamSubscription<List<NmeaSatelliteInfo>>? _satelliteSubscription;
  var _currentSatelliteInfos = <NmeaSatelliteInfo>[];

  // Simulated NMEA data provider members.
  SimulatedNmeaDataSource? _nmeaDataSimulator;
  StreamSubscription<String>? _nmeaDataSubscription;

  // Enable or disable the Recenter button.
  var _enableRecenter = false;
  StreamSubscription<LocationDisplayAutoPanMode>? _autopanSubscription;

  // A flag for when the NmeaLocationDataSource is running.
  var _locationDataSourceRunning = false;

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
                      onPressed:
                          _locationDataSource.status ==
                              LocationDataSourceStatus.stopped
                          ? _startDataSource
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
                    // Stop and reset the location data source.
                    ElevatedButton(
                      onPressed: _locationDataSourceRunning
                          ? _stopDataSource
                          : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
            // Widget to show top details.
            NmeaLocationDetails(
              nmeaLocation: _currentNmeaLocation,
              nmeaSatelliteInfos: _currentSatelliteInfos,
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

    // Subscribe to the location stream of the location data source.
    _locationSubscription = _locationDataSource.onLocationChanged.listen((
      location,
    ) {
      setState(() => _currentNmeaLocation = location);
    });

    // Subscribe to the location data source's satellite changed stream.
    _satelliteSubscription = _locationDataSource.onSatellitesChanged.listen((
      satelliteInfos,
    ) {
      setState(() => _currentSatelliteInfos = satelliteInfos);
    });

    // Set the autoPanMode to recenter and listen for any changes.
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.recenter;
    _autopanSubscription = _mapViewController
        .locationDisplay
        .onAutoPanModeChanged
        .listen((autoPanMode) {
          setState(() {
            // Activates/deactivates the Recenter button based on the new auto pan mode.
            _enableRecenter =
                autoPanMode != LocationDisplayAutoPanMode.recenter;
          });
        });

    // Set the ready state variable to true to enable the UI.
    setState(() => _ready = true);
  }

  Future<void> _startDataSource() async {
    final nmeaSentences = await _loadNmeaFile();

    // Create new instance of the NmeaSourceSimulator.
    _nmeaDataSimulator ??= SimulatedNmeaDataSource(nmeaSentences);

    // Subscribe to the simulator data.
    _nmeaDataSubscription ??= _nmeaDataSimulator!.nmeaMessages.listen((
      nmeaDataString,
    ) {
      final nmeaData = utf8.encoder.convert(nmeaDataString);
      _locationDataSource.pushData(nmeaData);
    });

    // Start the NMEALocationDataSource.
    await _locationDataSource.start();

    // Set the running state to enable the Reset button.
    setState(() => _locationDataSourceRunning = true);
  }

  Future<void> _stopDataSource() async {
    // Stop the location data source.
    await _locationDataSource.stop();

    // Cancel simulator subscription and remove reference to NMEA source
    // simulator and subscription.
    await _nmeaDataSubscription?.cancel();
    _nmeaDataSubscription = null;
    _nmeaDataSimulator = null;

    // Update the affected state variables.
    setState(() {
      _currentNmeaLocation = null;
      _currentSatelliteInfos = <NmeaSatelliteInfo>[];
      _locationDataSourceRunning = false;
    });
  }

  // Loads the sample NMEA data file and returns the NMEA sentences as a
  // list of Strings.
  Future<List<String>> _loadNmeaFile() async {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;

    final nmeaFile = File(listPaths.first);

    // Read and return the file as a list of String lines.
    return nmeaFile.readAsLines();
  }
}

// Widget that displays current location accuracy and NMEA satellite information.
class NmeaLocationDetails extends StatelessWidget {
  const NmeaLocationDetails({
    required this.nmeaLocation,
    required this.nmeaSatelliteInfos,
    super.key,
  });

  final ArcGISLocation? nmeaLocation;
  final List<NmeaSatelliteInfo> nmeaSatelliteInfos;

  @override
  Widget build(BuildContext context) {
    // Create list of child Widgets that will be shown in a Column.
    final children = <Widget>[];

    // If there is no location object, show placeholder text. Otherwise, compose
    // accuracy data string.
    final accuracy = nmeaLocation == null
        ? 'Accuracy will be shown here.'
        : 'Accuracy: Horizontal: ${nmeaLocation!.horizontalAccuracy.toStringAsFixed(3)}, Vertical: ${nmeaLocation!.verticalAccuracy.toStringAsFixed(3)}';
    children.add(Text(accuracy));

    // If there are no satellites, show placeholder text. Otherwise, compose the
    // Strings for satellite count, navigation systems, and IDs.
    if (nmeaSatelliteInfos.isEmpty) {
      children.add(const Text('Satellite information will be shown here.'));
    } else {
      final navigationSystems = <String>{};
      final satelliteIds = <int>[];

      for (final satellite in nmeaSatelliteInfos) {
        // Navigation system.
        navigationSystems.add(satellite.system.label);
        // Satellite Ids.
        satelliteIds.add(satellite.id);
      }

      children.add(
        Text('${nmeaSatelliteInfos.length} satellites are in view.'),
      );
      children.add(Text('System(s): ${navigationSystems.join(', ')}'));
      children.add(Text('IDs: ${satelliteIds.join(', ')}'));
    }

    // Build and return the Widget.
    return Column(
      children: [
        ColoredBox(
          color: const Color.fromARGB(200, 255, 255, 255),
          child: SafeArea(
            left: false,
            right: false,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  
}

// Extension on NmeaGnssSystem to provide a readable label.
extension on NmeaGnssSystem {
  String get label {
    switch (name) {
      case 'gps':
        return 'The Global Positioning System';
      case 'glonass':
        return 'The Russian Global Navigation Satellite System';
      case 'galileo':
        return 'The European Union Global Navigation Satellite System';
      case 'bds':
        return 'The BeiDou Navigation Satellite System';
      case 'qzss':
        return 'The Quasi-Zenith Satellite System';
      case 'navIc':
        return 'The Navigation Indian Constellation';
      default:
        return 'Unknown GNSS type';
    }
  }
}
