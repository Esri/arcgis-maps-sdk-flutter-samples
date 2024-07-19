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

class QueryTableStatisticsSample extends StatefulWidget {
  const QueryTableStatisticsSample({super.key});

  @override
  State<QueryTableStatisticsSample> createState() =>
      _QueryTableStatisticsSampleState();
}

class _QueryTableStatisticsSampleState extends State<QueryTableStatisticsSample>
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
  // A flag for querying statistics.
  var _onlyCitiesInCurrentExtent = true;
  // A flag for querying statistics.
  var _onlyCitiesGreaterThan5M = true;
  // A list of statistic definitions.
  final _statisticDefinitions = List<StatisticDefinition>.empty(growable: true);
  // A flag to display the query settings.
  var _toggleQuerySettings = true;

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

            Visibility(
              visible: _toggleQuerySettings,
              child: querySettings(context),
            ),
          ],
        ),
      ),
      bottomSheet: null, //querySettings(context),
    );
  }

  // Display the query options to query statistics.
  Widget querySettings(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 50,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _onlyCitiesInCurrentExtent,
                  onChanged: (value) {
                    setState(() => _onlyCitiesInCurrentExtent = value!);
                  },
                ),
                const Text('Only cities in current extent'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _onlyCitiesGreaterThan5M,
                  onChanged: (value) {
                    setState(() => _onlyCitiesGreaterThan5M = value!);
                  },
                ),
                const Text('Only cities greater than 5M'),
              ],
            ),
            ElevatedButton(
              onPressed: queryStatistics,
              child: const Text(
                'Get statistics',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Called when the map view is ready.
  void onMapViewReady() {
    for (final type in StatisticType.values) {
      _statisticDefinitions.add(
        StatisticDefinition(
          onFieldName: 'POP',
          statisticType: type,
        ),
      );
    }
    final map = ArcGISMap.withBasemapStyle(
      BasemapStyle.arcGISTopographic,
    );
    final featureLayer = FeatureLayer.withFeatureTable(
      _serviceFeatureTable,
    );
    map.operationalLayers.add(
      featureLayer,
    );
    _mapViewController.arcGISMap = map;
    setState(() => _ready = true);
  }

  // Query statistics from the service feature table.
  void queryStatistics() async {
    setState(() => _toggleQuerySettings = false);
    // Create a statistics query parameters object.
    final statisticsQueryParameters = StatisticsQueryParameters(
      statisticDefinitions: _statisticDefinitions,
    );

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
            title: const Text(
              'Statistical Query Results',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            content: Text(
              statistics.join('\n').toString(),
            ),
          );
        },
      ).then(
        (_) {
          setState(() => _toggleQuerySettings = true);
        },
      );
    }
  }
}
