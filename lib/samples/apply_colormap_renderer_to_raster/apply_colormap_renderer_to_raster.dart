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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ApplyColormapRendererToRaster extends StatefulWidget {
  const ApplyColormapRendererToRaster({super.key});

  @override
  State<ApplyColormapRendererToRaster> createState() =>
      _ApplyColormapRendererToRasterState();
}

class _ApplyColormapRendererToRasterState
    extends State<ApplyColormapRendererToRaster> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);
    _mapViewController.arcGISMap = map;

    // Download the ShastaBW tif file.
    await downloadSampleData(['cc68728b5904403ba637e1f1cd2995ae']);
    // Get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();

    // Create a Raster from the local tif file.
    final raster = Raster.withFileUri(
      Uri.file('${appDir.absolute.path}/ShastaBW/ShastaBW.tif'),
    );

    // Create a Raster Layer.
    final rasterLayer = RasterLayer.withRaster(raster);

    // Create a color map where values 0-149 are red (Color.RED) and 150-250 are yellow (Color.Yellow).
    final colors = <Color>[];
    for (var i = 0; i <= 250; i++) {
      if (i < 150) {
        colors.add(const Color(0xFFFF0000));
      } else {
        colors.add(const Color(0xFFFFFF00));
      }
    }

    // Create a color map renderer.
    final colorMapRenderer =  ColormapRenderer.withColors(colors);

    // Set the ColorMapRenderer on the Raster Layer.
    rasterLayer.renderer = colorMapRenderer;

    // Load the Raster Layer.
    await rasterLayer.load();
    // Add the Raster Layer to the map.
    map.operationalLayers.add(rasterLayer);


    // Set the viewpoint to the center of the raster layer's full extent.
    final fullExtent = rasterLayer.fullExtent;
    if (fullExtent != null) {
      final center = fullExtent.center;
      const scale = 80000.0;
      await _mapViewController.setViewpointCenter(center, scale: scale);
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

}
