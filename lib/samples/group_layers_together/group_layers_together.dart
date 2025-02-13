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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class GroupLayersTogether extends StatefulWidget {
  const GroupLayersTogether({super.key});

  @override
  State<GroupLayersTogether> createState() => _GroupLayersTogetherState();
}

class _GroupLayersTogetherState extends State<GroupLayersTogether>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: () => setState(() => _settingsVisible = true),
                      child: const Text('Settings'),
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
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _mapViewController.arcGISMap?.operationalLayers
                      .whereType<GroupLayer>()
                      .map(buildGroupLayerSettings)
                      .toList() ??
                  [],
            ),
          ),
        ),
      ],
    );
  }

  static const displayName = <String, String>{
    'DevelopmentProjectArea': 'Project Area',
    'DevA_Pathways': 'Pathways',
  };

  // Create Widgets to control the Group Layer and its layers.
  Widget buildGroupLayerSettings(GroupLayer groupLayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              groupLayer.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            // Create a Switch to toggle the visibility of the Group Layer.
            Switch(
              value: groupLayer.isVisible,
              onChanged: (value) {
                groupLayer.isVisible = value;
                setState(() {});
              },
            ),
          ],
        ),
        // Create a list of Switches to toggle the visibility of the individual layers.
        ...groupLayer.layers.map(
          (layer) {
            return Row(
              children: [
                Text(displayName[layer.name] ?? layer.name),
                const Spacer(),
                // Create a Switch to toggle the visibility of the individual layer.
                Switch(
                  value: layer.isVisible,
                  onChanged: groupLayer.isVisible
                      ? (value) {
                          layer.isVisible = value;
                          setState(() {});
                        }
                      : null,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> onMapViewReady() async {
    // Create a Group Layer for the Project Area Group.
    final projectAreaGroupLayer = GroupLayer()..name = 'Project Area Group';
    // Create a Feature Layer for the Project Area.
    final projectAreaTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevelopmentProjectArea/FeatureServer/0',
      ),
    );
    final projectAreaLayer = FeatureLayer.withFeatureTable(projectAreaTable);
    // Create a Feature Layer for the Pathways.
    final pathwaysTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_Pathways/FeatureServer/1',
      ),
    );
    final pathwaysLayer = FeatureLayer.withFeatureTable(pathwaysTable);
    // Add the layers to the Group Layer.
    projectAreaGroupLayer.layers.addAll([projectAreaLayer, pathwaysLayer]);

    // Create a map with the ArcGIS Streets basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    // Add the Group Layers to the map.
    map.operationalLayers.addAll([projectAreaGroupLayer]);

    // Load a layer so that the group layer has a full extent.
    await projectAreaLayer.load();
    if (projectAreaGroupLayer.fullExtent != null) {
      // Set the initial viewpoint to the full extent of the group layer.
      map.initialViewpoint =
          Viewpoint.fromTargetExtent(projectAreaGroupLayer.fullExtent!);
    }

    // Set the map to the map view.
    _mapViewController.arcGISMap = map;
    // Set the ready state variable to true to enable the UI.
    setState(() => _ready = true);
  }
}
