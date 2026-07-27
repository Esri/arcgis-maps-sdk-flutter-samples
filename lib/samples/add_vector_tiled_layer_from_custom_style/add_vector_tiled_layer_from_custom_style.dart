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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddVectorTiledLayerFromCustomStyle extends StatefulWidget {
  const AddVectorTiledLayerFromCustomStyle({super.key});

  @override
  State<AddVectorTiledLayerFromCustomStyle> createState() =>
      _AddVectorTiledLayerFromCustomStyleState();
}

class _AddVectorTiledLayerFromCustomStyleState
    extends State<AddVectorTiledLayerFromCustomStyle>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Cache style layers to avoid recreating them for repeated selections.
  final _vectorTiledLayers = <String, ArcGISVectorTiledLayer>{};

  // Keep the online style labels and associated ArcGIS Online item IDs.
  static const _onlineStyles = <String, String>{
    'Default': '1349bfa0ed08485d8a92c442a3850b06',
    'Style 1': 'bd8ac41667014d98b933e97713ba8377',
    'Style 2': '02f85ec376084c508b9c8e5a311724fa',
    'Style 3': '1bf0cc4a4380468fbbff107e100f65a5',
  };

  // Keep the offline style labels and associated ArcGIS Online item IDs.
  static const _offlineStyles = <String, String>{
    'Light': 'e01262ef2a4f4d91897d9bbd3a9b1075',
    'Dark': 'ce8a34e5d4ca4fa193a097511daa8855',
  };

  // Track the selected style label.
  var _selectedStyleLabel = 'Default';

  // Store the URI of the downloaded local vector tile package.
  Uri? _vtpkUri;

  // Keep a temporary folder for exported style resources.
  late final Uri _temporaryDirectoryUri;

  // Track whether initial setup has completed.
  var _ready = false;

  // Track whether style loading work is in progress.
  var _isBusy = false;

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
                  // Add the map view and connect lifecycle callbacks.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: _onMapViewReady,
                  ),
                ),
                // Add a style picker to switch between online and offline styles.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Style'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedStyleLabel,
                      onChanged: (_ready && !_isBusy)
                          ? (value) {
                              if (value == null ||
                                  value == _selectedStyleLabel) {
                                return;
                              }
                              _applyStyleSelection(value).ignore();
                            }
                          : null,
                      items: [..._onlineStyles.keys, ..._offlineStyles.keys]
                          .map((label) {
                            return DropdownMenuItem<String>(
                              value: label,
                              child: Text(label),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator while setup or style loading runs.
            LoadingIndicator(visible: !_ready || _isBusy),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Remove temporary exported resources when the sample is disposed.
    final directory = Directory.fromUri(_temporaryDirectoryUri);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
    super.dispose();
  }

  Future<void> _onMapViewReady() async {
    // Create a temporary directory for exported style resources.
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'add_vector_tiled_layer_from_custom_style_',
    );
    _temporaryDirectoryUri = temporaryDirectory.uri;

    // Resolve the local vector tile package from downloadable resources.
    final listPaths = GoRouter.of(context).state.extra as List<String>?;
    if (listPaths == null || listPaths.isEmpty) {
      showMessageDialog(
        'The required offline vector tile package is unavailable.',
        title: 'Missing Data',
      );
      return;
    }
    _vtpkUri = Uri.file(listPaths.first);

    // Create an empty map and set it on the map view.
    final map = ArcGISMap();
    _mapViewController.arcGISMap = map;

    // Apply the default style when the map view is ready.
    await _applyStyleSelection(_selectedStyleLabel);

    // Mark setup complete so the style picker can be used.
    setState(() => _ready = true);
  }

  Future<void> _applyStyleSelection(String styleLabel) async {
    // Block interactions while creating or loading the selected style.
    setState(() {
      _isBusy = true;
      _selectedStyleLabel = styleLabel;
    });

    try {
      // Get a cached layer or create and cache one.
      final layer =
          _vectorTiledLayers[styleLabel] ??
          await _createAndCacheVectorTiledLayer(styleLabel);

      // Create and apply a basemap from the selected vector tiled layer.
      final basemap = Basemap.withBaseLayer(layer);
      _mapViewController.arcGISMap?.basemap = basemap;

      // Apply a viewpoint that matches the selected style type.
      if (_offlineStyles.containsKey(styleLabel)) {
        _mapViewController.setViewpoint(
          Viewpoint.withLatLongScale(
            latitude: 37.76528,
            longitude: -100.01766,
            scale: 40000,
          ),
        );
      } else {
        _mapViewController.setViewpoint(
          Viewpoint.fromCenter(
            ArcGISPoint(
              x: 1990591.559979,
              y: 794036.007991,
              spatialReference: SpatialReference.webMercator,
            ),
            scale: 100000000,
          ),
        );
      }
    } on ArcGISException catch (e) {
      // Show ArcGIS runtime failures.
      showMessageDialog(e.message, title: 'ArcGIS Error');
    } on Exception catch (e) {
      // Show non-ArcGIS failures.
      showMessageDialog(e.toString(), title: 'Error');
    } finally {
      // Re-enable interactions after style work completes.
      setState(() => _isBusy = false);
    }
  }

  Future<ArcGISVectorTiledLayer> _createAndCacheVectorTiledLayer(
    String styleLabel,
  ) async {
    // Resolve the layer source using online or offline style item IDs.
    final ArcGISVectorTiledLayer layer;
    if (_onlineStyles.containsKey(styleLabel)) {
      layer = _createOnlineVectorTiledLayer(_onlineStyles[styleLabel]!);
    } else {
      layer = await _createOfflineVectorTiledLayer(_offlineStyles[styleLabel]!);
    }

    // Load the layer before assigning it to a map.
    await layer.load();

    // Cache the layer for later reuse.
    _vectorTiledLayers[styleLabel] = layer;
    return layer;
  }

  ArcGISVectorTiledLayer _createOnlineVectorTiledLayer(String itemId) {
    // Create a portal item for an ArcGIS Online vector style.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: itemId,
    );

    // Create a vector tiled layer from the online style item.
    return ArcGISVectorTiledLayer.withItem(portalItem);
  }

  Future<ArcGISVectorTiledLayer> _createOfflineVectorTiledLayer(
    String styleItemId,
  ) async {
    // Read the local vector tile package URI provided by downloadable resources.
    final vtpkUri = _vtpkUri;
    if (vtpkUri == null) {
      throw Exception('The local vector tile package is not available.');
    }

    // Create a portal item and export task for the selected style item.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: styleItemId,
    );
    final exportTask = ExportVectorTilesTask.withPortalItem(portalItem);

    // Export only style resources into a per-style temporary folder.
    final styleFolder = Directory.fromUri(
      _temporaryDirectoryUri.resolve('$styleItemId/'),
    )..createSync(recursive: true);
    final job = exportTask.exportStyleResourceCache(
      itemResourceCacheUri: styleFolder.uri,
    );
    final result = await job.run();
    final itemResourceCache = result.itemResourceCache;
    if (itemResourceCache == null) {
      throw Exception(
        'Failed to export style resources for the selected style.',
      );
    }

    // Create a vector tile cache from the downloaded local package.
    final vectorTileCache = VectorTileCache(fileUri: vtpkUri);

    // Create a vector tiled layer from tile and style caches.
    return ArcGISVectorTiledLayer.withVectorTileCache(
      vectorTileCache,
      itemResourceCache: itemResourceCache,
    );
  }
}
