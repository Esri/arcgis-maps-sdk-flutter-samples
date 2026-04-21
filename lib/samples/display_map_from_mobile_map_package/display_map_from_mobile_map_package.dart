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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisplayMapFromMobileMapPackage extends StatefulWidget {
  const DisplayMapFromMobileMapPackage({super.key});

  @override
  State<DisplayMapFromMobileMapPackage> createState() =>
      _DisplayMapFromMobileMapPackageState();
}

class _DisplayMapFromMobileMapPackageState
    extends State<DisplayMapFromMobileMapPackage>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    // Load the local mobile map package.
    final mmpkFile = File(listPaths.first);
    final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
    await mmpk.load();

    if (mmpk.maps.isNotEmpty) {
      // Get the first map in the mobile map package and set to the map view.
      _mapViewController.arcGISMap = mmpk.maps.first;
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
