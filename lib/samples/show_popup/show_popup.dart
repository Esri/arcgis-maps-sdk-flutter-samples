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
import 'package:arcgis_maps_sdk_flutter_samples/common/loading_indicator.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/sample_state_support.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class ShowPopup extends StatefulWidget {
  const ShowPopup({super.key});

  @override
  State<ShowPopup> createState() => _ShowPopupState();
}

class _ShowPopupState extends State<ShowPopup> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with San Francisco incidents web map.
    final map = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'fb788308ea2e4d8682b9c05ef641f273',
      ),
    );

    // Set initial viewpoint to San Francisco.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 37.7759,
      longitude: -122.45044,
      scale: 100000,
    );

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset offset) async {
    // Identify the tapped feature.
    final identifyResult = await _mapViewController.identifyLayers(
      screenPoint: offset,
      tolerance: 22,
    );

    // Ensure the identify layer result has a popup.
    if (identifyResult.isNotEmpty && identifyResult.first.popups.isNotEmpty) {
      final popup = identifyResult.first.popups.first;
      _showPopup(popup);
    }
  }

  // Display the results in a Popup view in a bottom modal sheet.
  void _showPopup(Popup popup) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: PopupView(
          popup: popup,
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
