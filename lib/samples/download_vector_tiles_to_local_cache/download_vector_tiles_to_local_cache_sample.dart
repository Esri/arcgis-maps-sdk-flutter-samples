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
import 'dart:io';
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
  // A progress number for the download job.
  var _progress = 0.0;
  // A instance of the ExportVectorTilesJob
  ExportVectorTilesJob? _exportVectorTilesJob;
  // A controller to emit progress values to the progress dialog
  final downloadProgressController = StreamController<double>();
  // A key to access the map view widget
  final _mapKey = GlobalKey();
  var _previewMap = false;

  final initialViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(
      x: -117.195800,
      y: 34.057386,
      spatialReference: SpatialReference.wgs84,
    ),
    scale: 100000,
  );

  @override
  void dispose() {
    downloadProgressController.close();
    super.dispose();
  }

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
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _previewMap
                        ? ElevatedButton(
                            onPressed: closePreviewVectorTiles,
                            child: const Text('Close Preview Vector Tiles'),
                          )
                        : ElevatedButton(
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

  // the method to be called when the map view is ready
  void onMapViewReady() {
    // Create a map with the basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    _mapViewController.arcGISMap = map;
    _mapViewController.interactionOptions.rotateEnabled = false;
    _mapViewController.setViewpoint(
      initialViewpoint,
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
    _mapViewController.graphicsOverlays.add(
      _downloadVectorTilesOverlay,
    );

    // Listen to the viewpoint changed event to update the download area graphic.
    _mapViewController.onViewpointChanged.listen(
      (viewpoint) {
        updateDownloadAreaGraphic();
      },
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Show a dialog with a progress indicator.
  void _showDownloadProgressDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProgressWidget(
          stream: downloadProgressController.stream,
          cancel: cancel,
        );
      },
    );
  }

  // Reset the map into initial state.
  void closePreviewVectorTiles() {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    _mapViewController.arcGISMap = map;
    _mapViewController.setViewpoint(
      initialViewpoint,
    );
    if (_mapViewController.graphicsOverlays.isEmpty) {
      _mapViewController.graphicsOverlays.add(
        _downloadVectorTilesOverlay,
      );
    }
    setState(() => _previewMap = false);
  }

  // Cancel the export vector tiles job.
  void cancel() {
    if (_exportVectorTilesJob != null &&
        _exportVectorTilesJob?.status == JobStatus.started) {
      _exportVectorTilesJob?.cancel();
    }
  }

  // Download the vector tiles for the outlined region.
  void downloadVectorTiles() async {
    final downloadArea = downloadAreaEnvelope();
    final vectorTileLayer = _mapViewController.arcGISMap!.basemap!.baseLayers[0]
        as ArcGISVectorTiledLayer;
    final vectorTilesExportTask =
        ExportVectorTilesTask.withUri(vectorTileLayer.uri!);
    await vectorTilesExportTask.load();

    // create a temporary directory to store the downloaded vector tiles
    final resourceDirectory = await _getDownloadDirectory();
    const vtpkName = 'myTileCacheDownload.vtpk';
    final vtpkFile =
        File('$resourceDirectory${Platform.pathSeparator}${vtpkName}');

    // Create the default export vector tiles parameters,
    // and shrink the area of interest by 10%.
    final exportVectorTilesParameters =
        await vectorTilesExportTask.createDefaultExportVectorTilesParameters(
      areaOfInterest: downloadArea!,
      maxScale: _mapViewController.scale * 0.1,
    );

    // Create the export vector tiles job.
    _exportVectorTilesJob =
        vectorTilesExportTask.exportVectorTilesWithItemResourceCache(
      parameters: exportVectorTilesParameters,
      vectorTileCacheUri: vtpkFile.uri,
      itemResourceCacheUri: Uri.directory(resourceDirectory),
    );

    // Listen to the job's progress, status, and completion.
    _exportVectorTilesJob?.onProgressChanged.listen((progress) {
      _progress = progress * 0.01;
      downloadProgressController.add(_progress);
    });

    // Listen to the job's status and handle the result.
    _exportVectorTilesJob?.onStatusChanged.listen((status) {
      if (status == JobStatus.failed || status == JobStatus.canceling) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Failed to download vector tiles:'
              '${_exportVectorTilesJob?.error?.message}',
            ),
          ),
        );
      }

      if (status == JobStatus.succeeded) {
        final result = _exportVectorTilesJob?.result as ExportVectorTilesResult;
        _loadExportedVectorTiles(result);
        setState(() => _previewMap = true);
      }
    });

    // Start the export vector tiles job.
    _exportVectorTilesJob?.start();

    // Show the download progress dialog.
    _showDownloadProgressDialog();
  }

  // Update the download area graphic on the map view.
  void updateDownloadAreaGraphic() {
    if (_mapViewController.graphicsOverlays.isEmpty) return;

    // Clear the previous download area.
    _downloadVectorTilesOverlay.graphics.clear();

    final envelope = downloadAreaEnvelope();
    if (envelope != null) {
      // Add the square envelope to the download vector tiles overlay.
      _downloadVectorTilesOverlay.graphics.add(
        Graphic(
          geometry: envelope,
        ),
      );
    }
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

  // Create a directory to store the downloaded vector tiles.
  Future<String> _getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final resourceDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}StyleItemResources');
    await resourceDirectory.delete(recursive: true);
    await resourceDirectory.create(recursive: true);

    return resourceDirectory.path;
  }

  // Load the downloaded vector tiles into the map view.
  void _loadExportedVectorTiles(ExportVectorTilesResult result) {
    final vectorTilesCache = result.vectorTileCache;
    final itemResourceCache = result.itemResourceCache;
    final vectorTileLayer = ArcGISVectorTiledLayer.withVectorTileCache(
      vectorTilesCache!,
      itemResourceCache: itemResourceCache,
    );

    _mapViewController.arcGISMap = ArcGISMap.withBasemap(
      Basemap.withBaseLayer(
        vectorTileLayer,
      ),
    );
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

//
// A stateful widget to display a progress bar.
//
class ProgressWidget extends StatefulWidget {
  final Stream<double> stream;
  final Function cancel;

  ProgressWidget({required this.stream, required this.cancel});

  @override
  _ProgressWidgetState createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget>
    with SampleStateSupport {
  double _progress = 0.0;

  @override
  void initState() {
    widget.stream.listen((data) {
      _startProgress(data);
    });
    super.initState();
  }

  void _startProgress(double progress) {
    setState(() {
      _progress = progress;
      if (_progress >= 1.0) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        color: Colors.white,
        constraints: BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Downloading...',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 20),
            Text(
              '${(_progress * 100).toStringAsFixed(1)}% completed',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.cancel;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel Job'),
            ),
          ],
        ),
      ),
    );
  }
}
