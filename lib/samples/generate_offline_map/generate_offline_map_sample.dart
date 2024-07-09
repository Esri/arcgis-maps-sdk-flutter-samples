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
  final _regionGraphic = Graphic();
  final _graphicsOverlay = GraphicsOverlay();
  late final ArcGISMap _map;
  late final OfflineMapTask _offlineMapTask;
  double? _progress;
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
                    ElevatedButton(
                      onPressed: _offline ? null : takeOffline,
                      child: _progress == null
                          ? const Text('Take Offline')
                          : Text('${(_progress! * 100).round()}%'),
                    ),
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
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    //fixme comments
    //fixme README/metadata

    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: 'acc027394bc84c2fb04d1ed317aac674',
    );
    _map = ArcGISMap.withItem(portalItem);
    _mapViewController.arcGISMap = _map;

    _regionGraphic.symbol = SimpleLineSymbol(color: Colors.red, width: 2.0);
    _graphicsOverlay.graphics.add(_regionGraphic);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);
    _mapViewController.onViewpointChanged.listen((_) {
      if (_mapViewController.visibleArea == null) return;

      final regionGeometry = GeometryEngine.scale(
        geometry: _mapViewController.visibleArea!.extent,
        scaleX: 0.9,
        scaleY: 0.9,
        origin: null,
      );
      _regionGraphic.geometry = regionGeometry;
    });

    _offlineMapTask = OfflineMapTask.withOnlineMap(_map);

    setState(() => _ready = true);
  }

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

    setState(() => _ready = false);

    final minScale = _mapViewController.scale;
    final maxScale = _mapViewController.arcGISMap?.maxScale ?? minScale + 1;

    final parameters =
        await _offlineMapTask.createDefaultGenerateOfflineMapParameters(
      areaOfInterest: _regionGraphic.geometry!,
      minScale: minScale,
      maxScale: maxScale,
    );
    parameters.continueOnErrors = false;
    final downloadDirectoryUri = await prepareEmptyDownloadDirectory();
    final generateOfflineJob = _offlineMapTask.generateOfflineMap(
      downloadDirectoryUri: downloadDirectoryUri,
      parameters: parameters,
    );
    generateOfflineJob.onProgressChanged.listen((progress) {
      setState(() => _progress = progress / 100.0);
    });

    final result = await generateOfflineJob.run();
    _mapViewController.arcGISMap = result.offlineMap;

    _graphicsOverlay.graphics.clear();

    setState(() {
      _progress = null;
      _offline = true;
      _ready = true;
    });
  }

  void reset() async {
    _mapViewController.arcGISMap = _map;
    _graphicsOverlay.graphics.add(_regionGraphic);
    await prepareEmptyDownloadDirectory();
    setState(() => _offline = false);
  }
}
