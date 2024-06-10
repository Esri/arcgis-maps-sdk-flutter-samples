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
  const AddTiledLayerSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  AddTiledLayerSampleState createState() => AddTiledLayerSampleState();
}

class AddTiledLayerSampleState extends State<AddTiledLayerSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(
        'http://services.arcgisonline.com/arcgis/rest/services/World_Topo_Map/MapServer');
    var tiledLayer = ArcGISTiledLayer.withUri(uri);
    final basemap = Basemap.withBaseLayer(tiledLayer);
    final map = ArcGISMap.withBasemap(basemap);
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }
}
