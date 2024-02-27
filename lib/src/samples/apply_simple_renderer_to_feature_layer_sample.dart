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
