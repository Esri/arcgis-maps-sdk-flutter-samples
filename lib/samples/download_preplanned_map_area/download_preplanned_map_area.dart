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
import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_state_support.dart';

class DownloadPreplannedMapArea extends StatefulWidget {
  const DownloadPreplannedMapArea({super.key});

  @override
  State<DownloadPreplannedMapArea> createState() =>
      _DownloadPreplannedMapAreaState();
}

class _DownloadPreplannedMapAreaState extends State<DownloadPreplannedMapArea>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Prepare an offline map task and map for the online web map.
  late OfflineMapTask _offlineMapTask;
  late ArcGISMap _webMap;
  // The location to save offline maps to.
  Directory? _downloadDirectory;
  // Create a Map to track preplanned map areas and their associated download jobs.
  final _preplannedMapAreas =
      <PreplannedMapArea, DownloadPreplannedOfflineMapJob?>{};
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the map selection UI should be displayed.
  var _mapSelectionVisible = false;

  @override
  void dispose() {
    // Delete downloaded offline maps on exit.
    _downloadDirectory?.deleteSync(recursive: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    // Create a button to open the map selection view.
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _mapSelectionVisible = true),
                      child: const Text('Select Map'),
                    ),
                  ],
                ),
              ],
            ),
            // Display the name of the current map.
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // Use the name of the item if available.
                    _mapViewController.arcGISMap?.item?.title ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
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
      // Display a list of available maps in a bottom sheet.
      bottomSheet:
          _mapSelectionVisible ? buildMapSelectionSheet(context) : null,
    );
  }

  void onMapViewReady() async {
    // Configure the directory to download offline maps to.
    _downloadDirectory = await createDownloadDirectory();

    // Create a map using a webmap from a portal item.
    final portal = Portal.arcGISOnline();
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: 'acc027394bc84c2fb04d1ed317aac674',
    );
    _webMap = ArcGISMap.withItem(portalItem);

    // Create and load an offline map task using the portal item.
    _offlineMapTask = OfflineMapTask.withPortalItem(portalItem);
    await _offlineMapTask.load();

    // Get the preplanned map areas from the offline map task and load each.
    final preplannedMapAreas = await _offlineMapTask.getPreplannedMapAreas();
    for (final mapArea in preplannedMapAreas) {
      await mapArea.load();
      // Add each map area as a key in the Map, setting the Job to null initially.
      _preplannedMapAreas[mapArea] = null;
    }

    // Initially set the web map to the map view controller.
    _mapViewController.arcGISMap = _webMap;

    // Upate the state with the preplanned map areas and set the UI state to ready.
    setState(() => _ready = true);
  }

  // Builds a map selection widget with a list of available maps.
  Widget buildMapSelectionSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
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
              Text('Select Map', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _mapSelectionVisible = false),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          // Create a list tile for the web map.
          ListTile(
            title: const Text('Web Map (online)'),
            trailing: _mapViewController.arcGISMap == _webMap
                ? const Icon(Icons.check)
                : null,
            onTap: () => _mapViewController.arcGISMap != _webMap
                ? setMapAndViewpoint(_webMap)
                : null,
          ),
          const SizedBox(height: 20.0),
          Text(
            'Preplanned Map Areas:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20.0),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _preplannedMapAreas.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
                child: buildMapAreaListTile(
                  _preplannedMapAreas.keys.toList()[index],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Builds a list tile for each preplanned area and updates the UI depending on the status of the job.
  Widget buildMapAreaListTile(PreplannedMapArea mapArea) {
    final title = Text(mapArea.portalItem.title);
    final job = _preplannedMapAreas[mapArea];

    // If a job has been associated with the preplanned area, check the status and display the relevant UI.
    if (job != null) {
      if (job.status == JobStatus.started) {
        return ListTile(
          enabled: false,
          title: title,
          trailing: Column(
            children: [
              // When the job is started, display the progress.
              CircularProgressIndicator(value: job.progress.toDouble() / 100.0),
              Text('${job.progress}%'),
            ],
          ),
        );
      } else if (job.status == JobStatus.succeeded && job.result != null) {
        // When the job has succeeded, get the result and then get the map from the result.
        final map = job.result!.offlineMap;
        return ListTile(
          title: title,
          trailing: _mapViewController.arcGISMap == map
              ? const Icon(Icons.check)
              : null,
          onTap: () => setMapAndViewpoint(map),
        );
      } else if (job.status == JobStatus.failed) {
        return ListTile(
          enabled: false,
          title: title,
          trailing: const Icon(Icons.error),
        );
      }
    }

    // Otherwise display a default list tile to initiate downloading the offline map.
    return ListTile(
      title: title,
      trailing: const Icon(Icons.download),
      onTap: () => downloadOfflineMap(mapArea),
    );
  }

  // Download an offline map for a provided preplanned map area.
  void downloadOfflineMap(PreplannedMapArea mapArea) async {
    // Create default parameters using the map area.
    final defaultDownloadParams = await _offlineMapTask
        .createDefaultDownloadPreplannedOfflineMapParameters(
      preplannedMapArea: mapArea,
    );

    // Set the required update mode. This sample map is not setup for updates so we use noUpdates.
    defaultDownloadParams.updateMode = PreplannedUpdateMode.noUpdates;

    // Create a directory for the map in the downloads directory.
    final mapDir = Directory(
      '${_downloadDirectory!.path}${Platform.pathSeparator}${mapArea.portalItem.title}',
    );
    mapDir.createSync();

    // Create and run a job to download the offline map using the default params and download path.
    final downloadMapJob =
        _offlineMapTask.downloadPreplannedOfflineMapWithParameters(
      parameters: defaultDownloadParams,
      downloadDirectoryUri: mapDir.uri,
    );

    // Associate the job with the map area and update the UI.
    setState(() => _preplannedMapAreas[mapArea] = downloadMapJob);
    // Update the UI when the progress changes.
    downloadMapJob.onProgressChanged.listen((_) => setState(() {}));
    downloadMapJob.run();
  }

  // Create the directory for downloading offline map areas into.
  Future<Directory> createDownloadDirectory() async {
    final documentDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(
      '${documentDir.path}${Platform.pathSeparator}preplanned_map_sample',
    );
    if (downloadDir.existsSync()) {
      downloadDir.deleteSync(recursive: true);
    }
    downloadDir.createSync();
    return downloadDir;
  }

  // Sets the provided map to the map view and updates the viewpoint.
  void setMapAndViewpoint(ArcGISMap map) {
    // Set the map to the map view and update the UI to reflect the newly selected map.
    _mapViewController.arcGISMap = map;
    setState(() {});

    if (map != _webMap) {
      // If the map is one of the offline maps,
      // build an envelope zoomed into the extent of the map to better see the features.
      final envBuilder = EnvelopeBuilder.fromEnvelope(
        map.initialViewpoint!.targetGeometry.extent,
      )..expandBy(0.5);
      final viewpoint = Viewpoint.fromTargetExtent(envBuilder.toGeometry());
      // Set the viewpoint to the mapview controller.
      _mapViewController.setViewpoint(viewpoint);
    }
  }
}
