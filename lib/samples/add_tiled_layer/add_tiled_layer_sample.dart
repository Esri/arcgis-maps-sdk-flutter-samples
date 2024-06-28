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
import 'package:flutter/material.dart';

class AddTiledLayerSample extends StatefulWidget {
  const AddTiledLayerSample({super.key});

  @override
  State<AddTiledLayerSample> createState() => _AddTiledLayerSampleState();
}

class _AddTiledLayerSampleState extends State<AddTiledLayerSample> {
  // create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() {
    // create a tiled layer with a URL to a tiled map service.
    final tiledLayer = ArcGISTiledLayer.withUri(
      Uri.parse(
          'http://services.arcgisonline.com/arcgis/rest/services/World_Topo_Map/MapServer'),
    );
    // create a basemap with the tiled layer.
    final basemap = Basemap.withBaseLayer(tiledLayer);
    // create a map with the basemap.
    final map = ArcGISMap.withBasemap(basemap);
    // set the map to the map view.
    _mapViewController.arcGISMap = map;
  }
}
