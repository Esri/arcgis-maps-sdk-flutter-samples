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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class DisplayAnnotation extends StatefulWidget {
  const DisplayAnnotation({super.key});

  @override
  State<DisplayAnnotation> createState() => _DisplayAnnotationState();
}

class _DisplayAnnotationState extends State<DisplayAnnotation>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // Add a map view to the widget tree and set a controller.
            child: ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
            ),
          ),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with a Basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray);
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 55.882436,
      longitude: -2.725610,
      scale: 72223.819286,
    );

    // Add a FeatureLayer from the East Lothian Rivers service.
    const riverService =
        'https://services1.arcgis.com/6677msI40mnLuuLr/arcgis/rest/services/East_Lothian_Rivers/FeatureServer/0';
    final featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(Uri.parse(riverService)),
    );
    map.operationalLayers.add(featureLayer);

    // Add an AnnotationLayer from the river annotation service.
    const riverAnnotationService =
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/RiversAnnotation/FeatureServer/0';
    final annotationLayer =
        AnnotationLayer.withUri(Uri.parse(riverAnnotationService));
    map.operationalLayers.add(annotationLayer);

    // Set the map to the map view.
    _mapViewController.arcGISMap = map;
  }
}
