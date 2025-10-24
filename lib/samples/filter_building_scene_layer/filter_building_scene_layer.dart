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
import 'package:flutter/material.dart';

class FilterBuildingSceneLayer extends StatefulWidget {
  const FilterBuildingSceneLayer({super.key});

  @override
  State<FilterBuildingSceneLayer> createState() =>
      _FilterBuildingSceneLayerState();
}

class _FilterBuildingSceneLayerState extends State<FilterBuildingSceneLayer>
    with SampleStateSupport {
  // Create a controller for the local scene view.
  final _localSceneViewController = ArcGISLocalSceneView.createController();

  // BuildingSceneLayer that will be filtered. Set after the WebScene is loaded.
  late final BuildingSceneLayer _buildingSceneLayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a local scene view to the widget tree and set a controller.
      body: ArcGISLocalSceneView(
        controllerProvider: () => _localSceneViewController,
        onLocalSceneViewReady: onLocalSceneViewReady,
      ),
    );
  }

  Future<void> onLocalSceneViewReady() async {
    // Create the local scene from a ArcGISOnline web scene.
    final sceneUri = Uri.parse(
      'https://arcgisruntime.maps.arcgis.com/home/item.html?id=b7c387d599a84a50aafaece5ca139d44',
    );
    final scene = ArcGISScene.withUri(sceneUri)!;
    await scene.load();

    // Get the BuildingSceneLayer from the webmap.
    _buildingSceneLayer =
        scene.operationalLayers.firstWhere(
              (layer) => layer is BuildingSceneLayer,
            )
            as BuildingSceneLayer;

    // Apply the scene to the local scene view controller.
    _localSceneViewController.arcGISScene = scene;
  }
}
