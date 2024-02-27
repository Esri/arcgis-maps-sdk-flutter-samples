//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
//

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
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
