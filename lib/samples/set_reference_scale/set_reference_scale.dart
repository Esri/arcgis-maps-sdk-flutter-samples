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

import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class SetReferenceScale extends StatefulWidget {
  const SetReferenceScale({super.key});

  @override
  State<SetReferenceScale> createState() => _SetReferenceScaleState();
}

class _SetReferenceScaleState extends State<SetReferenceScale>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a list of dropdown menu items to load all the reference scales.
  final _referenceScaleList = <DropdownMenuItem<double>>[];
  // Create a list of selected feature layers.
  final _selectedFeatureLayers = <String>[];
  // Create a list of all feature layers.
  late List<String> _allFeatureLayers;
  // Create a variable to store the map.
  var _map = ArcGISMap();
  // Create a variable to store the scale.
  var _scale = 250000.0;
  // Create a flag for when the map view is ready and controls can be used.
  var _ready = false;
  // Create a flag for when the bottom sheet is visible.
  var _bottomSheetVisible = false;
  // Create a regular expression to format the scale.
  final _digitGroupRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  @override
  void initState() {
    super.initState();
    // Add scales to the list.
    for (final value in [500000.0, 250000.0, 100000.0, 50000.0]) {
      _referenceScaleList.add(
        DropdownMenuItem(
          value: value,
          child: Text(formatAsScale(value)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        // Add a column to the widget tree.
        child: Column(
          children: [
            Expanded(
              // Add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            // Add a settings button to the widget tree.
            ElevatedButton(
              // Show the settings dialog when the button is pressed.
              onPressed: _ready
                  ? () => setState(() => _bottomSheetVisible = true)
                  : null,
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
      bottomSheet: _bottomSheetVisible ? buildSettings(context) : null,
    );
  }

  void onMapViewReady() async {
    // Create a portal item.
    final portal = Portal.arcGISOnline();
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: '3953413f3bd34e53a42bf70f2937a408',
    );
    // Load the portal item.
    await portalItem.load();

    // Create a map from the portal item and load it.
    _map = ArcGISMap.withItem(portalItem);
    await _map.load();

    // Get the operational layer names from the map.
    _allFeatureLayers =
        _map.operationalLayers.map((layer) => layer.name).toList();

    // Get the feature layers that have scale symbols enabled and add them to the selected feature layers list.
    for (final layer in _map.operationalLayers) {
      layer as FeatureLayer;
      layer.scaleSymbols == true
          ? _selectedFeatureLayers.add(layer.name)
          : null;
    }

    // Set the map view controller's map to the ArcGIS map.
    _mapViewController.arcGISMap = _map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Widget buildSettings(BuildContext context) {
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
          // Add a row with the settings title and close button.
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _bottomSheetVisible = false),
              ),
            ],
          ),
          // Add a container with a scrollable column for the settings.
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Reference Scale',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      // Add a dropdown button for setting a new reference scale.
                      DropdownButton(
                        underline: Container(),
                        style: Theme.of(context).textTheme.titleSmall,
                        isDense: true,
                        alignment: Alignment.center,
                        // Set the selected scale
                        value: _scale,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.deepPurple,
                        ),
                        // Set the callback to update the selected scale.
                        onChanged: (newScale) {
                          setState(() {
                            _scale = newScale!;
                            _map.referenceScale = _scale;
                          });
                        },
                        items: _referenceScaleList,
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Text(
                        'Apply Reference Scale to Layers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  // Add a list of checkboxes for selecting feature layers that will honor the reference scale.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Create a checkbox for each feature layer.
                      for (final layer in _allFeatureLayers)
                        CheckboxListTile(
                          dense: true,
                          value: _selectedFeatureLayers.contains(layer),
                          onChanged: (value) {
                            setState(() {
                              // Update the selected feature layers list.
                              if (value ?? false) {
                                _selectedFeatureLayers.add(layer);
                              } else {
                                _selectedFeatureLayers.remove(layer);
                              }
                            });

                            // Get the matching layer from the map.
                            var matchingLayer = _map.operationalLayers
                                .where((element) => element.name == layer)
                                .first as FeatureLayer;

                            // Set the layer property based on the checkbox value.
                            _selectedFeatureLayers.contains(matchingLayer.name)
                                ? matchingLayer.scaleSymbols = true
                                : matchingLayer.scaleSymbols = false;
                          },
                          // Set the title of the checkbox to the layer name.
                          title: Text(
                            layer,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      // Add text to display the current map scale.
                      Text(
                        'Map Scale',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        formatAsScale(_mapViewController.scale),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  // Add a button to set the map scale to the reference scale.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Set the map scale to the reference scale and close the settings dialog.
                        _mapViewController.setViewpointScale(
                          scale: _map.referenceScale,
                        );
                        setState(() => _bottomSheetVisible = false);
                      },
                      child: const Text('Set to Reference Scale'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create a function to format the scale.
  String formatAsScale(double value) {
    return '1:${value.toInt().toString().replaceAllMapped(_digitGroupRegex, matchFormatter)}';
  }

  // Create a helpder function to be applied on the regular expression.
  String Function(Match) matchFormatter = (Match match) => '${match[1]},';
}
