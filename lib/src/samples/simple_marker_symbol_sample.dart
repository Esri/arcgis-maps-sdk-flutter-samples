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

import 'dart:ui' as ui;

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

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
