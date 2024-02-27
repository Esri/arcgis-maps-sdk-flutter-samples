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
import 'dart:ui' as ui;

class SimpleMarkerSymbolSample extends StatefulWidget {
  const SimpleMarkerSymbolSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SimpleMarkerSymbolSampleState createState() =>
      SimpleMarkerSymbolSampleState();
}

class SimpleMarkerSymbolSampleState extends State<SimpleMarkerSymbolSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    _mapViewController.wrapAroundMode = WrapAroundMode.disabled;

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    final point = ArcGISPoint(
      x: -226773,
      y: 6550477,
      spatialReference: SpatialReference.webMercator,
    );

    map.initialViewpoint = Viewpoint.fromCenter(point, scale: 7500);

    _mapViewController.arcGISMap = map;

    final simpleMarkerSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.diamond,
      color: const ui.Color.fromARGB(255, 255, 255, 0),
      size: 12.0,
    );
    final graphic = Graphic(geometry: point, symbol: simpleMarkerSymbol);

    final graphicsOverlay = GraphicsOverlay();
    graphicsOverlay.graphics.add(graphic);

    _mapViewController.graphicsOverlays.add(graphicsOverlay);
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
