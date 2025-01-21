// Copyright 2025 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class SetUpLocationDrivenGeotriggers extends StatefulWidget {
  const SetUpLocationDrivenGeotriggers({super.key});

  @override
  State<SetUpLocationDrivenGeotriggers> createState() =>
      _SetUpLocationDrivenGeotriggersState();
}

class _SetUpLocationDrivenGeotriggersState
    extends State<SetUpLocationDrivenGeotriggers> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    final map = ArcGISMap.withUri(
      Uri.parse(
        'https://www.arcgis.com/home/item.html?id=6ab0e91dc39e478cae4f408e1a36a308',
      ),
    );
    _mapViewController.arcGISMap = map;
    // Perform some long-running setup task.
    await Future.delayed(const Duration(seconds: 10));
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    // Do something with a tap.
    // ignore: avoid_print
    print('Tapped at $offset');
  }

  Future<void> performTask() async {
    setState(() => _ready = false);
    // Perform some task.
    // ignore: avoid_print
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
