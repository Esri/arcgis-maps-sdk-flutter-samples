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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
  // Graphic to get the raster cell information.
  final Graphic _textGraphic = Graphic();
  // Graphics overlay to display the text graphic.
  final _textGraphicsOverlay = GraphicsOverlay();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
              onTap: onTap,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the oceans basemap style and an initial viewpoint.
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
    // Add the text graphic to the text graphics overlay.
    _textGraphicsOverlay.graphics.add(_textGraphic);
    // Add the text graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_textGraphicsOverlay);
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
        // Add the x & y coordinates where the user clicked raster cell to the string buffer.
        stringBuffer.writeln();
        stringBuffer.writeln('X: ${x.toStringAsFixed(4)}');
        stringBuffer.write('Y: ${y.toStringAsFixed(4)}');

        final textSymbol = TextSymbol(
          color: Colors.white,
          size: 12,
          text: stringBuffer.toString(),
          horizontalAlignment: HorizontalAlignment.left,
        );
        textSymbol.backgroundColor = Colors.black.withValues(
          alpha: 0.8,
        );
        _textGraphic.geometry = cell.geometry;
        _textGraphicsOverlay.renderer = SimpleRenderer(
          symbol: textSymbol,
        );
      }
    } else {
      _textGraphicsOverlay.renderer = null;
    }
  }

  Future<void> loadRasterLayer() async {
    // Download the raster file.
    await downloadSampleData(['b5f977c78ec74b3a8857ca86d1d9b318']);
    // Get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // Create a Raster from the local tif file.
    final raster = Raster.withFileUri(
      Uri.file(
        '${appDir.absolute.path}/SA_EVI_8Day_03May20/SA_EVI_8Day_03May20.tif',
      ),
    );
    // Create a Raster Layer.
    _rasterLayer = RasterLayer.withRaster(raster);
    // Load the Raster Layer.
    await _rasterLayer.load();
  }
}
