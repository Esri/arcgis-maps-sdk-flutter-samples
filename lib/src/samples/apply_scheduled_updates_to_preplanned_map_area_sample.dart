//
// COPYRIGHT © 2024 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
//

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:path_provider/path_provider.dart';
import '../sample_data.dart';

class ApplyScheduledUpdatesToPreplannedMapAreaSample extends StatefulWidget {
  const ApplyScheduledUpdatesToPreplannedMapAreaSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ApplyScheduledUpdatesToPreplannedMapAreaState createState() =>
      ApplyScheduledUpdatesToPreplannedMapAreaState();
}

class ApplyScheduledUpdatesToPreplannedMapAreaState
    extends State<ApplyScheduledUpdatesToPreplannedMapAreaSample> {
  final _mapViewController = ArcGISMapView.createController();
  var _isInitialized = false;
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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            SizedBox(
              height: 75,
              child: Row(
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
                      onPressed: _canUpdate ? syncUpdates : null,
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    await prepareData();
    _isInitialized = await loadMapPackageMap();

    checkForUpdates();
  }

  Future<void> prepareData() async {
    await downloadSampleData(['740b663bff5e4198b9b6674af93f638a']);
    final appDir = await getApplicationDocumentsDirectory();
    _dataUri = Uri.parse('${appDir.absolute.path}/canyonlands');
  }

  Future<bool> loadMapPackageMap() async {
    _offlineMapSyncTask = null;

    _mobileMapPackage = MobileMapPackage.withFileUri(_dataUri);
    try {
      await _mobileMapPackage!.load();
    } catch (err) {
      showAlertDialog(
        'Mobile Map Package failed to load with error: {$err}',
        title: 'Error',
      );
      return false;
    }

    if (_mobileMapPackage!.maps.isEmpty) {
      showAlertDialog('Mobile map package contains no maps.');
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
    if (!_isInitialized) return;
    final updatesInfo = await _offlineMapSyncTask!.checkForUpdates();

    setState(() {
      _updateStatus = updatesInfo.downloadAvailability;
      _updateSizeKB = updatesInfo.scheduledUpdatesDownloadSize / 1024;
      _canUpdate = updatesInfo.downloadAvailability ==
          OfflineUpdateAvailability.available;
    });
  }

  void syncUpdates() {
    if (!_isInitialized) return;
    setState(() => _canUpdate = false);

    final mapSyncJob =
        _offlineMapSyncTask!.syncOfflineMap(parameters: _mapSyncParameters!);

    mapSyncJob.run().then((value) async {
      final result = mapSyncJob.result!;
      if (result.isMobileMapPackageReopenRequired) {
        _mobileMapPackage?.close();
        _mobileMapPackage = null;
        _isInitialized = await loadMapPackageMap();
      }
      // Refresh the update status
      checkForUpdates();
    }, onError: (err) {
      showAlertDialog(
        'The offline map sync failed with error: {$err}.',
        title: 'Error',
      );
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
