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

class QueryFeatureTableSample extends StatefulWidget {
  const QueryFeatureTableSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  QueryFeatureTableSampleState createState() => QueryFeatureTableSampleState();
}

class QueryFeatureTableSampleState extends State<QueryFeatureTableSample> {
  final _mapViewController = ArcGISMapView.createController();
  late ServiceFeatureTable _featureTable;
  late FeatureLayer _featureLayer;
  final _textEditingController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _initialViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(
      x: -11000000,
      y: 5000000,
      spatialReference: SpatialReference.webMercator,
    ),
    scale: 100000000,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          TextField(
            focusNode: _searchFocusNode,
            controller: _textEditingController,
            decoration: InputDecoration(
              hintText: 'Enter a State...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: dismissSearch,
                icon: const Icon(Icons.clear),
              ),
            ),
            onSubmitted: onSearchSubmitted,
          ),
          Expanded(
            child: ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
            ),
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    _featureTable = ServiceFeatureTable.fromUri(Uri.parse(
        'https://services.arcgis.com/jIL9msH9OI208GCb/arcgis/rest/services/USA_Daytime_Population_2016/FeatureServer/0'));
    await _featureTable.load();
    _featureLayer = FeatureLayer.withFeatureTable(_featureTable);
    _featureLayer.opacity = 0.8;
    _featureLayer.maxScale = 10000;

    final lineSymbol = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid, color: Colors.black, width: 1);
    final fillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: Colors.yellow,
      outline: lineSymbol,
    );
    final renderer = SimpleRenderer(symbol: fillSymbol);
    _featureLayer.renderer = renderer;

    map.operationalLayers.add(_featureLayer);

    _mapViewController.arcGISMap = map;
    _mapViewController.setViewpoint(_initialViewpoint);
  }

  void onSearchSubmitted(String value) async {
    _featureLayer.clearSelection();

    final queryParameters = QueryParameters();
    final stateName = value.trim().toUpperCase();
    queryParameters.whereClause = "upper(STATE_NAME) LIKE '$stateName'";

    final queryResult =
        await _featureTable.queryFeatures(parameters: queryParameters);

    final iterator = queryResult.features().iterator;
    if (iterator.moveNext()) {
      final feature = iterator.current;
      if (feature.geometry != null) {
        _mapViewController.setViewpointGeometry(
          feature.geometry!.extent,
          paddingInDiPs: 20.0,
        );
      }
      _featureLayer.selectFeature(feature: feature);
    } else {
      if (context.mounted) {
        _mapViewController.setViewpoint(_initialViewpoint);
        showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              content: Text('No matching State found.'),
            );
          },
        );
      }
    }
  }

  void dismissSearch() {
    setState(() => _textEditingController.clear());
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
