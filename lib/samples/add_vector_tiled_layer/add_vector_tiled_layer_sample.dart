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

class AddVectorTiledLayerSample extends StatefulWidget {
  const AddVectorTiledLayerSample({super.key});

  @override
  State<AddVectorTiledLayerSample> createState() =>
      _AddVectorTiledLayerSampleState();
}

class _AddVectorTiledLayerSampleState extends State<AddVectorTiledLayerSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(
        'https://www.arcgis.com/home/item.html?id=7675d44bb1e4428aa2c30a9b68f97822');
    var vectorTiledLayer = ArcGISVectorTiledLayer.withUri(uri);
    final basemap = Basemap.withBaseLayer(vectorTiledLayer);
    final map = ArcGISMap.withBasemap(basemap);
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }
}
