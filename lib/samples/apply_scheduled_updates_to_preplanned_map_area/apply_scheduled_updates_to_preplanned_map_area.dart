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
import 'package:go_router/go_router.dart';

class ApplyScheduledUpdatesToPreplannedMapArea extends StatefulWidget {
  const ApplyScheduledUpdatesToPreplannedMapArea({super.key});

  @override
  State<ApplyScheduledUpdatesToPreplannedMapArea> createState() =>
      _ApplyScheduledUpdatesToPreplannedMapAreaState();
}

class _ApplyScheduledUpdatesToPreplannedMapAreaState
    extends State<ApplyScheduledUpdatesToPreplannedMapArea>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Flag indicating if an update is avalable for the map package.
  var _canUpdate = false;
  // Flag that will be set to true when all properties have been initialized.
  var _ready = false;
  // Status of the update availability.
  var _updateStatus = OfflineUpdateAvailability.indeterminate;
  // Size in KB of the available update.
  var _updateSizeKB = 0.0;
  // The Active mobile map package.
  MobileMapPackage? _mobileMapPackage;
  // Offline task and parameters used for updating the map package.
  late OfflineMapSyncTask _offlineMapSyncTask;
  late OfflineMapSyncParameters _mapSyncParameters;
  // The location of the map package on the device.
  late final Uri _dataUri;

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Updates: ${_updateStatus.name.toUpperCase()}'),
                        Text('Update Size: ${_updateSizeKB}KB'),
                      ],
                    ),
                    Center(
                      child: ElevatedButton(
                        // Disable the button if no update is available.
                        onPressed: _canUpdate ? syncUpdates : null,
                        child: const Text('Apply Updates'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction before state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    if (GoRouter.of(context).state.extra != null) {
      final listPaths = GoRouter.of(context).state.extra! as List<String>;
      _dataUri = Uri.parse(listPaths.first);
      await _loadMapPackageMap();

      // Check if there is an update for the map package.
      await _checkForUpdates();

      setState(() => _ready = true);
    }
  }

  // Perform the map data update.
  Future<void> syncUpdates() async {
    setState(() => _canUpdate = false);

    final mapSyncJob = _offlineMapSyncTask.syncOfflineMap(
      parameters: _mapSyncParameters,
    );
    try {
      await mapSyncJob.run();
      final result = mapSyncJob.result;
      if (result != null && result.isMobileMapPackageReopenRequired) {
        await _loadMapPackageMap();
      }
    } on ArcGISException catch (e) {
      showMessageDialog(
        'The offline map sync failed with error: {$e}.',
        title: 'Error',
      );
    } finally {
      // Refresh the update status.
      await _checkForUpdates();
    }
  }

  // Function to check for map package updates.
  Future<void> _checkForUpdates() async {
    final updatesInfo = await _offlineMapSyncTask.checkForUpdates();
    setState(() {
      _updateStatus = updatesInfo.downloadAvailability;
      _updateSizeKB = updatesInfo.scheduledUpdatesDownloadSize / 1024;
      _canUpdate =
          updatesInfo.downloadAvailability ==
          OfflineUpdateAvailability.available;
    });
  }

  // Load the map package into the map.
  Future<bool> _loadMapPackageMap() async {
    // Reset the map package.
    _mobileMapPackage?.close();
    _mobileMapPackage = null;
    _mobileMapPackage = MobileMapPackage.withFileUri(_dataUri);

    // Try to load the map package.
    try {
      await _mobileMapPackage!.load();
    } on ArcGISException catch (e) {
      showMessageDialog(
        'Mobile Map Package failed to load with error: {$e}',
        title: 'Error',
      );
      return false;
    }

    if (_mobileMapPackage!.maps.isEmpty) {
      showMessageDialog('Mobile map package contains no maps.');
      return false;
    }

    // Load the first map in the package.
    _mapViewController.arcGISMap = _mobileMapPackage!.maps.first;

    // Set the offline map sync task.
    _offlineMapSyncTask = OfflineMapSyncTask.withMap(
      _mapViewController.arcGISMap!,
    );

    // Set the map sync parameters.
    _mapSyncParameters =
        await _offlineMapSyncTask.createDefaultOfflineMapSyncParameters()
          ..syncDirection = SyncDirection.none
          ..preplannedScheduledUpdatesOption =
              PreplannedScheduledUpdatesOption.downloadAllUpdates
          ..rollbackOnFailure = true;

    return true;
  }
}
