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
import 'package:arcgis_maps_sdk_flutter_samples/common/token_challenger_handler.dart';
import 'package:flutter/material.dart';

class DisplayContentOfUtilityNetworkContainer extends StatefulWidget {
  const DisplayContentOfUtilityNetworkContainer({super.key});

  @override
  State<DisplayContentOfUtilityNetworkContainer> createState() =>
      _DisplayContentOfUtilityNetworkContainerState();
}

class _DisplayContentOfUtilityNetworkContainerState
    extends State<DisplayContentOfUtilityNetworkContainer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();

    // Set up authentication for the sample server.
    // Note: Never hardcode login information in a production application.
    // This is done solely for the sake of the sample.
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = TokenChallengeHandler(
      'editor01',
      'S7#i2LWmYH75',
    );
  }

  @override
  void dispose() {
    // Remove the TokenChallengeHandler and erase any credentials that were generated.
    ArcGISEnvironment
            .authenticationManager
            .arcGISAuthenticationChallengeHandler =
        null;
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
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
    // Create a map using the portal item of a web map containing a utility network.
    final portal = Portal(
      Uri.parse('https://sampleserver7.arcgisonline.com/portal/sharing/rest'),
    );
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: '0e38e82729f942a19e937b31bfac1b8d',
    );
    final map = ArcGISMap.withItem(portalItem);

    // Set an initial viewpoint on the map.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 41.8,
      longitude: -88.16,
      scale: 4000,
    );

    // Add the map to the map view.
    _mapViewController.arcGISMap = map;

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
    await Future<void>.delayed(const Duration(seconds: 5));

    setState(() => _ready = true);
  }
}
