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
import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ControlAnnotationSublayerVisibility extends StatefulWidget {
  const ControlAnnotationSublayerVisibility({super.key});

  @override
  State<ControlAnnotationSublayerVisibility> createState() =>
      _ControlAnnotationSublayerVisibilityState();
}

class _ControlAnnotationSublayerVisibilityState
    extends State<ControlAnnotationSublayerVisibility> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Declare labels text.
  String? _openLabel;
  String? _closedLabel;
  String? _currentScaleLabel;

  // Declare labels styles.
  Color? _openLabelColor;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;

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
                // A button to control Settings bottom sheet.
                if (_currentScaleLabel != null) buildBottomMenu()
                /*Center(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _settingsVisible = true),
                    child: const Text('Geometry Settings'),
                  ),
                ),*/
                /*Text(
                  _openLabel ?? '',
                  style: TextStyle(color: _openLabelColor),
                ),*/
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
      //bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  Widget buildBottomMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // A text to show current map scale
        Text(_currentScaleLabel ?? ''),
        // A button to toggle the visibility of the editing toolbar.
        IconButton(
          onPressed: () => setState(() => _settingsVisible = !_settingsVisible),
          icon: const Icon(Icons.edit, color: Colors.deepPurple),
        ),
      ],
    );
  }

  // The build method for the Geometry Settings bottom sheet.
  /*Widget buildSettings(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        20.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Geometry Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
          if (_openLabel != null)
            Row(
              children: [
                Text(_openLabel!),
                const Spacer(),
                Switch(
                  value: _generalize,
                  onChanged: (value) {
                    setState(() => _generalize = value);
                    updateGraphics();
                  },
                ),
              ],
            ),
          const Divider(),
        ],
      ),
    );
  }*/

  void onMapViewReady() async {
    await downloadSampleData(['b87307dcfb26411eb2e92e1627cb615b']);
    final appDir = await getApplicationDocumentsDirectory();

    // Load the mobile map package.
    final mmpkFile = File('${appDir.absolute.path}/GasDeviceAnno.mmpk');
    // Mobile map package that contains annotation layers.
    final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
    await mmpk.load();

    if (mmpk.maps.isNotEmpty) {
      // Get the first map in the mobile map package and set to the map view.
      _mapViewController.arcGISMap = mmpk.maps.first;
    }

    if (_mapViewController.arcGISMap != null) {
      // Get the annotation layer from the MapView operational layers.
      final annotationLayer = _mapViewController.arcGISMap!.operationalLayers
          .whereType<AnnotationLayer>()
          .first;

      // Load the annotation layer.
      await annotationLayer.load();

      // Get the annotation sub layers.
      final openSublayer =
          annotationLayer.subLayerContents[1] as AnnotationSublayer;
      final closedSublayer =
          annotationLayer.subLayerContents[0] as AnnotationSublayer;

      // Set the label content.
      _openLabel =
          '${openSublayer.name} (1:${openSublayer.maxScale.toInt()} - 1:${openSublayer.minScale.toInt()})';

      // Add event handler for changing the text to indicate whether the "open" sublayer is visible at the current scale.
      _mapViewController.onViewpointChanged.listen((_) {
        // Check if the sublayer is visible at the current map scale.
        if (closedSublayer.isVisibleAtScale(_mapViewController.scale)) {
          _openLabelColor = Colors.purple;
        }

        // Set the current map scale text.
        _currentScaleLabel =
            'Current map scale: 1:${_mapViewController.scale.toInt()}';

        setState(() {});
      });

      _closedLabel = closedSublayer.name;
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
