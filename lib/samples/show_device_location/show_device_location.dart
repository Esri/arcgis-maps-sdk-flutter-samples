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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class ShowDeviceLocation extends StatefulWidget {
  const ShowDeviceLocation({super.key});

  @override
  State<ShowDeviceLocation> createState() => _ShowDeviceLocationState();
}

class _ShowDeviceLocationState extends State<ShowDeviceLocation>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;

  // Create the system location data source.
  final _locationDataSource = SystemLocationDataSource();

  // A subscription to receive status changes of the location data source.
  StreamSubscription? _statusSubscription;
  var _status = LocationDataSourceStatus.stopped;

  // A subscription to receive changes to the auto-pan mode.
  StreamSubscription? _autoPanModeSubscription;
  var _autoPanMode = LocationDisplayAutoPanMode.recenter;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void dispose() {
    // When exiting, stop the location data source and cancel subscriptions.
    _locationDataSource.stop();
    _statusSubscription?.cancel();
    _autoPanModeSubscription?.cancel();

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
                Center(
                  child: ElevatedButton(
                    onPressed:
                        _status == LocationDataSourceStatus.failedToStart
                            ? null
                            : () => setState(() => _settingsVisible = true),
                    child: const Text('Location Settings'),
                  ),
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

  // The build method for the Geometry Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        max(
          20,
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
              // A switch to start and stop the location data source.
              Switch(
                value: _status == LocationDataSourceStatus.started,
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
          Row(
            children: [
              const Text('Auto-Pan Mode'),
              const Spacer(),
              // A dropdown menu to select the auto-pan mode.
              DropdownMenu(
                initialSelection: _autoPanMode,
                onSelected: (value) {
                  _mapViewController.locationDisplay.autoPanMode = value!;
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: LocationDisplayAutoPanMode.off,
                    label: 'Off',
                  ),
                  DropdownMenuEntry(
                    value: LocationDisplayAutoPanMode.recenter,
                    label: 'Recenter',
                  ),
                  DropdownMenuEntry(
                    value: LocationDisplayAutoPanMode.navigation,
                    label: 'Navigation',
                  ),
                  DropdownMenuEntry(
                    value: LocationDisplayAutoPanMode.compassNavigation,
                    label: 'Compass',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the Navigation Night basemap style.
    _mapViewController.arcGISMap = ArcGISMap.withBasemapStyle(
      BasemapStyle.arcGISNavigationNight,
    );

    // Set the initial system location data source and auto-pan mode.
    _mapViewController.locationDisplay.dataSource = _locationDataSource;
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.recenter;

    // Subscribe to status changes and changes to the auto-pan mode.
    _statusSubscription = _locationDataSource.onStatusChanged.listen((status) {
      setState(() => _status = status);
    });
    setState(() => _status = _locationDataSource.status);
    _autoPanModeSubscription = _mapViewController
        .locationDisplay
        .onAutoPanModeChanged
        .listen((mode) {
          setState(() => _autoPanMode = mode);
        });
    setState(
      () => _autoPanMode = _mapViewController.locationDisplay.autoPanMode,
    );

    // Attempt to start the location data source (this will prompt the user for permission).
    try {
      await _locationDataSource.start();
    } on ArcGISException catch (e) {
      showMessageDialog(e.message);
    }

    // Set the ready state variable to true to enable the UI.
    setState(() => _ready = true);
  }
}
