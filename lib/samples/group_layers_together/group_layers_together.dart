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
import 'package:arcgis_maps_sdk/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

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
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
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
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
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
      ),
    );
  }

  Widget buildGroupLayerSettings(GroupLayer groupLayer) {
    return ListTile(
      title: Text(groupLayer.name),
    );
  }

  void onMapViewReady() async {
    //fixme comments
    final projectAreaGroupLayer = GroupLayer()..name = 'Project Area Group';
    final projectAreaTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevelopmentProjectArea/FeatureServer/0',
      ),
    );
    final projectAreaLayer = FeatureLayer.withFeatureTable(projectAreaTable);
    final pathwaysTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_Pathways/FeatureServer/1',
      ),
    );
    final pathwaysLayer = FeatureLayer.withFeatureTable(pathwaysTable);
    projectAreaGroupLayer.layers.addAll([projectAreaLayer, pathwaysLayer]);

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    map.operationalLayers.addAll([projectAreaGroupLayer]);

    await projectAreaLayer.load();
    if (projectAreaGroupLayer.fullExtent != null) {
      map.initialViewpoint =
          Viewpoint.fromTargetExtent(projectAreaGroupLayer.fullExtent!);
    }

    _mapViewController.arcGISMap = map;
    setState(() => _ready = true);
  }
}
