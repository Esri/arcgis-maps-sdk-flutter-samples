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

class IdentifyLayerFeatures extends StatefulWidget {
  const IdentifyLayerFeatures({super.key});

  @override
  State<IdentifyLayerFeatures> createState() =>
      _IdentifyLayerFeaturesState();
}

class _IdentifyLayerFeaturesState
    extends State<IdentifyLayerFeatures> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // The message to display in the result banner.
  var _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add a map view to the widget tree and set a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: onTap,
          ),
          // Add a banner to show the results of the identify operation.
          SafeArea(
            child: IgnorePointer(
              child: Visibility(
                visible: _message.isNotEmpty,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.black.withOpacity(0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
        ],
      ),
    );
  }

  void onMapViewReady() async {
    // Create a feature layer of damaged property data.
    final serviceFeatureTable = ServiceFeatureTable.withUri(Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0'));
    final featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);

    // Create a layer with world cities data.
    final mapImageLayer = ArcGISMapImageLayer.withUri(Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer'));
    await mapImageLayer.load();
    // Hide continent and world layers.
    mapImageLayer.subLayerContents[1].isVisible = false;
    mapImageLayer.subLayerContents[2].isVisible = false;

    // Create a map with a basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -10977012.785807,
        y: 4514257.550369,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 68015210,
    );

    // Add the layers to the map.
    map.operationalLayers.addAll([featureLayer, mapImageLayer]);

    // Add the map to the map view.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() {
      _message = 'Tap on the map to identify layer features.';
      _ready = true;
    });
  }

  void onTap(Offset localPosition) async {
    // Identify features at the tapped location.
    final identifyLayerResults = await _mapViewController.identifyLayers(
      screenPoint: localPosition,
      tolerance: 12.0,
      maximumResultsPerLayer: 10,
    );

    // Count the number of identified features.
    var identifyTotal = 0;
    final layerCounts = <String>[];
    for (final result in identifyLayerResults) {
      final layerTotal = result.totalCount;
      identifyTotal += layerTotal;
      layerCounts.add('${result.layerContent.name}: $layerTotal');
    }

    // Display the results in the banner.
    setState(() {
      _message = identifyTotal == 0
          ? 'No features identified.'
          : layerCounts.join('\n');
    });
  }
}

extension on IdentifyLayerResult {
  // The total count of features, recursively including all sublayers.
  int get totalCount {
    return sublayerResults.fold(geoElements.length,
        (previous, element) => previous + element.totalCount);
  }
}
