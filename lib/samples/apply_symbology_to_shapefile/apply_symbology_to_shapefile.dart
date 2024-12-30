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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ApplySymbologyToShapefile extends StatefulWidget {
  const ApplySymbologyToShapefile({super.key});

  @override
  State<ApplySymbologyToShapefile> createState() =>
      _ApplySymbologyToShapefileState();
}

class _ApplySymbologyToShapefileState extends State<ApplySymbologyToShapefile>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // Hold reference to the feature layer so that its renderer can be changed when button is pushed.
  late FeatureLayer _shapefileFeatureLayer;
  // Hold reference to default renderer to enable switching back.
  Renderer? _defaultRenderer;
  // Hold reference to alternate renderer to enable switching.
  SimpleRenderer? _alternateRenderer;
  // Create variable for holding state relating to the renderer.
  bool _alternate = false;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Alternate renderer'),
                    Switch(
                      value: _alternate,
                      onChanged: (value) {
                        setState(() => _alternate = value);
                        updateRenderer();
                      },
                    ),
                  ],
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
    // Create a map with the topographic basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -11662054,
        y: 4818336,
        spatialReference: SpatialReference(wkid: 3857),
      ),
      scale: 200000,
    );

    // Download the sample data.
    await downloadSampleData(['d98b3e5293834c5f852f13c569930caa']);
    // Get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // Get the Shapefile from the download resource.
    final shapefile =
        File('${appDir.absolute.path}/Aurora_CO_shp/Subdivisions.shp');
    // Create a feature table from the Shapefile URI.
    final shapefileFeatureTable =
        ShapefileFeatureTable.withFileUri(shapefile.uri);
    // Create a feature layer for the Shapefile feature table.
    setState(
      () => _shapefileFeatureLayer =
          FeatureLayer.withFeatureTable(shapefileFeatureTable),
    );
    // Clear the operational layers and add the feature layer to the map.
    map.operationalLayers.clear();
    map.operationalLayers.add(_shapefileFeatureLayer);
    // Create the symbology for the alternate renderer.
    final lineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid,
      color: Colors.red,
      width: 1.0,
    );
    final fillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: Colors.yellow,
      outline: lineSymbol,
    );
    // Create the alternate renderer.
    setState(() => _alternateRenderer = SimpleRenderer(symbol: fillSymbol));
    // Wait for the layer to load so that it will be assigned a default renderer.
    await _shapefileFeatureLayer.load();
    // Hold a reference to the default renderer (to enable switching between the renderers).
    setState(() => _defaultRenderer = _shapefileFeatureLayer.renderer);

    _mapViewController.arcGISMap = map;
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Set the renderer.
  void updateRenderer() async {
    if (_shapefileFeatureLayer.renderer == _defaultRenderer) {
      setState(() => _shapefileFeatureLayer.renderer = _alternateRenderer);
    } else {
      setState(() => _shapefileFeatureLayer.renderer = _defaultRenderer);
    }
  }
}
