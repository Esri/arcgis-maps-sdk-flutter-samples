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

class FilterByDefinitionExpressionOrDisplayFilterSample extends StatefulWidget {
  const FilterByDefinitionExpressionOrDisplayFilterSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  FilterByDefinitionExpressionOrDisplayFilterSampleState createState() =>
      FilterByDefinitionExpressionOrDisplayFilterSampleState();
}

class FilterByDefinitionExpressionOrDisplayFilterSampleState
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
      appBar: AppBar(
        title: Text(widget.title),
      ),
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
