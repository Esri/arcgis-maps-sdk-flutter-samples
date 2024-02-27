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

class SelectFeaturesInFeatureLayerSample extends StatefulWidget {
  const SelectFeaturesInFeatureLayerSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SelectFeaturesInFeatureLayerSampleState createState() =>
      SelectFeaturesInFeatureLayerSampleState();
}

class SelectFeaturesInFeatureLayerSampleState
    extends State<SelectFeaturesInFeatureLayerSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.fromUri(Uri.parse(
          'https://services1.arcgis.com/4yjifSiIG17X0gW4/arcgis/rest/services/GDP_per_capita_1960_2016/FeatureServer/0')));

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray);

    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: 4.376000,
        y: 50.838570,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 5e7,
    );

    map.operationalLayers.add(_featureLayer);

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
        onTap: onTap,
      ),
    );
  }

  void onTap(Offset localPosition) async {
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _featureLayer,
      screenPoint: localPosition,
      tolerance: 22,
      maximumResults: 1000,
    );

    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();

    if (features.isEmpty) {
      final featureQueryResult = await _featureLayer.getSelectedFeatures();
      final selectedFeatures = featureQueryResult.features();
      for (final feature in selectedFeatures) {
        _featureLayer.unselectFeature(feature: feature);
      }
    } else {
      _featureLayer.selectFeatures(features: features);
    }
  }
}
