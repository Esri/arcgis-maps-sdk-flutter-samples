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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_data.dart';
import '../../utils/sample_state_support.dart';

class DisplayDimensions extends StatefulWidget {
  const DisplayDimensions({super.key});

  @override
  State<DisplayDimensions> createState() => _DisplayDimensionsState();
}

class _DisplayDimensionsState extends State<DisplayDimensions>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // The DimensionLayer showing the dimensions on the map.
  late final DimensionLayer _dimensionLayer;

  // The state variable to show the name of the dimension layer.
  var _dimensionLayerName = '';

  // Switch states for the dimension layer and definition expression.
  var _showDimensionLayer = true;
  var _isDefinitionExpressionApplied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
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
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dimension layer name: '),
                          Text(_dimensionLayerName),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dimension layer'),
                          Switch(
                            value: _showDimensionLayer,
                            onChanged: showDimensionLayer,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Definition Expression: Dimensions >= 450m',
                          ),
                          Switch(
                            value: _isDefinitionExpressionApplied,
                            onChanged: applyDefinitionExpression,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Download the mobile map package.
    await downloadSampleData(['f5ff6f5556a945bca87ca513b8729a1e']);

    // Load the local mobile map package.
    final appDir = await getApplicationDocumentsDirectory();
    final mmpkFile =
        File('${appDir.absolute.path}/Edinburgh_Pylon_Dimensions.mmpk');
    final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
    await mmpk.load();

    if (mmpk.maps.isNotEmpty) {
      // Get the first map in the mobile map package and set to the map view.
      final map = mmpk.maps.first;

      // Get the dimension layer from the map's operational layers.
      _dimensionLayer = map.operationalLayers.whereType<DimensionLayer>().first;

      // Set an initial viewpoint for the map.
      map.initialViewpoint = Viewpoint.fromCenter(
        ArcGISPoint(
          x: -368015.99460377498,
          y: 7540290.3376379032,
          spatialReference: SpatialReference.webMercator,
        ),
        scale: 30000,
      );

      // Set the map to the map view.
      _mapViewController.arcGISMap = map;
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() {
      _dimensionLayerName = _dimensionLayer.name;
      _ready = true;
    });
  }

  // Function that shows or hides the dimension layer on the map.
  void showDimensionLayer(bool show) {
    _dimensionLayer.isVisible = show;
    setState(() => _showDimensionLayer = show);
  }

  // Function that applies or removes the definition expression to the dimension layer.
  void applyDefinitionExpression(bool apply) {
    final definitionExpression = apply ? 'DIMLENGTH >= 450' : '';
    _dimensionLayer.definitionExpression = definitionExpression;
    setState(() => _isDefinitionExpressionApplied = apply);
  }
}
