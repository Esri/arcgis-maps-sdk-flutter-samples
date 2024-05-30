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
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      resizeToAvoidBottomInset: false,
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

    _featureTable = ServiceFeatureTable.withUri(Uri.parse(
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
      if (mounted) {
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
