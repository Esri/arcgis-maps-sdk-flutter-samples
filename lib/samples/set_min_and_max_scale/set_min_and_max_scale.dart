// Copyright 2026 Esri
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

class SetMinAndMaxScale extends StatefulWidget {
  const SetMinAndMaxScale({super.key});

  @override
  State<SetMinAndMaxScale> createState() => _SetMinAndMaxScaleState();
}

class _SetMinAndMaxScaleState extends State<SetMinAndMaxScale>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a basemap style and initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -355453,
        y: 7548720,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 3000,
    );
    // Set min and max scales to the map.
    map.minScale = 8000;
    map.maxScale = 2000;
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;
  }
}
