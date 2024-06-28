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

class ApplySimpleRendererToFeatureLayerSample extends StatefulWidget {
  const ApplySimpleRendererToFeatureLayerSample({super.key});

  @override
  State<ApplySimpleRendererToFeatureLayerSample> createState() =>
      _ApplySimpleRendererToFeatureLayerSampleState();
}

class _ApplySimpleRendererToFeatureLayerSampleState
    extends State<ApplySimpleRendererToFeatureLayerSample> {
  // The feature layer that will host the symbolized features
  late final FeatureLayer _featureLayer;
  // Create the map view controller
  final _mapViewController = ArcGISMapView.createController();
  // State variable indicating if all state has been initialized
  var _ready = false;
  // State variable indicating if the default renderer is currently being used.
  var _usingDefaultRenderer = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: _usingDefaultRenderer
                        ? overrideRenderer
                        : resetRenderer,
                    child: _usingDefaultRenderer
                        ? const Text('Blue Renderer')
                        : const Text('Orange Renderer'),
                  ),
                )
              ],
            ),
            // Display a progress indicator and prevent interaction before state is ready
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
      ),
    );
  }

  void onMapViewReady() {
    // Initialize the feature layer with a feature table web service
    final uri = Uri.parse(
        'https://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/Landscape_Trees/FeatureServer/0');
    final serviceFeatureTable = ServiceFeatureTable.withUri(uri);
    _featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);

    // Initialize the ArcGISMap
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic)
      ..operationalLayers.add(_featureLayer)
      ..initialViewpoint = Viewpoint.fromCenter(
        ArcGISPoint(
          x: -9177343,
          y: 4247283,
          spatialReference: SpatialReference.webMercator,
        ),
        scale: 4750,
      );

    // Add the map to the MapViewController
    _mapViewController.arcGISMap = map;

    // Set the _ready state to true. This will hide the overlay controls.
    setState(() => _ready = true);
  }

  void overrideRenderer() {
    // Set a new renderer for the feature layer
    final markerSymbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle, color: Colors.blue, size: 5);
    _featureLayer.renderer = SimpleRenderer(symbol: markerSymbol);
    setState(() => _usingDefaultRenderer = false);
  }

  void resetRenderer() {
    // Reset the feature layer renderer
    _featureLayer.resetRenderer();
    setState(() => _usingDefaultRenderer = true);
  }
}
