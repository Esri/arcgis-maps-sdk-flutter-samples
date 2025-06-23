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

class SetSurfaceNavigationConstraint extends StatefulWidget {
  const SetSurfaceNavigationConstraint({super.key});

  @override
  State<SetSurfaceNavigationConstraint> createState() =>
      _SetSurfaceNavigationConstraintState();
}

class _SetSurfaceNavigationConstraintState
    extends State<SetSurfaceNavigationConstraint>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISSceneView(
        controllerProvider: () => _sceneViewController,
        onSceneViewReady: onSceneViewReady,
      ),
    );
  }

  void onSceneViewReady() {
    // Create the portal item with the item ID for the web scene.
    const itemId = '91a4fafd747a47c7bab7797066cb9272';
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: itemId,
    );

    // Create the scene with the portal item.
    final scene = ArcGISScene.withItem(portalItem);

    // Set the opacity so that is is possible to see below the surface.
    scene.baseSurface.opacity = 0.7;

    // Set the navigation constraint to none so that the camera can pass above and
    // below the elevation surface.
    scene.baseSurface.navigationConstraint = NavigationConstraint.none;

    // Set the scene to the scene view controller.
    _sceneViewController.arcGISScene = scene;
  }
}
