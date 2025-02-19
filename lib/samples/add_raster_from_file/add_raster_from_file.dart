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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AddRasterFromFile extends StatefulWidget {
  const AddRasterFromFile({super.key});

  @override
  State<AddRasterFromFile> createState() => _AddRasterFromFileState();
}

class _AddRasterFromFileState extends State<AddRasterFromFile>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add a map view to the widget tree and set a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the ArcGIS ImageryStandard basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    // Load the raster layer.
    final rasterLayer = await loadRasterLayerFromFile();

    // Add the raster layer to the map's operational layers.
    map.operationalLayers.add(rasterLayer);

    // Set the viewpoint to the center of the raster layer's full extent.
    final fullExtent = rasterLayer.fullExtent;
    if (fullExtent != null) {
      final viewpoint = Viewpoint.fromCenter(
        fullExtent.center,
        scale: 80000,
      );

      // Set the map on the map view controller.
      _mapViewController.arcGISMap = map;

      // Set the viewpoint to the raster layer.
      _mapViewController.setViewpoint(viewpoint);

      // Set the ready state variable to true to enable the sample UI.
      setState(() => _ready = true);
    }
  }

  Future<RasterLayer> loadRasterLayerFromFile() async {
    // Download the sample data.
    await downloadSampleData(['7c4c679ab06a4df19dc497f577f111bd']);
    // Get the temp directory.
    final directory = await getApplicationDocumentsDirectory();
    // Create a file to the Shasta tif file.
    final shastaTifFile =
        File('${directory.absolute.path}/raster-file/raster-file/Shasta.tif');
    // Create a raster from the file URI.
    final raster = Raster.withFileUri(shastaTifFile.uri);
    // Load the raster object.
    await raster.load();

    // Create a raster layer using the raster object.
    final rasterLayer = RasterLayer.withRaster(raster);
    return rasterLayer;
  }
}
