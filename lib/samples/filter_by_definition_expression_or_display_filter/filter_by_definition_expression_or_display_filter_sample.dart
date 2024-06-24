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

class FilterByDefinitionExpressionOrDisplayFilterSample extends StatefulWidget {
  const FilterByDefinitionExpressionOrDisplayFilterSample({super.key});

  @override
  State<FilterByDefinitionExpressionOrDisplayFilterSample> createState() =>
      _FilterByDefinitionExpressionOrDisplayFilterSampleState();
}

class _FilterByDefinitionExpressionOrDisplayFilterSampleState
    extends State<FilterByDefinitionExpressionOrDisplayFilterSample> {
  // create a map view controller
  final _mapViewController = ArcGISMapView.createController();
  final FeatureLayer _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(Uri.parse(
          'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0')));

  @override
  void initState() {
    super.initState();
    // create a map with a topographic basemap style
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    // add the feature layer to the map
    map.operationalLayers.add(_featureLayer);
    // set the initial viewpoint
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 37.7759,
      longitude: -122.45044,
      scale: 100000,
    );

    // set the map to the map view.
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
              ),
            ),
            // add a text widget to display the feature count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // add a button to apply a definition expression
                TextButton(
                  onPressed: applyDefinitionExpression,
                  child: const Text('Definition Expression'),
                ),
                // add a button to apply a display filter
                TextButton(
                  onPressed: applyDisplayFilter,
                  child: const Text('Display Filter'),
                ),
                // add a button to reset the definition expression and display filter
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
    // remove the display filter
    _featureLayer.displayFilterDefinition = null;
    // apply a definition expression to the feature layer
    _featureLayer.definitionExpression =
        "req_Type = 'Tree Maintenance or Damage'";
    // count the number of features
    calculateFeatureCount();
  }

  void applyDisplayFilter() {
    // remove the definition expression
    _featureLayer.definitionExpression = '';
    // apply a display filter to the feature layer
    final displayFilter = DisplayFilter.withWhereClause(
        name: 'Damaged Trees',
        whereClause: "req_type LIKE '%Tree Maintenance%'");
    // create a manual display filter definition
    final manualDisplayFilterDefinition =
        ManualDisplayFilterDefinition.withFilters(
            activeFilter: displayFilter, availableFilters: [displayFilter]);
    _featureLayer.displayFilterDefinition = manualDisplayFilterDefinition;
    // count the number of features
    calculateFeatureCount();
  }

  void reset() {
    // remove the definition expression and display filter
    _featureLayer.displayFilterDefinition = null;
    _featureLayer.definitionExpression = '';
    // count the number of features
    calculateFeatureCount();
  }

  void calculateFeatureCount() async {
    // count the number of features
    final queryParameters = QueryParameters();
    // get the current extent of the map view
    queryParameters.geometry = _mapViewController
        .getCurrentViewpoint(viewpointType: ViewpointType.boundingGeometry)
        ?.targetGeometry
        .extent;
    queryParameters.whereClause = '1=1';

    // query the feature count
    final featureCount = await _featureLayer.featureTable!
        .queryFeatureCount(queryParameters: queryParameters);

    // show the feature count in an alert dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text('$featureCount features found.'));
        },
      );
    }
  }
}
