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

class DisplayLocalScene extends StatefulWidget {
  const DisplayLocalScene({super.key});

  @override
  State<DisplayLocalScene> createState() => _DisplayLocalSceneState();
}

class _DisplayLocalSceneState extends State<DisplayLocalScene>
    with SampleStateSupport {
  // Create a controller for the local scene view.
  final _localSceneViewController = ArcGISLocalSceneView.createController();

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
    // Create a scene with a topographic basemap and a local scene viewing mode.
    final scene = ArcGISScene.withBasemapStyle(
      BasemapStyle.arcGISTopographic,
      viewingMode: SceneViewingMode.local,
    );

    // Create the 3d scene layer.
    final sceneLayer = ArcGISSceneLayer.withUri(
      Uri.parse(
        'https://www.arcgis.com/home/item.html?id=61da8dc1a7bc4eea901c20ffb3f8b7af',
      ),
    );

    // Add world elevation source to the scene's surface.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    // Add the scene layer to the scene's operational layers.
    scene.operationalLayers.add(sceneLayer);

    // Set the clipping area for the local scene.
    scene.clippingArea = Envelope.fromXY(
      xMin: 19454578.8235,
      yMin: -5055381.4798,
      xMax: 19455518.8814,
      yMax: -5054888.4150,
      spatialReference: SpatialReference.webMercator,
    );

    // Enable the clipping area so only the scene elements within the clipping
    // area are rendered.
    scene.isClippingEnabled = true;

    // Set the scene's initial viewpoint.
    final camera = Camera.withLocation(
      location: ArcGISPoint(
        x: 19455578.6821,
        y: -5056336.2227,
        z: 1699.3366,
        spatialReference: SpatialReference.webMercator,
      ),
      heading: 338.7410,
      pitch: 40.3763,
      roll: 0,
    );
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(
        x: 19455026.8116,
        y: -5054995.7415,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 8314.6991,
      camera: camera,
    );

    // Apply the scene to the local scene view controller.
    _localSceneViewController.arcGISScene = scene;
  }
}
