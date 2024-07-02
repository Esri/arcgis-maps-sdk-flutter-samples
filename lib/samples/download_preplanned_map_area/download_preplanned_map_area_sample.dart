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

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_state_support.dart';

class DownloadPreplannedMapAreaSample extends StatefulWidget {
  const DownloadPreplannedMapAreaSample({super.key});

  @override
  State<DownloadPreplannedMapAreaSample> createState() =>
      _DownloadPreplannedMapAreaSampleState();
}

class _DownloadPreplannedMapAreaSampleState
    extends State<DownloadPreplannedMapAreaSample> with SampleStateSupport {
  final _mapViewController = ArcGISMapView.createController();
  var _preplannedAreas = <PreplannedMapArea>[];
  var _selectedPreplannedAreaIndex = -1;
  var _isLoading = false;
  OfflineMapTask? _offlineMapTask;
  final _sourceMap = ArcGISMap.withUri(Uri.parse(
      'https://arcgisruntime.maps.arcgis.com/home/item.html?id=acc027394bc84c2fb04d1ed317aac674'))!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () =>
                    _mapViewController..arcGISMap = _sourceMap,
                onMapViewReady: onMapViewReady,
              ),
            ),
            SizedBox(
              height: 235,
              width: double.infinity,
              child: _buildMapAreaList(context),
            )
          ],
        ),
      ),
    );
  }

  ListView _buildMapAreaList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _preplannedAreas.length,
      itemBuilder: (context, index) {
        final name = _preplannedAreas[index].portalItem.title;
        return Card(
          child: ListTile(
            trailing: Text((index == _selectedPreplannedAreaIndex && _isLoading)
                ? 'Loading'
                : ''),
            selected: (index == _selectedPreplannedAreaIndex),
            title: Text(name),
            onTap: () async {
              if (index == _selectedPreplannedAreaIndex) {
                return;
              }
              setState(() {
                _selectedPreplannedAreaIndex = index;
                _isLoading = true;
              });
              try {
                final map = await _downloadOfflineMap(index);
                _mapViewController.arcGISMap = map;
              } catch (e) {
                print(e);
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> onMapViewReady() async {
    await _initPreplannedMapTask(_sourceMap);
  }

  Future<void> _initPreplannedMapTask(ArcGISMap map) async {
    final offlineMapTask = OfflineMapTask.withOnlineMap(_sourceMap);
    await offlineMapTask.load();
    final preplannedAreas = await offlineMapTask.getPreplannedMapAreas();
    for (final preplannedArea in preplannedAreas) {
      await preplannedArea.load();
    }

    _offlineMapTask = offlineMapTask;
    setState(() => _preplannedAreas = preplannedAreas);
  }

  Future<ArcGISMap?> _downloadOfflineMap(int preplannedAreaIndex) async {
    if (_offlineMapTask == null) {
      return null;
    }

    final offlineMapTask = _offlineMapTask!;
    final selectedPreplannedArea = _preplannedAreas[preplannedAreaIndex];

    final downloadParams = await offlineMapTask
        .createDefaultDownloadPreplannedOfflineMapParameters(
            preplannedMapArea: selectedPreplannedArea);

    // This sample map is not setup for updates
    downloadParams.updateMode = PreplannedUpdateMode.noUpdates;

    final mapDownloadDir = await _getMapDownloadDirectory();
    final downloadMapJob =
        offlineMapTask.downloadPreplannedOfflineMapWithParameters(
            parameters: downloadParams,
            downloadDirectoryUri: mapDownloadDir.uri);

    final downloadResult = await downloadMapJob.run();

    // Return downloaded map
    if (!downloadResult.hasErrors) {
      return downloadResult.offlineMap;
    }

    return null;
  }

  Future<Directory> _getMapDownloadDirectory() async {
    final documentDir = await getApplicationDocumentsDirectory();
    final mapDir = Directory('${documentDir.path}/offline_map');
    if (mapDir.existsSync()) {
      mapDir.deleteSync(recursive: true);
    }

    mapDir.createSync();
    return mapDir;
  }
}
