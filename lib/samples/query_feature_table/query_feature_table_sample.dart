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

class QueryFeatureTableSample extends StatefulWidget {
  const QueryFeatureTableSample({super.key});

  @override
  State<QueryFeatureTableSample> createState() =>
      _QueryFeatureTableSampleState();
}

class _QueryFeatureTableSampleState extends State<QueryFeatureTableSample> {
  // create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // create a text editing controller.
  final _textEditingController = TextEditingController();
  // create a focus node for the search text field.
  final _searchFocusNode = FocusNode();
  // create an initial viewpoint.
  final _initialViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(
      x: -11000000,
      y: 5000000,
      spatialReference: SpatialReference.webMercator,
    ),
    scale: 100000000,
  );
  // create a feature table and a feature layer.
  final ServiceFeatureTable _featureTable = ServiceFeatureTable.withUri(Uri.parse(
      'https://services.arcgis.com/jIL9msH9OI208GCb/arcgis/rest/services/USA_Daytime_Population_2016/FeatureServer/0'));
  late FeatureLayer _featureLayer;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // create a column with a text field and a map view.
      body: SafeArea(
        child: Column(
          children: [
            // create a text field for searching states.
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
            // add a map view to the widget tree and set a controller.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // create a map with the topographic basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // create a feature layer and amend the opacity and max scale properties.
    _featureLayer = FeatureLayer.withFeatureTable(_featureTable)
      ..opacity = 0.8
      ..maxScale = 10000;

    // create a renderer with a fill symbol and apply to the feature layer.
    final lineSymbol = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid, color: Colors.black, width: 1);
    final fillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: Colors.yellow,
      outline: lineSymbol,
    );
    final renderer = SimpleRenderer(symbol: fillSymbol);
    _featureLayer.renderer = renderer;

    // add the feature layer to the map and define an initial viewpoint.
    map.operationalLayers.add(_featureLayer);
    map.initialViewpoint = _initialViewpoint;
    // set the map to the map view.
    _mapViewController.arcGISMap = map;
  }

  void onSearchSubmitted(String value) async {
    // clear the selection.
    _featureLayer.clearSelection();

    // create query parameters and set the where clause.
    final queryParameters = QueryParameters();
    final stateName = value.trim().toUpperCase();
    queryParameters.whereClause = "upper(STATE_NAME) LIKE '$stateName'";

    // query the feature table with the query parameters.
    final queryResult =
        await _featureTable.queryFeatures(parameters: queryParameters);

    // get the first feature from the query result.
    final iterator = queryResult.features().iterator;
    if (iterator.moveNext()) {
      final feature = iterator.current;
      if (feature.geometry != null) {
        // set the viewpoint to the feature's extent.
        _mapViewController.setViewpointGeometry(
          feature.geometry!.extent,
          paddingInDiPs: 20.0,
        );
      }
      _featureLayer.selectFeature(feature: feature);
    } else {
      // show an alert dialog if no matching state is found.
      if (mounted) {
        // set the viewpoint to the initial viewpoint.
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
    // clear the text field and dismiss the keyboard.
    setState(() => _textEditingController.clear());
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
