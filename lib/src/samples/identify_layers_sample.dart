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

    if (identifyLayerResults.isNotEmpty && context.mounted) {
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
