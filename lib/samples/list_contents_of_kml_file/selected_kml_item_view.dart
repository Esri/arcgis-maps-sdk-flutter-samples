// Copyright 2026 Esri
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

class SelectedKmlItemView extends StatefulWidget {
  const SelectedKmlItemView({
    required this._kmlDataset,
    required this._selectedKmlNode,
    super.key,
  });

  final KmlDataset _kmlDataset;
  final KmlNode _selectedKmlNode;

  @override
  State<SelectedKmlItemView> createState() => _SelectedKmlItemViewState();
}

class _SelectedKmlItemViewState extends State<SelectedKmlItemView>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget._selectedKmlNode.name)),
      body: SafeArea(
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with an imagery basemap style and add it to the scene view.
    final scene = ArcGISScene.withBasemapStyle(.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Add a surface to the scene based on elevation data.
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );

    // Create a KML layer and add it to the scene.
    final kmlLayer = KmlLayer(widget._kmlDataset);
    scene.operationalLayers.add(kmlLayer);

    // Set the viewpoint based on the selected node.
    final viewpoint = await _createViewpointForKmlNode(
      widget._selectedKmlNode,
      scene.baseSurface,
    );
    if (viewpoint != null) {
      _sceneViewController.setViewpoint(viewpoint);
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<Viewpoint?> _createViewpointForKmlNode(
    KmlNode kmlNode,
    Surface surface,
  ) async {
    // Ensure the surface for the scene is loaded.
    if (surface.loadStatus != .loaded) {
      await surface.load();
    }

    final kmlViewpoint = kmlNode.viewpoint;
    if (kmlViewpoint != null) {
      return _createViewpointWithKmlViewpoint(kmlViewpoint, surface);
    } else if (kmlNode.extent != null) {
      return _viewpointWithExtent(kmlNode.extent, surface);
    } else {
      return null;
    }
  }

  Future<Viewpoint> _createViewpointWithKmlViewpoint(
    KmlViewpoint kmlViewpoint,
    Surface surface,
  ) async {
    // Center on the selected KML node.
    final Camera viewpointCamera;

    if (kmlViewpoint.type == .lookAt) {
      var lookAtPoint = kmlViewpoint.location;
      if (kmlViewpoint.altitudeMode != .absolute) {
        // If the elevation is relative, account for the surface's elevation.
        final elevation = await surface.getElevation(kmlViewpoint.location);
        final kmlViewpointAltitude = kmlViewpoint.location.z ?? 0;
        lookAtPoint = ArcGISPoint(
          x: kmlViewpoint.location.x,
          y: kmlViewpoint.location.y,
          z: kmlViewpointAltitude + elevation,
        );
      }

      viewpointCamera = Camera.withLookAtPoint(
        lookAtPoint: lookAtPoint,
        distance: kmlViewpoint.range,
        heading: kmlViewpoint.heading,
        pitch: kmlViewpoint.pitch,
        roll: kmlViewpoint.roll,
      );
    } else {
      viewpointCamera = Camera.withLocation(
        location: kmlViewpoint.location,
        heading: kmlViewpoint.heading,
        pitch: kmlViewpoint.pitch,
        roll: kmlViewpoint.roll,
      );
    }

    final viewpoint = Viewpoint.withExtentCamera(
      targetExtent: widget._selectedKmlNode.extent!,
      camera: viewpointCamera,
    );

    return viewpoint;
  }

  Future<Viewpoint?> _viewpointWithExtent(
    Envelope? extent,
    Surface surface,
  ) async {
    if (extent == null || extent.isEmpty) return null;

    final extentCenter = extent.center;
    final elevation = await surface.getElevation(extentCenter);

    if (extent.width == 0 || extent.height == 0) {
      // If the extent is not empty, but the width and height are still zero,
      // default values (based on Google Earth) are used to create a camera.
      final centerAltitude = extentCenter.z ?? 0;
      final elevatedCenter = ArcGISPoint(
        x: extentCenter.x,
        y: extentCenter.y,
        z: centerAltitude + elevation,
      );
      final camera = Camera.withLookAtPoint(
        lookAtPoint: elevatedCenter,
        distance: 1000,
        heading: 0,
        pitch: 45,
        roll: 0,
      );

      return Viewpoint.withLatLongScaleCamera(
        latitude: .nan,
        longitude: .nan,
        scale: .nan,
        camera: camera,
      );
    } else {
      final extentBuilder = EnvelopeBuilder.fromEnvelope(extent)
        ..zMax += elevation
        ..zMin += elevation
        ..expandBy(1.1);

      return Viewpoint.fromTargetExtent(extentBuilder.extent);
    }
  }
}
