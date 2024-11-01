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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class ApplyStyleToWmsLayer extends StatefulWidget {
  const ApplyStyleToWmsLayer({super.key});

  @override
  State<ApplyStyleToWmsLayer> createState() => _ApplyStyleToWmsLayerState();
}

class _ApplyStyleToWmsLayerState extends State<ApplyStyleToWmsLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Hold a reference to the layer to enable re-styling.
  late WmsLayer _mnWmsLayer;

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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: performTask,
                      child: const Text('Perform Task'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with spatial reference appropriate for the service.
    final map = ArcGISMap(spatialReference: SpatialReference(wkid: 26915));
    map.minScale = 7000000.0;
    // Create a new WMS layer displaying the specified layers from the service.
    // The default styles are chosen by default.
    _mnWmsLayer = WmsLayer.withUriAndLayerNames(
      uri: Uri.parse(
        'https://imageserver.gisdata.mn.gov/cgi-bin/mncomp?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities',
      ),
      layerNames: ['mncomp'],
    );

    // Wait for the layer to load.
    await _mnWmsLayer.load();

    if (_mnWmsLayer.fullExtent != null) {
      // Center the map on the layer's contents.
      map.initialViewpoint =
          Viewpoint.fromTargetExtent(_mnWmsLayer.fullExtent!);
    }

    // Add the layer to the map.
    map.operationalLayers.add(_mnWmsLayer);

    // Add the map to the view.
    _mapViewController.arcGISMap = map;

    // Enable the buttons.
    FirstStyleButton.IsEnabled = true;
    SecondStyleButton.IsEnabled = true;
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;
    // Perform some long-running setup task.
    await Future.delayed(const Duration(seconds: 10));
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
