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
import 'package:path_provider/path_provider.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'dart:io';
import '../sample_data.dart';

class OpenMobileMapSample extends StatefulWidget {
  const OpenMobileMapSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  OpenMobileMapSampleState createState() => OpenMobileMapSampleState();
}

class OpenMobileMapSampleState extends State<OpenMobileMapSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() async {
    await downloadSampleData(['e1f3a7254cb845b09450f54937c16061']);
    final appDir = await getApplicationDocumentsDirectory();
    final mmpkFile = File('${appDir.absolute.path}/Yellowstone.mmpk');
    final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
    await mmpk.load();
    if (mmpk.maps.isNotEmpty) {
      _mapViewController.arcGISMap = mmpk.maps.first;
    }
  }
}
