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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class AddWebTiledLayer extends StatefulWidget {
  const AddWebTiledLayer({super.key});

  @override
  State<AddWebTiledLayer> createState() => _AddWebTiledLayerState();
}

class _AddWebTiledLayerState extends State<AddWebTiledLayer>
    with SampleStateSupport {
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
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  // Called when the map view is ready.
  void onMapViewReady() {
    // Templated URL to the tile service.
    const templateUrl =
        'https://server.arcgisonline.com/arcgis/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{level}/{row}/{col}.jpg';
    // Attribution string for the Living Atlas service.
    const attribution =
        'Map tiles by ArcGIS Living Atlas of the World, under Esri Master License Agreement. Data by Esri, Garmin, GEBCO, NOAA NGDC, and other contributors.';

    // Create the WebTiledLayer from the URL.
    final webTiledLayer = WebTiledLayer(template: templateUrl)
      // Set the attribution.
      ..setAttribution(attribution);

    // Create a basemap from the WebTiledLayer.
    final basemap = Basemap.withBaseLayer(webTiledLayer);
    // Create a map to hold the BaseMap.
    final map = ArcGISMap.withBasemap(basemap);
    // Set the ArcGISMap to the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
