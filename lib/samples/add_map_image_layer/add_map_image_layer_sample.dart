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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class AddMapImageLayerSample extends StatefulWidget {
  const AddMapImageLayerSample({super.key});

  @override
  State<AddMapImageLayerSample> createState() => _AddMapImageLayerSampleState();
}

class _AddMapImageLayerSampleState extends State<AddMapImageLayerSample>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Add a map view to the widget tree and set a controller.
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: _onMapViewReady,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapViewReady() async {
    // Create a map with a map image layer.
    final map = ArcGISMap();
    // Create a map image layer with a uri.
    final mapImageLayer = ArcGISMapImageLayer.withUri(
      Uri.parse(
          'https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer'),
    );
    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;
    // Add the map image layer to the map.
    map.operationalLayers.add(mapImageLayer);
    // Load the map image layer.
    await mapImageLayer.load();
    // Set the state to ready.
    setState(() => _ready = true);
  }
}
