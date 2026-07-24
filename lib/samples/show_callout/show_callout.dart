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

class ShowCallout extends StatefulWidget {
  const ShowCallout({super.key});

  @override
  State<ShowCallout> createState() => _ShowCalloutState();
}

class _ShowCalloutState extends State<ShowCallout> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
        onTap: onTap,
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(.arcGISTopographic);

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;
  }

  void onTap(Offset offset) {
    // Convert screen point to map point.
    final mapPoint = _mapViewController.screenToLocation(screen: offset);
    if (mapPoint == null) return;

    // Project the tapped point to WGS84 for coordinate formatting.
    final tapLocation =
        GeometryEngine.project(
              mapPoint,
              outputSpatialReference: SpatialReference.wgs84,
            )
            as ArcGISPoint;

    // Format the coordinates using the CoordinateFormatter.toLatitudeLongitude.
    final coordinateText = CoordinateFormatter.toLatitudeLongitude(
      point: tapLocation,
      format: LatitudeLongitudeFormat.decimalDegrees,
      decimalPlaces: 2,
    );

    // Show the coordinates in a callout.
    _mapViewController.callout.showAt(
      mapPoint,
      title: 'Location',
      detail: coordinateText,
    );
  }
}
