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

import 'package:arcgis_maps_sdk/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DisplayDimensions extends StatefulWidget {
  const DisplayDimensions({super.key});

  @override
  State<DisplayDimensions> createState() => _DisplayDimensionsState();
}

class _DisplayDimensionsState extends State<DisplayDimensions> {
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
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dimensions layer'),
                          Switch(
                            value: true,
                            onChanged: (value) {},
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                              'Definition Expression: Dimensions >= 450m'),
                          Switch(
                            value: true,
                            onChanged: (value) {},
                          ),
                        ],
                      ),
                    ],
                  ),
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
    await downloadSampleData(['f5ff6f5556a945bca87ca513b8729a1e']);
    final appDir = await getApplicationDocumentsDirectory();

    // Load the local mobile map package.
    final mmpkFile =
        File('${appDir.absolute.path}/Edinburgh_Pylon_Dimensions.mmpk');
    final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
    await mmpk.load();

    if (mmpk.maps.isNotEmpty) {
      // Get the first map in the mobile map package and set to the map view.
      _mapViewController.arcGISMap = mmpk.maps.first;
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void performTask() async {
    setState(() => _ready = false);
    // Perform some task.
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
