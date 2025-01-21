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
  var _openLabel = '';
  var _closedLabel = '';
  var _currentScaleLabel = '';

  // Declare open label color.
  Color? _openLabelColor;

  // Declare the annotation sub layers.
  late final AnnotationSublayer _closedSublayer;
  late final AnnotationSublayer _openSublayer;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;

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
                  ),
                ),
                // A button to control Settings bottom sheet.
                Center(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _settingsVisible = true),
                    child: const Text('Settings'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        Row(
          children: [
            Text(
              _openLabel,
              style: TextStyle(color: _openLabelColor),
            ),
            const Spacer(),
            Switch(
              value: _openSublayer.isVisible,
              onChanged: (value) {
                // Set the visibility of the open sub layer.
                setState(() => _openSublayer.isVisible = value);
              },
            ),
          ],
        ),
        Row(
          children: [
            Text(
              _closedLabel,
            ),
            const Spacer(),
            Switch(
              value: _closedSublayer.isVisible,
              onChanged: (value) {
                // Set the visibility of the closed sub layer.
                setState(() => _closedSublayer.isVisible = value);
              },
            ),
          ],
        ),
        Text(
          _currentScaleLabel,
        ),
      ],
    );
  }

  Future<void> onMapViewReady() async {
    try {
      await downloadSampleData(['b87307dcfb26411eb2e92e1627cb615b']);
      final appDir = await getApplicationDocumentsDirectory();

      // Load the mobile map package.
      final mmpkFile = File('${appDir.absolute.path}/GasDeviceAnno.mmpk');
      // Mobile map package that contains annotation layers.
      final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
      await mmpk.load();

      // Get the first map in the mobile map package and set to the map view.
      _mapViewController.arcGISMap = mmpk.maps.first;

      // Get the annotation layer from the MapView operational layers.
      final annotationLayer = _mapViewController.arcGISMap!.operationalLayers
          .whereType<AnnotationLayer>()
          .first;

      // Load the annotation layer.
      await annotationLayer.load();

      setState(() {
        // Get the annotation sub layers.
        _closedSublayer =
            annotationLayer.subLayerContents[0] as AnnotationSublayer;

        _openSublayer =
            annotationLayer.subLayerContents[1] as AnnotationSublayer;

        // Set the closed label content.
        _closedLabel = _closedSublayer.name;

        // Set the open label content.
        _openLabel =
            '${_openSublayer.name} (1:${_openSublayer.maxScale.toInt()} - 1:${_openSublayer.minScale.toInt()})';
      });

      // Add event handler for changing the text color to indicate whether the "open" sublayer is visible at the current scale.
      _mapViewController.onViewpointChanged.listen((_) {
        // Check if the sublayer is visible at the current map scale.
        if (_openSublayer.isVisibleAtScale(_mapViewController.scale)) {
          setState(
              () => _openLabelColor = Theme.of(context).colorScheme.primary,);
        } else {
          setState(() => _openLabelColor = null);
        }
        // Set the current map scale text.
        setState(
          () => _currentScaleLabel =
              'Current map scale: 1:${_mapViewController.scale.toInt()}',
        );
      });

      // Set the ready state variable to true to enable the sample UI.
      setState(() => _ready = true);
    } on ArcGISException catch (e) {
      showMessageDialog('${e.message}.');
    } on Exception {
      showMessageDialog(
        'There was an error loading the data required for the sample.',
      );
    }
  }
}
