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

class QueryTableStatisticsSample extends StatefulWidget {
  const QueryTableStatisticsSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  QueryTableStatisticsSampleState createState() =>
      QueryTableStatisticsSampleState();
}

class QueryTableStatisticsSampleState
    extends State<QueryTableStatisticsSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _serviceFeatureTable = ServiceFeatureTable.fromUri(Uri.parse(
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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
          ),
          Positioned(
            width: 350,
            height: 160,
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

    if (context.mounted) {
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
