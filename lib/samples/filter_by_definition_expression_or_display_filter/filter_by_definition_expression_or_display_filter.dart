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

class FilterByDefinitionExpressionOrDisplayFilter extends StatefulWidget {
  const FilterByDefinitionExpressionOrDisplayFilter({super.key});

  @override
  State<FilterByDefinitionExpressionOrDisplayFilter> createState() =>
      _FilterByDefinitionExpressionOrDisplayFilterState();
}

class _FilterByDefinitionExpressionOrDisplayFilterState
    extends State<FilterByDefinitionExpressionOrDisplayFilter>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // Create a feature layer.
  final _featureLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/SF_311_Incidents/FeatureServer/0',
      ),
    ),
  );
  // Create a display filter definition.
  ManualDisplayFilterDefinition? _displayFilterDefinition;
  // Create a definition expression.
  var _definitionExpression = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              // Add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            // Add a text widget to display the feature count.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Add a button to apply a definition expression.
                ElevatedButton(
                  onPressed: applyDefinitionExpression,
                  child: const Text(
                    'Apply \nExpression',
                    textAlign: TextAlign.center,
                  ),
                ),
                // Add a button to apply a display filter.
                ElevatedButton(
                  onPressed: applyDisplayFilter,
                  child: const Text(
                    'Apply \nFilter',
                    textAlign: TextAlign.center,
                  ),
                ),
                // Add a button to reset the definition expression and display filter.
                ElevatedButton(
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

  void onMapViewReady() {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    // Add the feature layer to the map.
    map.operationalLayers.add(_featureLayer);
    // Set the initial viewpoint.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 37.7759,
      longitude: -122.45044,
      scale: 100000,
    );

    // Set the map to the map view.
    _mapViewController.arcGISMap = map;
  }

  void applyDefinitionExpression() async {
    // Remove the display filter.
    _displayFilterDefinition = null;
    // Apply a definition expression to the feature layer.
    _definitionExpression = "req_Type = 'Tree Maintenance or Damage'";
    // Count the number of features.
    await calculateFeatureCount();
  }

  void applyDisplayFilter() async {
    // Remove the definition expression.
    _definitionExpression = '';
    // Apply a display filter to the feature layer.
    final displayFilter = DisplayFilter.withWhereClause(
      name: 'Damaged Trees',
      whereClause: "req_type LIKE '%Tree Maintenance%'",
    );
    // Create a manual display filter definition.
    final manualDisplayFilterDefinition =
        ManualDisplayFilterDefinition.withFilters(
      activeFilter: displayFilter,
      availableFilters: [displayFilter],
    );
    _displayFilterDefinition = manualDisplayFilterDefinition;
    // Count the number of features.
    await calculateFeatureCount();
  }

  void reset() async {
    // Remove the definition expression and display filter.
    _displayFilterDefinition = null;
    _definitionExpression = '';
    // Count the number of features.
    await calculateFeatureCount();
  }

  Future<void> calculateFeatureCount() async {
    _featureLayer.displayFilterDefinition = _displayFilterDefinition;
    _featureLayer.definitionExpression = _definitionExpression;
    // Get the current extent of the map view.
    final extent = _mapViewController
        .getCurrentViewpoint(viewpointType: ViewpointType.boundingGeometry)
        ?.targetGeometry
        .extent;

    // Create query parameters.
    final queryParameters = QueryParameters();
    queryParameters.geometry = extent;

    // Query the feature count.
    final featureCount = await _featureLayer.featureTable!
        .queryFeatureCount(queryParameters: queryParameters);

    // Show the feature count in an alert dialog.
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Current Feature Count',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            content: Text(
              '$featureCount features',
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    }
  }
}
