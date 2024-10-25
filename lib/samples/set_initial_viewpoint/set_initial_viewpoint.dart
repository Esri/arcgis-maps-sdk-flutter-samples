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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class SetInitialViewpoint extends StatefulWidget {
  const SetInitialViewpoint({super.key});

  @override
  State<SetInitialViewpoint> createState() => _SetInitialViewpointState();
}

class _SetInitialViewpointState extends State<SetInitialViewpoint>
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

  void onMapViewReady() {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    // Create an initial envelope.
    final initialEnvelope = Envelope.fromXY(
      xMin: -118.805,
      yMin: 34.027,
      xMax: -118.795,
      yMax: 34.037,
      spatialReference: SpatialReference.wgs84,
    );
    // Create and set the initial viewpoint to the map.
    map.initialViewpoint = Viewpoint.fromTargetExtent(initialEnvelope.extent);

    _mapViewController.arcGISMap = map;
  }
}
