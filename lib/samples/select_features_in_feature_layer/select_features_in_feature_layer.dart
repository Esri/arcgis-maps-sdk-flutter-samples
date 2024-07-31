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

import '../../utils/sample_state_support.dart';

class SelectFeaturesInFeatureLayer extends StatefulWidget {
  const SelectFeaturesInFeatureLayer({super.key});

  @override
  State<SelectFeaturesInFeatureLayer> createState() =>
      _SelectFeaturesInFeatureLayerState();
}

class _SelectFeaturesInFeatureLayerState
    extends State<SelectFeaturesInFeatureLayer> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a feature layer from a feature table.
  final _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(Uri.parse(
          'https://services1.arcgis.com/4yjifSiIG17X0gW4/arcgis/rest/services/GDP_per_capita_1960_2016/FeatureServer/0')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        // Add a callback to the onTap event.
        onTap: onTap,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with a light gray canvas basemap.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray);
    // Set the initial viewpoint to a specific location and scale.
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: 4.376000,
        y: 50.838570,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 5e7,
    );
    // Add the feature layer to the map.
    map.operationalLayers.add(_featureLayer);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;
  }

  void onTap(Offset localPosition) async {
    // Clear the selection on the feature layer.
    _featureLayer.clearSelection();

    // Identify the features at the tapped location.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _featureLayer,
      screenPoint: localPosition,
      tolerance: 22,
      maximumResults: 1000,
    );
    // Get the features from the identify layer result.
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();

    // If no features are identified, unselect all features.
    if (features.isEmpty) {
      final featureQueryResult = await _featureLayer.getSelectedFeatures();
      final selectedFeatures = featureQueryResult.features();
      for (final feature in selectedFeatures) {
        _featureLayer.unselectFeature(feature: feature);
      }
    } else {
      // Select the identified features.
      _featureLayer.selectFeatures(features: features);
    }
  }
}
