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

class ApplySimpleRendererToFeatureLayerSample extends StatefulWidget {
  const ApplySimpleRendererToFeatureLayerSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ApplySimpleRendererToFeatureLayerSampleState createState() =>
      ApplySimpleRendererToFeatureLayerSampleState();
}

class ApplySimpleRendererToFeatureLayerSampleState
    extends State<ApplySimpleRendererToFeatureLayerSample> {
  final _mapViewController = ArcGISMapView.createController();
  late FeatureLayer _featureLayer;
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(
        'https://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/Landscape_Trees/FeatureServer/0');
    final serviceFeatureTable = ServiceFeatureTable.fromUri(uri);
    _featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);
    _map.operationalLayers.add(_featureLayer);
    _map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -9177250,
        y: 4247200,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 9500,
    );
    _mapViewController.arcGISMap = _map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
              ),
            ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: resetRenderer,
                  child: const Text('Reset'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: overrideRenderer,
                  child: const Text('Override'),
                ),
                const Spacer(),
              ],
            )
          ],
        ),
      ),
    );
  }

  void resetRenderer() {
    _featureLayer.resetRenderer();
  }

  void overrideRenderer() {
    final markerSymbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle, color: Colors.blue, size: 5);
    _featureLayer.renderer = SimpleRenderer(symbol: markerSymbol);
  }
}
