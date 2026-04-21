// Copyright 2025 Esri
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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IdentifyRasterCell extends StatefulWidget {
  const IdentifyRasterCell({super.key});

  @override
  State<IdentifyRasterCell> createState() => _IdentifyRasterCellState();
}

class _IdentifyRasterCellState extends State<IdentifyRasterCell>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // Raster layer to display raster data on the map.
  late RasterLayer _rasterLayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: onTap,
          ),
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the oceans basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);
    // Add map to the map view.
    _mapViewController.arcGISMap = map;
    // Load the raster layer.
    await loadRasterLayer();
    // Add the Raster Layer to the map.
    map.operationalLayers.add(_rasterLayer);
    // Set the viewpoint.
    if (_rasterLayer.fullExtent != null) {
      await _mapViewController.setViewpointGeometry(_rasterLayer.fullExtent!);
    }
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset position) async {
    // Get the result for where the user tapped on the raster layer.
    final identifyResult = await _mapViewController.identifyLayer(
      _rasterLayer,
      screenPoint: position,
      tolerance: 1,
    );
    // Get the identified raster cell.
    if (identifyResult.geoElements.isNotEmpty) {
      // Create a StringBuffer to display information to the user.
      final stringBuffer = StringBuffer();
      final cell = identifyResult.geoElements.first;
      // Loop through the attributes (key/value pairs).
      cell.attributes.forEach((key, value) {
        stringBuffer.writeln('$key: $value');
      });
      // Get the x and y values of the cell.
      if (cell.geometry != null) {
        final x = cell.geometry!.extent.xMin;
        final y = cell.geometry!.extent.yMin;
        // Add the x & y coordinates where the user tapped the raster cell to the string buffer.
        stringBuffer.write(
          'X: ${x.toStringAsFixed(4)} Y: ${y.toStringAsFixed(4)}',
        );

        // Display a callout for the raster cell attributes.
        _mapViewController.callout.showCalloutForGeoElement(
          cell,
          contentBuilder: (context, geoElement) => IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.white,
              child: Text(stringBuffer.toString(), softWrap: false),
            ),
          ),
        );
      }
    }
  }

  Future<void> loadRasterLayer() async {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    // Create a Raster from the local tif file.
    final raster = Raster.withFileUri(Uri.file(listPaths.first));
    // Create a Raster Layer.
    _rasterLayer = RasterLayer.withRaster(raster);
    // Load the Raster Layer.
    await _rasterLayer.load();
  }
}
