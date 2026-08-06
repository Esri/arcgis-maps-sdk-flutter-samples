// Copyright 2026 Esri
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

import 'dart:async';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class DisplayAlternateSymbolsAtDifferentScales extends StatefulWidget {
  const DisplayAlternateSymbolsAtDifferentScales({super.key});

  @override
  State<DisplayAlternateSymbolsAtDifferentScales> createState() =>
      _DisplayAlternateSymbolsAtDifferentScalesState();
}

class _DisplayAlternateSymbolsAtDifferentScalesState
    extends State<DisplayAlternateSymbolsAtDifferentScales>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // The current map scale.
  var _currentScale = 0.0;

  // A subscription for viewpoint changes.
  StreamSubscription<void>? _viewpointChangedSubscription;

  @override
  void dispose() {
    _viewpointChangedSubscription?.cancel().ignore();
    super.dispose();
  }

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
                // Display the current map scale.
                MapBanner(
                  text:
                      'Scale: 1:${_currentScale.isFinite ? _currentScale.round() : 0}',
                ),
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Center(
                  // A button to reset the viewpoint to the initial viewpoint of the map.
                  child: ElevatedButton(
                    onPressed: () {
                      final initialViewpoint =
                          _mapViewController.arcGISMap?.initialViewpoint;

                      if (initialViewpoint != null) {
                        _mapViewController.setViewpoint(initialViewpoint);
                      }
                    },
                    child: const Text('Reset Viewpoint'),
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

  void onMapViewReady() {
    // Create a map with a basemap style and initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -13631200,
        y: 4546830,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 7500,
    );

    // Create the service feature table.
    final featureTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0',
      ),
    );

    // Creates a feature layer from the service feature table.
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);

    // Apply the unique value renderer to the feature layer.
    featureLayer.renderer = makeUniqueValueRenderer();

    // Add the feature layer to the map's operational layers.
    map.operationalLayers.add(featureLayer);

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Listen to changes in the viewpoint and update the state with the new map scale.
    _viewpointChangedSubscription = _mapViewController.onViewpointChanged
        .listen(
          (_) => setState(() {
            _currentScale = _mapViewController.scale;
          }),
        );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Creates a unique value renderer with alternate symbols by scale.
  UniqueValueRenderer makeUniqueValueRenderer() {
    // Create a purple diamond marker symbol and convert it to a multilayer symbol.
    final purpleDiamond = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.diamond,
      color: Colors.purple,
      size: 15,
    ).toMultilayerSymbol();

    // Create a red triangle marker symbol and convert it to a multilayer symbol.
    final redTriangle = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.triangle,
      color: Colors.red,
      size: 30,
    ).toMultilayerSymbol();

    // Apply reference properties to the symbol to define min and max scale values at which the symbol will be visible.
    redTriangle.referenceProperties = SymbolReferenceProperties(
      minScale: 5000,
      maxScale: 0,
    );
    // Create a blue square marker symbol and convert it to a multilayer symbol.
    final blueSquare = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.square,
      color: Colors.blue,
      size: 30,
    ).toMultilayerSymbol();

    // Apply reference properties to the symbol to define min and max scale values at which the symbol will be visible.
    blueSquare.referenceProperties = SymbolReferenceProperties(
      minScale: 10000,
      maxScale: 5000,
    );

    // Create a yellow diamond marker symbol and convert it to a multilayer symbol.
    final yellowDiamond = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.diamond,
      color: Colors.yellow,
      size: 30,
    ).toMultilayerSymbol();

    // Apply reference properties to the symbol to define min and max scale values at which the symbol will be visible.
    yellowDiamond.referenceProperties = SymbolReferenceProperties(
      minScale: 20000,
      maxScale: 10000,
    );

    // Define the symbols used to render "Damaged Property" features.
    final uniqueValue = UniqueValue(
      description: 'unique values based on request type',
      label: 'unique value',
      symbol: redTriangle,
      values: ['Damaged Property'],
      alternateSymbols: [blueSquare, yellowDiamond],
    );

    // Configure the renderer to display unique and alternate symbols for request types.
    return UniqueValueRenderer(
      fieldNames: ['req_type'],
      uniqueValues: [uniqueValue],
      defaultSymbol: purpleDiamond,
    );
  }
}
