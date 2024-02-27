//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
//

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class ApplyUniqueValueRendererSample extends StatefulWidget {
  const ApplyUniqueValueRendererSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ApplyUniqueValueRendererSampleState createState() =>
      ApplyUniqueValueRendererSampleState();
}

class ApplyUniqueValueRendererSampleState
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
    final serviceFeatureTable = ServiceFeatureTable.fromUri(uri);
    final featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);
    featureLayer.renderer = _configureUniqueValueRenderer();

    map.operationalLayers.add(featureLayer);
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
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
