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

class SetReferenceScaleSample extends StatefulWidget {
  const SetReferenceScaleSample({super.key});

  @override
  State<SetReferenceScaleSample> createState() => _SetReferenceScaleState();
}

class _SetReferenceScaleState extends State<SetReferenceScaleSample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a list of dropdown menu items to load all the reference scales.
  final _referenceScaleList = <DropdownMenuItem<double>>[];
  // Create a list of possible reference scales.
  final _possibleReferenceScales = <double>[500000, 250000, 100000, 50000];
  // Create a list of selected feature layers.
  final _selectedFeatureLayers = <String>[];
  // Create a list of all feature layers.
  final _allFeatureLayers = <String>[];
  // Create a variable to store the map.
  var _map = ArcGISMap();
  // Create a variable to store the scale.
  var _scale = 250000.0;
  // Create a variable to store the ready state.
  var _ready = false;
  // Create a variable to store the selected feature layer source.
  int? _selectedScale;

  @override
  void initState() {
    super.initState();
    // Add scales to the list.
    _referenceScaleList.addAll([
      DropdownMenuItem(
        value: _possibleReferenceScales[0],
        child: const Text('1:500,000'),
      ),
      DropdownMenuItem(
        value: _possibleReferenceScales[1],
        child: const Text('1:250,000'),
      ),
      DropdownMenuItem(
        value: _possibleReferenceScales[2],
        child: const Text('1:100,000'),
      ),
      DropdownMenuItem(
        value: _possibleReferenceScales[3],
        child: const Text('1:50,000'),
      )
    ]);
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
            // Add a Settings button to the widget tree.
            ElevatedButton(
              // Show the settings dialog when the button is pressed.
              onPressed: _ready
                  ? () => showDialog(
                        context: context,
                        builder: (context) => showSettings(context),
                      )
                  : null,
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.deepPurple,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create a portal item.
    final portal = Portal.arcGISOnline();
    final portalItem = PortalItem.withPortalAndItemId(
        portal: portal, itemId: '3953413f3bd34e53a42bf70f2937a408');
    // Load the portal item.
    await portalItem.load();

    // Create a map from the portal item and load it.
    _map = ArcGISMap.withItem(portalItem);
    await _map.load();

    // Get the operational layers from the map.
    for (var layer in _map.operationalLayers) {
      _allFeatureLayers.add(layer.name);
    }
    _mapViewController.arcGISMap = _map;

    // See if the map is ready.
    setState(() => _ready = true);
  }

  StatefulBuilder showSettings(BuildContext newContext) {
    // Show the settings dialog.
    return StatefulBuilder(builder: (newContext, setNewState) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Center(
                child: Text('Settings',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              // Add a dropdown button for setting a new reference scale.
              DropdownButton(
                alignment: Alignment.center,
                hint: const Text(
                  'Select a New Reference Scale',
                  style: TextStyle(
                    color: Colors.deepPurple,
                  ),
                ),
                // Set the selected scale
                value: _selectedScale,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.deepPurple,
                ),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                // Set the onChanged callback to update the selected scale.
                onChanged: (newScale) {
                  updateScale(newScale!.toDouble());
                },
                items: _referenceScaleList,
              ),
              const Text(
                'Apply Reference Scale to a Layer',
              ),
              // Add a list of checkboxes for selecting feature layers that will honor the reference scale.
              Column(
                children: [
                  // Create a checkbox for each feature layer.
                  for (var layer in _allFeatureLayers)
                    CheckboxListTile(
                      value: _selectedFeatureLayers.contains(layer),
                      onChanged: (value) {
                        // Update the selected feature layers.
                        setNewState(() {
                          if (value ?? false) {
                            _selectedFeatureLayers.add(layer);
                          } else {
                            _selectedFeatureLayers.remove(layer);
                          }
                        });
                      },
                      title: Text(layer),
                    ),
                ],
              ),
              // Add a button to set the map scale to the reference scale and update the layers.
              ElevatedButton(
                onPressed: () {
                  setScaleAndLayers();
                  Navigator.pop(newContext);
                },
                child: const Text('Set Map Scale to Reference Scale'),
              ),
            ],
          ),
        ),
      );
    });
  }

  void updateScale(double newScale) {
    // Update the scale.
    setState(() => _scale = newScale);
  }

  void setScaleAndLayers() {
    // Set the map scale to the reference scale and update the layers.
    setState(() {
      // Set the map scale to the reference scale.
      _map.referenceScale = _scale;
      // Update the layers to honor the reference scale.
      for (var layer in _selectedFeatureLayers) {
        var matchingLayers = _map.operationalLayers
            .where((element) => element.name == layer)
            .first as FeatureLayer;
        matchingLayers.scaleSymbols = true;
      }
    });
  }
}
