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
      ServiceFeatureTable.withUri(Uri.parse(
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
