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
import 'package:path_provider/path_provider.dart';

class ChangeCameraController extends StatefulWidget {
  const ChangeCameraController({super.key});

  @override
  State<ChangeCameraController> createState() => _ChangeCameraControllerState();
}

class _ChangeCameraControllerState extends State<ChangeCameraController>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  // The graphic for the plane.
  Graphic? _planeGraphic;

  // The type of CameraController currently being used.
  var _selectedCameraControllerKind = CameraControllerKind.globe;

  final _cameraControllerDropdownEntries =
      <DropdownMenuEntry<CameraControllerKind>>[];

  @override
  void initState() {
    super.initState();

    _cameraControllerDropdownEntries.addAll([
      const DropdownMenuEntry(
        value: CameraControllerKind.globe,
        label: 'Global',
      ),
      const DropdownMenuEntry(
        value: CameraControllerKind.orbitLocation,
        label: 'Orbit crater',
      ),
      const DropdownMenuEntry(
        value: CameraControllerKind.orbitGeoElement,
        label: 'Orbit plane',
      ),
    ]);
  }

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
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Select Camera Controller:'),
                    // Create a dropdown menu to select a feature layer source.
                    DropdownMenu(
                      dropdownMenuEntries: _cameraControllerDropdownEntries,
                      trailingIcon: const Icon(Icons.arrow_drop_down),
                      textAlign: TextAlign.center,
                      textStyle: Theme.of(context).textTheme.labelMedium,
                      hintText: 'Select a camera controller',
                      onSelected: handleCameraControllerSelection,
                      initialSelection: _selectedCameraControllerKind,
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
    );
  }

  Future<void> onSceneViewReady() async {
    // Add the scene to the view controller.
    final scene = _setupScene();
    _sceneViewController.arcGISScene = scene;

    // Graphics overlay for the plane
    final graphicsOverlay = GraphicsOverlay();
    _planeGraphic = await _setupPlaneGraphic();
    graphicsOverlay.graphics.add(_planeGraphic!);
    graphicsOverlay.sceneProperties.surfacePlacement =
        SurfacePlacement.absolute;

    _sceneViewController.graphicsOverlays.add(graphicsOverlay);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void handleCameraControllerSelection(
    CameraControllerKind? cameraControllerKind,
  ) {
    if (cameraControllerKind == null || _planeGraphic == null) return;

    switch (cameraControllerKind) {
      case CameraControllerKind.globe:
        _sceneViewController.cameraController = GlobeCameraController();
      case CameraControllerKind.orbitGeoElement:
        final cameraController = OrbitGeoElementCameraController(
          targetGeoElement: _planeGraphic!,
          distance: 1700,
        );

        cameraController.cameraPitchOffset = 3;
        cameraController.cameraHeadingOffset = 150;
        _sceneViewController.cameraController = cameraController;
      case CameraControllerKind.orbitLocation:
        final cameraController =
            OrbitLocationCameraController.withTargetPositionAndCameraDistance(
              targetLocation: ArcGISPoint(
                x: -109.929589,
                y: 38.437304,
                z: 1700,
                spatialReference: SpatialReference.wgs84,
              ),
              distance: 10000,
            );

        cameraController.cameraPitchOffset = 3;
        cameraController.cameraHeadingOffset = 150;
        _sceneViewController.cameraController = cameraController;
    }

    setState(() {
      _selectedCameraControllerKind = cameraControllerKind;
    });
  }

  ArcGISScene _setupScene() {
    // Create a scene with an imagery basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Set the scene's initial viewpoint.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: Camera.withLookAtPoint(
        lookAtPoint: ArcGISPoint(
          x: -109.93330428076712,
          y: 38.454207465344282,
          spatialReference: SpatialReference.wgs84,
        ),
        distance: 10000,
        heading: 150,
        pitch: 20,
        roll: 0,
      ),
    );

    // Add surface elevation to the scene.
    final surface = Surface();
    final worldElevationService = Uri.parse(
      'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
    );
    final elevationSource = ArcGISTiledElevationSource.withUri(
      worldElevationService,
    );
    surface.elevationSources.add(elevationSource);
    scene.baseSurface = surface;

    return scene;
  }

  Future<Graphic> _setupPlaneGraphic() async {
    // Download the plane model files
    await downloadSampleData(['681d6f7694644709a7c830ec57a2d72b']);
    final documentsDirPath =
        (await getApplicationDocumentsDirectory()).absolute.path;
    final planeModelPath = '$documentsDirPath/Bristol/Bristol.dae';

    final planePosition = ArcGISPoint(
      x: -109.937516,
      y: 38.456714,
      z: 5000,
      spatialReference: SpatialReference.wgs84,
    );

    final planeSymbol = ModelSceneSymbol.withUri(
      uri: Uri.parse(planeModelPath),
      scale: 50,
    );

    final planeGraphic = Graphic(geometry: planePosition, symbol: planeSymbol);

    return planeGraphic;
  }
}

enum CameraControllerKind { globe, orbitLocation, orbitGeoElement }
