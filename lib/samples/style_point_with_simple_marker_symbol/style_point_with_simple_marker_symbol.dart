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

import '../../utils/sample_state_support.dart';

class StylePointWithSimpleMarkerSymbol extends StatefulWidget {
  const StylePointWithSimpleMarkerSymbol({super.key});

  @override
  State<StylePointWithSimpleMarkerSymbol> createState() =>
      _StylePointWithSimpleMarkerSymbolState();
}

class _StylePointWithSimpleMarkerSymbolState
    extends State<StylePointWithSimpleMarkerSymbol> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: _onMapViewReady,
      ),
    );
  }

  void _onMapViewReady() {
    // Create a map with a basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    // Create a point using x and y coordinates.
    final point = ArcGISPoint(
      x: -226773,
      y: 6550477,
      spatialReference: SpatialReference.webMercator,
    );

    // Set the initial viewpoint of the map to the point and provide a scale.
    map.initialViewpoint = Viewpoint.fromCenter(point, scale: 7500);

    // Set the map to the mapview controller.
    _mapViewController.arcGISMap = map;

    // Create a graphics overlay and add it to the mapview controller.
    final graphicsOverlay = GraphicsOverlay();
    _mapViewController.graphicsOverlays.add(graphicsOverlay);

    // Create a simple marker symbol with a style, color and size.
    final simpleMarkerSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle,
      color: Colors.red,
      size: 10.0,
    );

    // Create a graphic using the point and simple marker symbol.
    final graphic = Graphic(geometry: point, symbol: simpleMarkerSymbol);

    // Add the graphic to the graphics overlay.
    graphicsOverlay.graphics.add(graphic);
  }
}
