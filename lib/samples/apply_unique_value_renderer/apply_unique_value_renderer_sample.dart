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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class ApplyUniqueValueRendererSample extends StatefulWidget {
  const ApplyUniqueValueRendererSample({super.key});

  @override
  State<ApplyUniqueValueRendererSample> createState() =>
      _ApplyUniqueValueRendererSampleState();
}

class _ApplyUniqueValueRendererSampleState
    extends State<ApplyUniqueValueRendererSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(x: -12356253.6, y: 3842795.4),
      scale: 52681563.2,
    );

    final uri = Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3');
    final serviceFeatureTable = ServiceFeatureTable.withUri(uri);
    final featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);
    featureLayer.renderer = _configureUniqueValueRenderer();

    map.operationalLayers.add(featureLayer);
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }

  Renderer? _configureUniqueValueRenderer() {
    final stateOutlineSymbol = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid, color: Colors.white, width: 0.7);

    final pacificFillSymbol = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.blue,
        outline: stateOutlineSymbol);
    final mountainFillSymbol = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.green,
        outline: stateOutlineSymbol);
    final westSouthCentralFillSymbol = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: Colors.brown,
        outline: stateOutlineSymbol);

    final pacificValue = UniqueValue(
        description: 'Pacific Region',
        label: 'Pacific',
        symbol: pacificFillSymbol,
        values: ['Pacific']);
    final mountainValue = UniqueValue(
        description: 'Rocky Mountain Region',
        label: 'Mountain',
        symbol: mountainFillSymbol,
        values: ['Mountain']);
    final westSouthCentralValue = UniqueValue(
        description: 'West South Central Region',
        label: 'West South Central',
        symbol: westSouthCentralFillSymbol,
        values: ['West South Central']);

    final defaultFillSymbol = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.cross, color: Colors.grey, outline: null);

    return UniqueValueRenderer(
      fieldNames: ['SUB_REGION'],
      uniqueValues: [
        pacificValue,
        mountainValue,
        westSouthCentralValue,
      ],
      defaultLabel: 'Other',
      defaultSymbol: defaultFillSymbol,
    );
  }
}
