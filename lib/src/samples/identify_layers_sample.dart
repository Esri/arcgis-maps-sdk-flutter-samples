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

class IdentifyLayersSample extends StatefulWidget {
  const IdentifyLayersSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  IdentifyLayersSampleState createState() => IdentifyLayersSampleState();
}

class IdentifyLayersSampleState extends State<IdentifyLayersSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -10977012.785807,
        y: 4514257.550369,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 68015210,
    );

    final serviceFeatureTable = ServiceFeatureTable.fromUri(Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0'));
    final featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);

    map.operationalLayers.add(featureLayer);

    _mapViewController.arcGISMap = map;

    _mapViewController.magnifierEnabled = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onTap: onTap,
        onLongPressEnd: onTap,
      ),
    );
  }

  void onTap(Offset localPosition) async {
    final identifyLayerResults = await _mapViewController.identifyLayers(
      screenPoint: localPosition,
      tolerance: 12.0,
    );

    if (identifyLayerResults.isNotEmpty && mounted) {
      int count = identifyLayerResults.length;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text('Found $count'));
        },
      );
    }
  }
}
