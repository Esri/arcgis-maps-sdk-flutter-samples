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
import 'package:path_provider/path_provider.dart';

import '../sample_data.dart';

class AddTiledLayerAsBasemapSample extends StatefulWidget {
  const AddTiledLayerAsBasemapSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  AddTiledLayerAsBasemapSampleState createState() =>
      AddTiledLayerAsBasemapSampleState();
}

class AddTiledLayerAsBasemapSampleState
    extends State<AddTiledLayerAsBasemapSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() async {
    await downloadSampleData(['e4a398afe9a945f3b0f4dca1e4faccb5']);
    const tilePackageName = 'SanFrancisco.tpkx';
    final appDir = await getApplicationDocumentsDirectory();
    final pathToFile = '${appDir.absolute.path}/$tilePackageName';

    final tileCache = TileCache.withFileUri(Uri.parse(pathToFile));
    final tiledLayer = ArcGISTiledLayer.withTileCache(tileCache);
    final basemap = Basemap.withBaseLayer(tiledLayer);
    final map = ArcGISMap.withBasemap(basemap);
    _mapViewController.arcGISMap = map;
  }
}
