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

import '../../utils/sample_state_support.dart';

class GenerateOfflineMapSample extends StatefulWidget {
  const GenerateOfflineMapSample({super.key});

  @override
  State<GenerateOfflineMapSample> createState() =>
      _GenerateOfflineMapSampleState();
}

class _GenerateOfflineMapSampleState extends State<GenerateOfflineMapSample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a Graphic to show the area to be taken offline.
  final _regionGraphic = Graphic();
  // Create a GraphicsOverlay to display the Graphic.
  final _graphicsOverlay = GraphicsOverlay();
  // Declare a map to be loaded later.
  late final ArcGISMap _map;
  // Declare the OfflineMapTask.
  late final OfflineMapTask _offlineMapTask;
  //fixme comment
  GenerateOfflineMapJob? _generateOfflineMapJob;
  // Progress of the OfflineMapTask.
  int? _progress;
  // A flag for when the map is viewing offline data.
  var _offline = false;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
                    // Add a button to take the outlined region offline.
                    ElevatedButton(
                      onPressed:
                          _progress != null || _offline ? null : takeOffline,
                      child: const Text('Take Map Offline'),
                    ),
                    // Add a button to reset the map to its original state.
                    ElevatedButton(
                      onPressed: _offline ? reset : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
            //fixme comments
            Visibility(
              visible: _progress != null,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_progress%'),
                      LinearProgressIndicator(
                        value: _progress != null ? _progress! / 100.0 : 0.0,
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () => _generateOfflineMapJob?.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create the map from a portal item.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: 'acc027394bc84c2fb04d1ed317aac674',
    );
    _map = ArcGISMap.withItem(portalItem);
    _mapViewController.arcGISMap = _map;

    // Prepare a Graphic to outline the region to be taken offline.
    _regionGraphic.symbol = SimpleLineSymbol(color: Colors.red, width: 2.0);
    _graphicsOverlay.graphics.add(_regionGraphic);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);
    // As the viewpoint changes, update the Graphic's new geometry.
    _mapViewController.onViewpointChanged.listen((_) {
      if (_mapViewController.visibleArea == null) return;
      if (_progress != null) return; //fixme refresh if cancelled

      // The region to take offline is the center 90% of the visible area.
      final regionGeometry = GeometryEngine.scale(
        geometry: _mapViewController.visibleArea!.extent,
        scaleX: 0.9,
        scaleY: 0.9,
        origin: null,
      );
      _regionGraphic.geometry = regionGeometry;
    });

    // Create an OfflineMapTask for the map.
    _offlineMapTask = OfflineMapTask.withOnlineMap(_map);

    setState(() => _ready = true);
  }

  // Create an empty directory to store the offline map.
  Future<Uri> prepareEmptyDownloadDirectory() async {
    final documentsUri = (await getApplicationDocumentsDirectory()).uri;
    final downloadDirectoryUri = documentsUri.resolve('offline_map');
    final downloadDirectory = Directory.fromUri(downloadDirectoryUri);
    if (downloadDirectory.existsSync()) {
      downloadDirectory.deleteSync(recursive: true);
    }
    downloadDirectory.createSync();
    return downloadDirectoryUri;
  }

  void takeOffline() async {
    if (_regionGraphic.geometry == null) return;

    setState(() => _progress = 0);

    // Create parameters specifying the region to take offline.
    final minScale = _mapViewController.scale;
    final maxScale = _mapViewController.arcGISMap?.maxScale ?? minScale + 1;
    final parameters =
        await _offlineMapTask.createDefaultGenerateOfflineMapParameters(
      areaOfInterest: _regionGraphic.geometry!,
      minScale: minScale,
      maxScale: maxScale,
    );
    parameters.continueOnErrors = false;

    // Prepare an empty directory to store the offline map.
    final downloadDirectoryUri = await prepareEmptyDownloadDirectory();

    // Create a job to generate the offline map.
    _generateOfflineMapJob = _offlineMapTask.generateOfflineMap(
      parameters: parameters,
      downloadDirectoryUri: downloadDirectoryUri,
    );

    // Listen for progress updates.
    _generateOfflineMapJob!.onProgressChanged.listen((progress) {
      setState(() => _progress = progress);
    });

    try {
      // Run the job.
      final result = await _generateOfflineMapJob!.run();

      // Get the offline map and display it.
      _mapViewController.arcGISMap = result.offlineMap;
      _generateOfflineMapJob = null;
    } catch (e) {
      _progress = null;
      return;
    }

    // Remove the graphic that specified the region to take offline.
    _graphicsOverlay.graphics.clear();

    setState(() {
      _progress = null;
      _offline = true;
    });
  }

  void reset() async {
    // Reset the map to its original state and delete the offline map.
    _mapViewController.arcGISMap = _map;
    _graphicsOverlay.graphics.add(_regionGraphic);
    await prepareEmptyDownloadDirectory();
    setState(() => _offline = false);
  }
}
