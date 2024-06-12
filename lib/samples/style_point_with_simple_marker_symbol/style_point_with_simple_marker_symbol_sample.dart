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

class StylePointWithSimpleMarkerSymbolSample extends StatefulWidget {
  const StylePointWithSimpleMarkerSymbolSample({super.key});

  @override
  State<StylePointWithSimpleMarkerSymbolSample> createState() =>
      _StylePointWithSimpleMarkerSymbolSampleState();
}

class _StylePointWithSimpleMarkerSymbolSampleState
    extends State<StylePointWithSimpleMarkerSymbolSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    // create a map with a basemap style
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    // create a point using x and y coordinates
    final point = ArcGISPoint(
      x: -226773,
      y: 6550477,
      spatialReference: SpatialReference.webMercator,
    );

    // set the initial viewpoint of the map to the point and provide a scale
    map.initialViewpoint = Viewpoint.fromCenter(point, scale: 7500);

    // set the map to the mapview controller
    _mapViewController.arcGISMap = map;

    // create a graphics overlay and add it to the mapview controller
    final graphicsOverlay = GraphicsOverlay();
    _mapViewController.graphicsOverlays.add(graphicsOverlay);

    // create a simple marker symbol with a style, color and size
    final simpleMarkerSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: Color(Colors.red.value),
      size: 10.0,
    );

    // create a graphic using the point and simple marker symbol
    final graphic = Graphic(geometry: point, symbol: simpleMarkerSymbol);

    // add the graphic to the graphics overlay
    graphicsOverlay.graphics.add(graphic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // create an ArcGISMapView and assign the mapview controller
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }
}
