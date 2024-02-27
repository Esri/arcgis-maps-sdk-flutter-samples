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

class ShowMagnifierSample extends StatelessWidget {
  const ShowMagnifierSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => ArcGISMapView.createController()
          ..arcGISMap =
              ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard)
          ..arcGISMap!.initialViewpoint = Viewpoint.fromCenter(
            ArcGISPoint(
              x: -110.8258,
              y: 32.154089,
              spatialReference: SpatialReference.wgs84,
            ),
            scale: 2e4,
          )
          ..magnifierEnabled = true,
      ),
    );
  }
}
