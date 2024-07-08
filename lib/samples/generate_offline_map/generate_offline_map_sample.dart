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

class GenerateOfflineMapSample extends StatefulWidget {
  const GenerateOfflineMapSample({super.key});

  @override
  State<GenerateOfflineMapSample> createState() =>
      _GenerateOfflineMapSampleState();
}

class _GenerateOfflineMapSampleState extends State<GenerateOfflineMapSample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
                    onTap: onTap,
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

  void onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;
    // Perform some long-running setup task.
    await Future.delayed(const Duration(seconds: 10));
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    print('Tapped at $offset');
  }

  void performTask() async {
    setState(() => _ready = false);
    // Perform some task.
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
