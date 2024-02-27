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
