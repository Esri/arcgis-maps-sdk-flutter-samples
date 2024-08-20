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

import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class QueryTableStatistics extends StatefulWidget {
  const QueryTableStatistics({super.key});

  @override
  State<QueryTableStatistics> createState() => _QueryTableStatisticsState();
}

class _QueryTableStatisticsState extends State<QueryTableStatistics>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a ServiceFeatureTable from a URL.
  final _serviceFeatureTable = ServiceFeatureTable.withUri(
    Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer/0',
    ),
  );
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for whether to limit the query to cities within the current extent.
  var _onlyCitiesInCurrentExtent = true;
  // A flag for whether to limit the query to cities with population greater than 5 million.
  var _onlyCitiesGreaterThan5M = true;
  // A list of statistic definitions to apply to the query.
  final _statisticDefinitions = <StatisticDefinition>[];
  // A flag to display the query settings.
  var _settingsVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: () => setState(() => _settingsVisible = true),
                      child: const Text('Settings'),
                    ),
                    // A button to calculate the statistics.
                    ElevatedButton(
                      onPressed: queryStatistics,
                      child: const Text('Get statistics'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? querySettings(context) : null,
    );
  }

  // The build method for the query options shown in the bottom sheet.
  Widget querySettings(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Query Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _onlyCitiesInCurrentExtent,
                onChanged: (value) =>
                    setState(() => _onlyCitiesInCurrentExtent = value!),
              ),
              const Text('Only cities in current extent'),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _onlyCitiesGreaterThan5M,
                onChanged: (value) =>
                    setState(() => _onlyCitiesGreaterThan5M = value!),
              ),
              const Text('Only cities greater than 5M'),
            ],
          ),
        ],
      ),
    );
  }

  // Called when the map view is ready.
  void onMapViewReady() {
    // Add the statistic definitions for the 'POP' (Population) field.
    for (final type in StatisticType.values) {
      _statisticDefinitions.add(
        StatisticDefinition(
          onFieldName: 'POP',
          statisticType: type,
        ),
      );
    }
    // Create a map with a topographic basemap.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // Create a feature layer from the service feature table.
    final featureLayer = FeatureLayer.withFeatureTable(_serviceFeatureTable);

    // Add the feature layer to the map.
    map.operationalLayers.add(featureLayer);
    // Set the map to the map view.
    _mapViewController.arcGISMap = map;
    setState(() => _ready = true);
  }

  // Query statistics from the service feature table.
  void queryStatistics() async {
    // Create a statistics query parameters object.
    final statisticsQueryParameters =
        StatisticsQueryParameters(statisticDefinitions: _statisticDefinitions);

    // Set the geometry and spatial relationship if the flag is true.
    if (_onlyCitiesInCurrentExtent) {
      statisticsQueryParameters.geometry = _mapViewController.visibleArea;
      statisticsQueryParameters.spatialRelationship =
          SpatialRelationship.intersects;
    }
    // Set the where clause if the flag is true.
    if (_onlyCitiesGreaterThan5M) {
      statisticsQueryParameters.whereClause = 'POP_RANK = 1';
    }
    // Query the statistics.
    final statisticsQueryResult = await _serviceFeatureTable.queryStatistics(
      statisticsQueryParameters: statisticsQueryParameters,
    );

    // Prepare the statistics results for display.
    final statistics = [];
    final records = statisticsQueryResult.statisticRecords();
    for (final record in records) {
      record.statistics.forEach((key, value) {
        final displayName =
            key.toLowerCase() == 'count_pop' ? 'CITY_COUNT' : key;
        final displayValue = key.toLowerCase() == 'count_pop'
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2);
        statistics.add('[$displayName]  $displayValue');
      });
    }
    // Display the statistics in a dialog.
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Statistical Query Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            content: Text(statistics.join('\n')),
          );
        },
      );
    }
  }
}
