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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_state_support.dart';

class AddTiledLayerAsBasemap extends StatefulWidget {
  const AddTiledLayerAsBasemap({super.key});

  @override
  AddTiledLayerAsBasemapState createState() => AddTiledLayerAsBasemapState();
}

class AddTiledLayerAsBasemapState extends State<AddTiledLayerAsBasemap>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
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
    );
  }

  void onMapViewReady() async {
    await downloadSampleData(['e4a398afe9a945f3b0f4dca1e4faccb5']);
    final appDir = await getApplicationDocumentsDirectory();

    // Create a tile cache, specifying the path to the local tile package.
    const tilePackageName = 'SanFrancisco.tpkx';
    final pathToFile = '${appDir.absolute.path}/$tilePackageName';
    final tileCache = TileCache.withFileUri(Uri.parse(pathToFile));

    // Create a tiled layer with the tile cache.
    final tiledLayer = ArcGISTiledLayer.withTileCache(tileCache);
    // Create a basemap with the tiled layer.
    final basemap = Basemap.withBaseLayer(tiledLayer);
    // Create a map with the basemap.
    final map = ArcGISMap.withBasemap(basemap);
    // Set the map to the map view.
    _mapViewController.arcGISMap = map;
    // Set the ready state variable to true to enable the UI.
    setState(() => _ready = true);
  }
}
