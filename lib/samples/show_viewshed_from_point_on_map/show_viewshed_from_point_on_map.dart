// Copyright 2025 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class ShowViewshedFromPointOnMap extends StatefulWidget {
  const ShowViewshedFromPointOnMap({super.key});

  @override
  State<ShowViewshedFromPointOnMap> createState() =>
      _ShowViewshedFromPointOnMapState();
}

class _ShowViewshedFromPointOnMapState extends State<ShowViewshedFromPointOnMap>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A GraphicsOverlay to show where the user tapped on the map.
  final _inputOverlay = GraphicsOverlay();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: onTap,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: 45.3790902612337,
        y: 6.84905317262762,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 70000,
    );

    // Create a renderer for the input overlay to show where the user tapped.
    _inputOverlay.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(color: Colors.red, size: 15),
    );
    _mapViewController.graphicsOverlays.add(_inputOverlay);

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    // Determine the map point from the local position of the tap.
    final mapPoint = _mapViewController.screenToLocation(screen: localPosition);
    if (mapPoint == null) return;

    // Clear the previous graphic from the input overlay.
    _inputOverlay.graphics.clear();

    // Create a graphic at the tapped location and add it to the input overlay.
    final inputGraphic = Graphic(geometry: mapPoint);
    _inputOverlay.graphics.add(inputGraphic);

    setState(() => _ready = false);

    //fixme calculate the viewshed from the tapped point
    //'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Elevation/ESRI_Elevation_World/GPServer/Viewshed'

    setState(() => _ready = true);
  }
}
