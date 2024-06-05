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

class FilterByDefinitionExpressionOrDisplayFilterSample extends StatefulWidget {
  const FilterByDefinitionExpressionOrDisplayFilterSample({super.key});

  @override
  State<FilterByDefinitionExpressionOrDisplayFilterSample> createState() =>
      _FilterByDefinitionExpressionOrDisplayFilterSampleState();
}

class _FilterByDefinitionExpressionOrDisplayFilterSampleState
    extends State<FilterByDefinitionExpressionOrDisplayFilterSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.fromUri(Uri.parse(
          'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0')));

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.operationalLayers.add(_featureLayer);
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 37.7759,
      longitude: -122.45044,
      scale: 100000,
    );

    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: applyDefinitionExpression,
                  child: const Text('Definition Expression'),
                ),
                TextButton(
                  onPressed: applyDisplayFilter,
                  child: const Text('Display Filter'),
                ),
                TextButton(
                  onPressed: reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void applyDefinitionExpression() {
    _featureLayer.displayFilterDefinition = null;
    _featureLayer.definitionExpression =
        "req_Type = 'Tree Maintenance or Damage'";
  }

  void applyDisplayFilter() {
    _featureLayer.definitionExpression = '';
    final displayFilter = DisplayFilter.withWhereClause(
        name: 'Damaged Trees',
        whereClause: "req_type LIKE '%Tree Maintenance%'");
    final manualDisplayFilterDefinition =
        ManualDisplayFilterDefinition.withFilters(
            activeFilter: displayFilter, availableFilters: [displayFilter]);
    _featureLayer.displayFilterDefinition = manualDisplayFilterDefinition;
  }

  void reset() {
    _featureLayer.displayFilterDefinition = null;
    _featureLayer.definitionExpression = '';
  }
}
