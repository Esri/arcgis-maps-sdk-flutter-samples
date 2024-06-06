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

class QueryTableStatisticsSample extends StatefulWidget {
  const QueryTableStatisticsSample({super.key});

  @override
  State<QueryTableStatisticsSample> createState() =>
      _QueryTableStatisticsSampleState();
}

class _QueryTableStatisticsSampleState
    extends State<QueryTableStatisticsSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _serviceFeatureTable = ServiceFeatureTable.withUri(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer/0'));
  bool _onlyCitiesInCurrentExtent = true;
  bool _onlyCitiesGreaterThan5M = true;
  final _statisticDefinitions = List<StatisticDefinition>.empty(growable: true);

  @override
  void initState() {
    super.initState();

    for (final type in StatisticType.values) {
      _statisticDefinitions.add(
        StatisticDefinition(onFieldName: 'POP', statisticType: type),
      );
    }

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    final featureLayer = FeatureLayer.withFeatureTable(_serviceFeatureTable);
    map.operationalLayers.add(featureLayer);

    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
          ),
          Positioned(
            width: 350,
            height: 180,
            bottom: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SwitchListTile(
                    title: const Text('Only cities in current extent'),
                    value: _onlyCitiesInCurrentExtent,
                    onChanged: (value) {
                      setState(() => _onlyCitiesInCurrentExtent = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Only cities greater than 5M'),
                    value: _onlyCitiesGreaterThan5M,
                    onChanged: (value) {
                      setState(() => _onlyCitiesGreaterThan5M = value);
                    },
                  ),
                  TextButton(
                    onPressed: queryStatistics,
                    child: const Text(
                      'Get statistics',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void queryStatistics() async {
    final statisticsQueryParameters =
        StatisticsQueryParameters(statisticDefinitions: _statisticDefinitions);

    if (_onlyCitiesInCurrentExtent) {
      statisticsQueryParameters.geometry = _mapViewController.visibleArea;

      statisticsQueryParameters.spatialRelationship =
          SpatialRelationship.intersects;
    }

    if (_onlyCitiesGreaterThan5M) {
      statisticsQueryParameters.whereClause = 'POP_RANK = 1';
    }

    final statisticsQueryResult = await _serviceFeatureTable.queryStatistics(
        statisticsQueryParameters: statisticsQueryParameters);

    final statistics = StringBuffer();

    final records = statisticsQueryResult.statisticRecords();
    for (final record in records) {
      record.statistics.forEach((key, value) {
        statistics.write('\n$key: $value');
      });
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Statistical Query Results'),
            content: Text(
              statistics.toString(),
            ),
          );
        },
      );
    }
  }
}
