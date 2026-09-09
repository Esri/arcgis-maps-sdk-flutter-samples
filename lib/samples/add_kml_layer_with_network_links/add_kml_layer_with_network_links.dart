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

class AddKmlLayerWithNetworkLinks extends StatefulWidget {
  const AddKmlLayerWithNetworkLinks({super.key});

  @override
  State<AddKmlLayerWithNetworkLinks> createState() =>
      _AddKmlLayerWithNetworkLinksState();
}

class _AddKmlLayerWithNetworkLinksState
    extends State<AddKmlLayerWithNetworkLinks>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // A subscription to listen for network link messages.
  StreamSubscription<({KmlNetworkLink networkLink, String message})>?
  _messageSubscription;

  // A list to store network link messages.
  final _networkLinkMessages = <String>[];

  // A flag to indicate whether the bottom sheet is visible.
  var _bottomSheetVisible = false;

  @override
  void dispose() {
    // Stop listening for messages when the sample is removed.
    _messageSubscription?.cancel().ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a scene view to the widget tree and set its controller.
      body: ArcGISSceneView(
        controllerProvider: () => _sceneViewController,
        onSceneViewReady: onSceneViewReady,
      ),
      // A bottom sheet to display network link messages.
      bottomSheet: _bottomSheetVisible ? _buildBottomSheet(context) : null,
      // A button to bring up the bottom sheet.
      floatingActionButton: _bottomSheetVisible
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _bottomSheetVisible = true),
              child: const Icon(Icons.message_outlined),
            ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return BottomSheetSettings(
      title: 'Network Link Messages',
      onCloseIconPressed: () => setState(() => _bottomSheetVisible = false),
      settingsWidgets: (context) {
        if (_networkLinkMessages.isEmpty) {
          // A message indicating that no network link messages have been received.
          return [const Text('No network link messages received.')];
        }

        // Show the network link messages.
        return [for (final message in _networkLinkMessages) Text(message)];
      },
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with an imagery basemap style and initial viewpoint.
    final scene = ArcGISScene.withBasemapStyle(.arcGISImagery);
    scene.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 50.472421,
      longitude: 8.150526,
      scale: 10000000,
    );

    // Create the dataset from the radar KMZ file that contains network links.
    final dataset = KmlDataset(
      Uri.parse(
        'https://www.arcgis.com/sharing/rest/content/items/600748d4464442288f6db8a4ba27dc95/data',
      ),
    );

    // Create the KML layer and add it to the scene.
    final layer = KmlLayer(dataset);
    scene.operationalLayers.add(layer);

    // Add the scene to the controller.
    _sceneViewController.arcGISScene = scene;

    // Listen for network link control messages.
    _messageSubscription = dataset.onNetworkLinkMessageReceived.listen((event) {
      setState(() {
        _networkLinkMessages.add(event.message);
        _bottomSheetVisible = true;
      });
    });
  }
}
