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

class DownloadVectorTilesToLocalCache extends StatefulWidget {
  const DownloadVectorTilesToLocalCache({super.key});

  @override
  State<DownloadVectorTilesToLocalCache> createState() =>
      _DownloadVectorTilesToLocalCacheState();
}

class _DownloadVectorTilesToLocalCacheState
    extends State<DownloadVectorTilesToLocalCache> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A instance of the ExportVectorTilesJob.
  ExportVectorTilesJob? _exportVectorTilesJob;
  // A progress number for the download job.
  var _progress = 0.0;
  // A flag to indicate if the preview map is open.
  var _previewMap = false;
  // A flag to indicate if the download job has started.
  var _isJobStarted = false;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A key to access the map view widget.
  final _mapKey = GlobalKey();
  // A key to be used when converting screen locations to map coordinates.
  final _outlineKey = GlobalKey();

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
                  child: Stack(
                    children: [
                      // Add a map view to the widget tree and set a controller.
                      ArcGISMapView(
                        key: _mapKey,
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                      ),
                      // Add a red outline that marks the region to be taken offline.
                      Visibility(
                        visible: !_previewMap,
                        child: buildRedOutline(),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: _previewMap
                      ? ElevatedButton(
                          onPressed: closePreviewVectorTiles,
                          child: const Text('Close Preview Vector Tiles'),
                        )
                      : ElevatedButton(
                          onPressed:
                              _isJobStarted ? null : startDownloadVectorTiles,
                          child: const Text('Download Vector Tiles'),
                        ),
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
            // Display a progress indicator and a cancel button during the offline map generation.
            Visibility(
              visible: _isJobStarted,
              child: Center(
                child: buildProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // the method to be called when the map view is ready
  void onMapViewReady() {
    // disable the map view's rotation.
    _mapViewController.interactionOptions.rotateEnabled = false;

    setupInitialMapView();
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Set up the initial map view.
  void setupInitialMapView() {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    _mapViewController.arcGISMap = map;
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
  }

  // After the tiles caches are previewed, reset the map into initial state.
  void closePreviewVectorTiles() {
    setupInitialMapView();
    setState(() => _previewMap = false);
    setState(() => _isJobStarted = false);
  }

  // Cancel the export vector tiles job.
  void cancelDownloadingJob() async {
    setState(() => _progress = 0.0);
    setState(() => _isJobStarted = false);

    // Cancel the export vector tiles job, the job status will be failed.
    // The status listener will popup a dialog to show the error message.
    await _exportVectorTilesJob?.cancel();
  }

  // Start to download the vector tiles for the outlined region.
  void startDownloadVectorTiles() async {
    // Get the download area.
    final downloadArea = downloadAreaEnvelope();
    // Get the ArcGISVectorTiledLayer which the vector tiles cache will be downloaded from.
    final layer = _mapViewController.arcGISMap?.basemap?.baseLayers.first;
    if (downloadArea == null ||
        layer == null ||
        layer is! ArcGISVectorTiledLayer ||
        layer.uri == null) {
      _showErrorDialog('Invalid download area or layer');
      return;
    }

    // Show the progress indicator to start the download process.
    setState(() => _isJobStarted = true);

    // Create an export vector tiles task.
    final vectorTilesExportTask = ExportVectorTilesTask.withUri(layer.uri!);
    await vectorTilesExportTask.load();

    // Get the cache directory to store the downloaded vector tiles
    final resourceDirectory = await _getDownloadDirectory();
    final vtpkFile = File(
      '$resourceDirectory${Platform.pathSeparator}myTileCacheDownload.vtpk',
    );

    // Create the default export vector tiles parameters,
    // and shrink the area of interest by 10%.
    final exportVectorTilesParameters =
        await vectorTilesExportTask.createDefaultExportVectorTilesParameters(
      areaOfInterest: downloadArea,
      maxScale: _mapViewController.scale * 0.1,
    );

    // Create the export vector tiles job.
    _exportVectorTilesJob =
        vectorTilesExportTask.exportVectorTilesWithItemResourceCache(
      parameters: exportVectorTilesParameters,
      vectorTileCacheUri: vtpkFile.uri,
      itemResourceCacheUri: Uri.directory(resourceDirectory),
    );

    // Listen to the job's progress.
    _exportVectorTilesJob?.onProgressChanged.listen(
      (progress) {
        setState(() => _progress = progress * 0.01);
      },
    );

    try {
      // Start the export vector tiles job.
      final result = await _exportVectorTilesJob?.run();

      // If the job succeeded, load the downloaded caches into the map view.
      _loadExportedVectorTiles(result);
    } on ArcGISException catch (e) {
      _showErrorDialog(e.message);
    } finally {
      _exportVectorTilesJob = null;
    }
    // Dismiss the progress indicator.
    setState(() {
      _isJobStarted = false;
      _progress = 0.0;
    });
  }

  // Show an error dialog.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Info', style: Theme.of(context).textTheme.titleMedium),
        content: Text(
          'Failed to download vector tiles:\n$message',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Calculate the Envelope of the outlined region.
  Envelope? downloadAreaEnvelope() {
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    // Get the global screen rect of the outlined region.
    final outlineRenderBox = outlineContext.findRenderObject() as RenderBox;
    final outlineGlobalScreenRect =
        outlineRenderBox.localToGlobal(Offset.zero) & outlineRenderBox.size;

    // Convert the global screen rect to a rect local to the map view.
    final mapRenderBox = mapContext.findRenderObject() as RenderBox;
    final mapLocalScreenRect =
        outlineGlobalScreenRect.shift(-mapRenderBox.localToGlobal(Offset.zero));

    // Convert the local screen rect to map coordinates.
    final locationTopLeft =
        _mapViewController.screenToLocation(screen: mapLocalScreenRect.topLeft);
    final locationBottomRight = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.bottomRight,
    );
    if (locationTopLeft == null || locationBottomRight == null) return null;

    // Create an Envelope from the map coordinates.
    return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  }

  // Create a directory to store the downloaded vector tiles.
  Future<String> _getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final resourceDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}StyleItemResources',
    );
    if (resourceDirectory.existsSync()) {
      resourceDirectory.deleteSync(recursive: true);
    }
    resourceDirectory.createSync(recursive: true);

    return resourceDirectory.path;
  }

  // Load the downloaded vector tiles into the map view.
  void _loadExportedVectorTiles(ExportVectorTilesResult? result) {
    final vectorTilesCache = result?.vectorTileCache;
    final itemResourceCache = result?.itemResourceCache;
    if (vectorTilesCache == null || itemResourceCache == null) {
      _showErrorDialog('Invalid vector tiles cache or item resource cache');
      return;
    }
    // Create a new vector tile layer with the downloaded vector tiles.
    final vectorTileLayer = ArcGISVectorTiledLayer.withVectorTileCache(
      vectorTilesCache,
      itemResourceCache: itemResourceCache,
    );
    // display the vector tile layer as a basemap layer in the map view.
    _mapViewController.arcGISMap = ArcGISMap.withBasemap(
      Basemap.withBaseLayer(
        vectorTileLayer,
      ),
    );
    // Display the preview map button.
    setState(() => _previewMap = true);
  }

  // Return a Widget with a red outline.
  Widget buildRedOutline() {
    return IgnorePointer(
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 50.0),
          child: Container(
            key: _outlineKey,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Return a Widget with a linear progress bar.
  Widget buildProgressIndicator() {
    return Container(
      color: Colors.white,
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.6),
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
            '${(_progress * 100).toStringAsFixed(0)}% completed',
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
            onPressed: cancelDownloadingJob,
            child: const Text('Cancel Job'),
          ),
        ],
      ),
    );
  }
}
