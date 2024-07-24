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

class DownloadVectorTilesToLocalCacheSample extends StatefulWidget {
  const DownloadVectorTilesToLocalCacheSample({super.key});

  @override
  State<DownloadVectorTilesToLocalCacheSample> createState() =>
      _DownloadVectorTilesToLocalCacheSampleState();
}

class _DownloadVectorTilesToLocalCacheSampleState
    extends State<DownloadVectorTilesToLocalCacheSample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The graphics overlay to show a red outline square around the vector tiles
  // to be downloaded
  final _downloadVectorTilesOverlay = GraphicsOverlay();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;
  var _progress = 0.0;
  final _mapKey = GlobalKey();

  var _firstTime = true;

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
                    key: _mapKey,
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: onTap,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: downloadVectorTiles,
                      child: const Text('Download Vector Tiles'),
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
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? showDownloadProgress(context) : null,
    );
  }

  void onMapViewReady() {
    // Create a map with the basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    _mapViewController.arcGISMap = map;
    _mapViewController.interactionOptions.rotateEnabled = false;
    _mapViewController.setViewpoint(
      Viewpoint.fromCenter(
        ArcGISPoint(
          x: -117.195800,
          y: 34.057386,
          spatialReference: SpatialReference.wgs84,
        ),
        scale: 100000,
      ),
    );

    // Configure the graphics overlay for the geodetic buffers.
    _downloadVectorTilesOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.red[200]!.withOpacity(0.5),
        outline: SimpleLineSymbol(
          style: SimpleLineSymbolStyle.solid,
          color: Colors.red,
          width: 2.0,
        ),
      ),
    );
    _downloadVectorTilesOverlay.opacity = 0.5;

    // Add the overlays to the map view.
    _mapViewController.graphicsOverlays.addAll(
      [
        _downloadVectorTilesOverlay,
      ],
    );
    // _mapViewController.onDrawStatusChanged.listen(
    //   (status) {
    //     if (status == DrawStatus.completed && _firstTime) {
    //       updateDownloadAreaGraphic();
    //     }
    //   },
    // );

    _mapViewController.onViewpointChanged.listen(
      (viewpoint) {
        updateDownloadAreaGraphic();
      },
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Widget showDownloadProgress(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
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
              const Text('Download Area:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.red,
                ),
              ),
              Text(': ${(_progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  void onTap(Offset screenPoint) {
    // Capture the tapped point and convert it to a map point.
    final mapPoint = _mapViewController.screenToLocation(screen: screenPoint);
    if (mapPoint == null) return;
  }

  // Download the vector tiles for the outlined region.
  void downloadVectorTiles() async {
    final downloadArea = downloadAreaEnvelope();
    final vectorTileLayer = _mapViewController.arcGISMap!.basemap!.baseLayers[0]
        as ArcGISVectorTiledLayer;
    final vectorTilesExportTask =
        ExportVectorTilesTask.withUri(vectorTileLayer.uri!);

    final exportVectorTilesParameters =
        await vectorTilesExportTask.createDefaultExportVectorTilesParameters(
      areaOfInterest: downloadArea!,
      maxScale: _mapViewController.scale * 0.1,
    );

    final directory = await getDownloadsDirectory();
    final vtpkName = '${vectorTileLayer.name}-download.vtpk';
    final resDir =
        File('${directory!.path}${Platform.pathSeparator}StyleItemResources');
    if (resDir.existsSync()) {
      resDir.deleteSync(recursive: true);
    }
    resDir.createSync();
    print(resDir.existsSync());
    if (!resDir.existsSync()) {
      resDir.createSync();
    }

    final vtpkFile = File('${resDir.path}${Platform.pathSeparator}${vtpkName}');
    print(resDir.path);
    print(vtpkFile.path);

    final downloadJob =
        vectorTilesExportTask.exportVectorTilesWithItemResourceCache(
      parameters: exportVectorTilesParameters,
      vectorTileCacheUri: vtpkFile.uri,
      itemResourceCacheUri: resDir.uri,
    );

    downloadJob.onProgressChanged.listen((progress) {
      setState(() => _progress = progress as double);
    });

    downloadJob.onJobDone.listen((_) {
      setState(() => _settingsVisible = false);
    });

    downloadJob.onStatusChanged.listen((status) {
      print(status);

      if (status == JobStatus.failed) {
        print(downloadJob.error);
        print(downloadJob.result);

        setState(() => _settingsVisible = false);
      }
    });

    downloadJob.onMessageAdded.listen((message) {
      print(message);
    });

    try {
      setState(() => _settingsVisible = true);
      downloadJob.start();
    } catch (e) {
      print(e);
    }
  }

  void updateDownloadAreaGraphic() {
    // Clear the previous download area.
    _downloadVectorTilesOverlay.graphics.clear();

    final envelope = downloadAreaEnvelope();
    if (envelope == null) return;

    // Add the square envelope to the download vector tiles overlay.
    _downloadVectorTilesOverlay.graphics.add(
      Graphic(
        geometry: envelope,
      ),
    );

    _firstTime = false;
  }

  // Calculate the Envelope of the outlined region.
  Envelope? downloadAreaEnvelope() {
    final mapContext = _mapKey.currentContext;
    if (mapContext == null) return null;

    // Convert the global screen rect to a rect local to the map view.
    final mapRenderBox = mapContext.findRenderObject() as RenderBox;
    final shrunkRect = mapRenderBox.paintBounds.shrink(0.2);

    // Convert the local screen rect to map coordinates.
    final locationTopLeft =
        _mapViewController.screenToLocation(screen: shrunkRect.topLeft);
    final locationBottomRight =
        _mapViewController.screenToLocation(screen: shrunkRect.bottomRight);
    if (locationTopLeft == null || locationBottomRight == null) return null;

    // Create an Envelope from the map coordinates.
    return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  }
}

extension on Rect {
  // Shrink the Rect by a factor of the width and height.
  Rect shrink(double factor) {
    final double shrinkWidth = width * factor;
    final double shrinkHeight = height * factor;

    // Create a new Rect with the shrunk dimensions
    return Rect.fromLTRB(
      left + shrinkWidth / 2,
      shrinkHeight / 2,
      right - shrinkWidth / 2,
      bottom - shrinkHeight / 2,
    );
  }
}
