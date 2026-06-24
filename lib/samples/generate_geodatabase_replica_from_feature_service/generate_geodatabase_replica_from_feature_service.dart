// Copyright 2026 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/download_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

const _featureServiceUri =
    'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer';

class GenerateGeodatabaseReplicaFromFeatureService extends StatefulWidget {
  const GenerateGeodatabaseReplicaFromFeatureService({super.key});

  @override
  State<GenerateGeodatabaseReplicaFromFeatureService> createState() =>
      _GenerateGeodatabaseReplicaFromFeatureServiceState();
}

class _GenerateGeodatabaseReplicaFromFeatureServiceState
    extends State<GenerateGeodatabaseReplicaFromFeatureService>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create a key to locate the map view when converting screen coordinates.
  final _mapKey = GlobalKey();

  // Create a key to locate the outline used as the download extent.
  final _outlineKey = GlobalKey();

  // Create the geodatabase sync task from the sync-enabled feature service.
  final _geodatabaseSyncTask = GeodatabaseSyncTask.withUri(
    Uri.parse(_featureServiceUri),
  );

  // Store the map so operational layers can be swapped between online and local data.
  late ArcGISMap _map;

  // Store the current generate job so it can be canceled.
  GenerateGeodatabaseJob? _generateGeodatabaseJob;

  // Store the current geodatabase so its local resources can be closed.
  Geodatabase? _geodatabase;

  // Store job stream subscriptions so the widget can dispose of them.
  StreamSubscription<int>? _progressSubscription;

  // A message that describes the current sample state.
  var _statusMessage = 'Loading feature layers.';

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag for when a generated replica is displayed.
  var _replicaDisplayed = false;

  // A progress value for the generate geodatabase job.
  double? _progress;

  @override
  void dispose() {
    // Cancel any active job before releasing the widget state.
    _generateGeodatabaseJob?.cancel().ignore();

    // Stop listening for progress changes from the previous job.
    _progressSubscription?.cancel().ignore();

    // Close the geodatabase to release local file resources.
    _geodatabase?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
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
                      // Show the current workflow status above the map.
                      Align(
                        alignment: Alignment.topCenter,
                        child: SafeArea(
                          child: Container(
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      // Add a red outline that marks the region to generate.
                      Visibility(
                        visible: !_replicaDisplayed,
                        child: buildRedOutline(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add a button to restore the online service layers.
                      ElevatedButton(
                        onPressed: !_ready || !_replicaDisplayed
                            ? null
                            : resetMap,
                        child: const Text('Reset'),
                      ),
                      // Add a button to generate a local geodatabase replica.
                      ElevatedButton(
                        onPressed:
                            !_ready || _progress != null || _replicaDisplayed
                            ? null
                            : generateGeodatabase,
                        child: const Text('Generate Geodatabase'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a progress indicator and a cancel button during generation.
            Visibility(
              visible: _progress != null,
              child: DownloadProgressCard(
                title: 'Creating geodatabase',
                progress: _progress ?? 0,
                onCancel: () {
                  // Cancel the active generate geodatabase job.
                  _generateGeodatabaseJob?.cancel().ignore();
                },
                cancelLabel: 'Cancel Job',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Disable map rotation because the outlined download area is screen aligned.
    _mapViewController.interactionOptions.rotateEnabled = false;

    try {
      // Create the map with the local San Francisco tile package as the basemap.
      _map = await _createMap();
      _mapViewController.arcGISMap = _map;

      // Load the sync task so the feature service layer metadata is available.
      await _geodatabaseSyncTask.load();

      // Add the online feature service layers for the initial connected view.
      addOnlineFeatureLayers();

      // Zoom to the local basemap extent (San Francisco).
      final basemapExtent = _map.basemap?.baseLayers.first.fullExtent;
      if (basemapExtent != null) {
        await _mapViewController.setViewpointGeometry(
          basemapExtent,
          paddingInDiPs: 20,
        );
      }

      // Enable the sample UI after setup is complete.
      setState(() {
        _ready = true;
        _statusMessage = 'Tap the generate button to take the area offline.';
      });
    } on ArcGISException catch (e) {
      // Show ArcGIS errors raised while loading the task or map.
      showMessageDialog(e.message, title: 'Error');
    } on FileSystemException catch (e) {
      // Show local file errors raised while finding the downloaded basemap.
      showMessageDialog(e.message, title: 'Error');
    } on Exception catch (e) {
      // Show any local file or routing errors raised during setup.
      showMessageDialog(e.toString(), title: 'Error');
    }
  }

  Future<ArcGISMap> _createMap() async {
    // Read the downloaded San Francisco tile package path from the router.
    final tpkxFile = _downloadedTilePackageFile();

    // Create a tile cache and tiled layer from the local tile package.
    final tileCache = TileCache.withFileUri(tpkxFile.uri);
    await tileCache.load();
    final tiledLayer = ArcGISTiledLayer.withTileCache(tileCache);

    // Create a map that uses the local tiled layer as its basemap.
    final basemap = Basemap.withBaseLayer(tiledLayer);
    return ArcGISMap.withBasemap(basemap);
  }

  File _downloadedTilePackageFile() {
    // Download the sample data and get the file path from the router.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final tpkxFile = File(listPaths.first);
    return tpkxFile;
  }

  void addOnlineFeatureLayers() {
    // Clear operational layers before adding the connected service layers.
    _map.operationalLayers.clear();

    // Create a service feature table and feature layer for each service layer.
    final layerInfos =
        _geodatabaseSyncTask.featureServiceInfo?.layerInfos ?? [];
    final featureLayers = layerInfos.map((layerInfo) {
      final tableUri = Uri.parse('$_featureServiceUri/${layerInfo.id}');
      final table = ServiceFeatureTable.withUri(tableUri);
      return FeatureLayer.withFeatureTable(table);
    });

    // Display the online feature service layers on the map.
    _map.operationalLayers.addAll(featureLayers);
  }

  Envelope? outlineEnvelope() {
    // Get the widget contexts required to translate the outline to map coordinates.
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    // Get the global screen rectangle of the red outline.
    final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
    final outlineGlobalScreenRect =
        outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;

    // Convert the global rectangle into coordinates local to the map view.
    final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
    final mapLocalScreenRect = outlineGlobalScreenRect.shift(
      -mapRenderBox!.localToGlobal(Offset.zero),
    );

    // Convert the outline corners from screen coordinates to map locations.
    final locationTopLeft = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.topLeft,
    );
    final locationBottomRight = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.bottomRight,
    );
    if (locationTopLeft == null || locationBottomRight == null) return null;

    // Create an envelope from the two corner map points.
    return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  }

  Future<void> generateGeodatabase() async {
    // Get the area of interest from the red outline.
    final extent = outlineEnvelope();
    if (extent == null) {
      showMessageDialog('Could not determine the geodatabase extent.');
      return;
    }

    // Show job progress while the geodatabase is being generated.
    setState(() {
      _progress = 0;
      _statusMessage = 'Generating geodatabase.';
    });

    try {
      // Create default generation parameters for the outlined extent.
      final parameters = await _geodatabaseSyncTask
          .createDefaultGenerateGeodatabaseParameters(extent: extent);

      // Exclude attachments because this sample only displays offline features.
      parameters.returnAttachments = false;

      // Create a fresh path for the generated geodatabase file.
      final geodatabaseFileUri = await _createGeodatabaseFileUri();

      // Create and store the generate geodatabase job.
      _generateGeodatabaseJob = _geodatabaseSyncTask.generateGeodatabase(
        parameters: parameters,
        pathToGeodatabaseFileUri: geodatabaseFileUri,
      );

      // Listen for job progress and convert the percentage to the card value.
      _progressSubscription = _generateGeodatabaseJob!.onProgressChanged.listen(
        (progress) {
          if (mounted) setState(() => _progress = progress / 100);
        },
      );

      // Run the job and load the resulting local geodatabase.
      final geodatabase = await _generateGeodatabaseJob!.run();
      try {
        await geodatabase.load();

        // Replace the online layers with feature layers from the local geodatabase.
        displayGeodatabase(geodatabase);

        // Unregister the replica because this sample will not synchronize edits.
        try {
          await _geodatabaseSyncTask.unregisterGeodatabase(geodatabase);
        } on ArcGISException catch (e) {
          showMessageDialog(e.message, title: 'Warning');
        }
      } catch (_) {
        // Ensure local resources are released if loading/display fails.
        geodatabase.close();
        rethrow;
      }
      // Update the UI after the replica has been displayed.
      setState(() {
        _progress = null;
        _replicaDisplayed = true;
        _statusMessage = 'Generated geodatabase successfully.';
      });
    } on ArcGISException catch (e) {
      // Reset generation state if the job fails or is canceled.
      setState(() {
        _progress = null;
        _statusMessage = 'Tap the generate button to take the area offline.';
      });

      // Report failures unless the user canceled the job.
      if (e.errorType != ArcGISExceptionType.commonUserCanceled) {
        showMessageDialog(e.message, title: 'Error');
      }
    } on Exception catch (e) {
      // Reset generation state for unexpected errors (for example, local file I/O).
      setState(() {
        _progress = null;
        _statusMessage = 'Tap the generate button to take the area offline.';
      });
      showMessageDialog(e.toString(), title: 'Error');
    } finally {
      // Clear job state and progress listeners after completion.
      _generateGeodatabaseJob = null;
      await _progressSubscription?.cancel();
      _progressSubscription = null;
    }
  }

  Future<Uri> _createGeodatabaseFileUri() async {
    // Create a folder in the application documents directory for the replica.
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final replicaDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}WildfireSyncReplica',
    );

    // Delete any previous replica so the new job writes to an empty location.
    if (replicaDirectory.existsSync()) {
      replicaDirectory.deleteSync(recursive: true);
    }
    replicaDirectory.createSync(recursive: true);

    // Return the full geodatabase file URI for the generate job.
    return File(
      '${replicaDirectory.path}${Platform.pathSeparator}WildfireSync.geodatabase',
    ).uri;
  }

  void displayGeodatabase(Geodatabase geodatabase) {
    // Close any previous geodatabase before keeping the new one.
    _geodatabase?.close();
    _geodatabase = geodatabase;

    // Remove the online layers before displaying local geodatabase layers.
    _map.operationalLayers.clear();

    // Create feature layers from all feature tables in the geodatabase.
    final featureLayers = geodatabase.geodatabaseFeatureTables.map(
      FeatureLayer.withFeatureTable,
    );

    // Add the local feature layers to the map.
    _map.operationalLayers.addAll(featureLayers);
  }

  void resetMap() {
    // Close and clear the current geodatabase replica.
    _geodatabase?.close();
    _geodatabase = null;

    // Restore the original online feature service layers.
    addOnlineFeatureLayers();

    // Update the UI so a new replica can be generated.
    setState(() {
      _replicaDisplayed = false;
      _statusMessage = 'Tap the generate button to take the area offline.';
    });
  }

  Widget buildRedOutline() {
    // Prevent the outline from intercepting map gestures.
    return IgnorePointer(
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(30, 50, 30, 50),
          child: Container(
            key: _outlineKey,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
