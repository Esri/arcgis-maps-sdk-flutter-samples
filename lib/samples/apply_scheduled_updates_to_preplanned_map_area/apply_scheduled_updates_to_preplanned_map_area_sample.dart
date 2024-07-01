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

import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_data.dart';

class ApplyScheduledUpdatesToPreplannedMapAreaSample extends StatefulWidget {
  const ApplyScheduledUpdatesToPreplannedMapAreaSample({super.key});

  @override
  State<ApplyScheduledUpdatesToPreplannedMapAreaSample> createState() =>
      _ApplyScheduledUpdatesToPreplannedMapAreaSampleState();
}

class _ApplyScheduledUpdatesToPreplannedMapAreaSampleState
    extends State<ApplyScheduledUpdatesToPreplannedMapAreaSample> {
  // Create the map controller
  final _mapViewController = ArcGISMapView.createController();
  // Flag that will be set to true when all properties have been initialized
  var _ready = false;
  // Flag that indicates if the map package is actively being updated
  var _updating = false;
  // Flag indicating if an update is avalable for the map package
  var _canUpdate = false;
  // Status of the update availability
  var _updateStatus = OfflineUpdateAvailability.indeterminate;
  // Size in KB of the available update
  var _updateSizeKB = 0.0;
  // The Active mobile map package
  MobileMapPackage? _mobileMapPackage;
  // Offline task and parameters used for updating the map package
  OfflineMapSyncTask? _offlineMapSyncTask;
  OfflineMapSyncParameters? _mapSyncParameters;
  // The location of the map package on the device
  late final Uri _dataUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        onPressed: _updating
                            ? null
                            : _canUpdate
                                ? syncUpdates
                                : resetMapPackage,
                        child: _canUpdate
                            ? const Text('Update')
                            : const Text('Reset'),
                      ),
                    ),
                  ],
                )
              ],
            ),
            // Display a progress indicator and prevent interaction before state is ready
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

  Future<void> onMapViewReady() async {
    await prepareData();
    await loadMapPackageMap();
    setState(() => _ready = true);

    await checkForUpdates();
  }

  Future<void> prepareData() async {
    await downloadSampleData(['740b663bff5e4198b9b6674af93f638a'],
        replaceExisting: true);
    final appDir = await getApplicationDocumentsDirectory();
    _dataUri = Uri.parse('${appDir.absolute.path}/canyonlands');
  }

  Future<bool> loadMapPackageMap() async {
    _offlineMapSyncTask = null;

    _mobileMapPackage = MobileMapPackage.withFileUri(_dataUri);
    try {
      await _mobileMapPackage!.load();
    } catch (err) {
      if (mounted) {
        showAlertDialog(
          'Mobile Map Package failed to load with error: {$err}',
          title: 'Error',
        );
      }
      return false;
    }

    if (_mobileMapPackage!.maps.isEmpty) {
      if (mounted) {
        showAlertDialog('Mobile map package contains no maps.');
      }
      return false;
    }

    _mapViewController.arcGISMap = _mobileMapPackage!.maps.first;

    _offlineMapSyncTask =
        OfflineMapSyncTask.withMap(_mapViewController.arcGISMap!);

    _mapSyncParameters =
        await _offlineMapSyncTask!.createDefaultOfflineMapSyncParameters()
          ..syncDirection = SyncDirection.none
          ..preplannedScheduledUpdatesOption =
              PreplannedScheduledUpdatesOption.downloadAllUpdates
          ..rollbackOnFailure = true;

    return true;
  }

  Future<void> checkForUpdates() async {
    final updatesInfo = await _offlineMapSyncTask!.checkForUpdates();
    if (mounted) {
      setState(() {
        _updateStatus = updatesInfo.downloadAvailability;
        _updateSizeKB = updatesInfo.scheduledUpdatesDownloadSize / 1024;
        _canUpdate = updatesInfo.downloadAvailability ==
            OfflineUpdateAvailability.available;
      });
    }
  }

  Future<void> resetMapPackage() async {
    setState(() => _updating = true);
    // Reload the map package from the original zip file
    _mobileMapPackage?.close();
    _mobileMapPackage = null;
    final archivePath = '${_dataUri.path}.zip';
    final archiveFile = File.fromUri(Uri.parse(archivePath));
    if (archiveFile.existsSync()) {
      await extractZipArchive(archiveFile);
      await loadMapPackageMap();

      // Check for updates based on the reloaded package
      await checkForUpdates();
    }

    setState(() => _updating = false);
  }

  Future<void> syncUpdates() async {
    setState(() => _updating = true);

    final mapSyncJob =
        _offlineMapSyncTask!.syncOfflineMap(parameters: _mapSyncParameters!);

    try {
      await mapSyncJob.run();
      final result = mapSyncJob.result;
      if (result != null && result.isMobileMapPackageReopenRequired) {
        _mobileMapPackage?.close();
        _mobileMapPackage = null;
        await loadMapPackageMap();
      }
      // Refresh the update status
      await checkForUpdates();
    } catch (err) {
      if (mounted) {
        showAlertDialog(
          'The offline map sync failed with error: {$err}.',
          title: 'Error',
        );
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> showAlertDialog(String message, {String title = 'Alert'}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'))
        ],
      ),
    );
  }
}
