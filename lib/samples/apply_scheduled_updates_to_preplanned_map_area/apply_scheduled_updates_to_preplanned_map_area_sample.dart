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
  final _mapViewController = ArcGISMapView.createController();
  var _ready = false;
  var _canUpdate = false;
  var _updateStatus = OfflineUpdateAvailability.indeterminate;
  var _updateSizeKB = 0.0;
  OfflineMapSyncTask? _offlineMapSyncTask;
  MobileMapPackage? _mobileMapPackage;
  OfflineMapSyncParameters? _mapSyncParameters;
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
                        onPressed: _canUpdate ? syncUpdates : resetMapPackage,
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

    checkForUpdates();
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
    if (!_ready) return;
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
    setState(() => _ready = false);
    _mobileMapPackage?.close();
    _mobileMapPackage = null;

    final archivePath = '${_dataUri.path}.zip';
    final archiveFile = File.fromUri(Uri.parse(archivePath));
    await extractZipArchive(archiveFile);
    await loadMapPackageMap();

    await checkForUpdates();
    setState(() => _ready = true);
  }

  void syncUpdates() {
    if (!_ready) return;
    setState(() => _canUpdate = false);

    final mapSyncJob =
        _offlineMapSyncTask!.syncOfflineMap(parameters: _mapSyncParameters!);

    mapSyncJob.run().then((value) async {
      setState(() => _ready = false);
      final result = mapSyncJob.result!;
      if (result.isMobileMapPackageReopenRequired) {
        _mobileMapPackage?.close();
        _mobileMapPackage = null;
        await loadMapPackageMap();
        setState(() => _ready = true);
      }
      // Refresh the update status
      checkForUpdates();
    }, onError: (err) {
      if (mounted) {
        showAlertDialog(
          'The offline map sync failed with error: {$err}.',
          title: 'Error',
        );
      }
    });
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
