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

import 'dart:convert';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

class Animate3DGraphic extends StatefulWidget {
  const Animate3DGraphic({super.key});

  @override
  State<Animate3DGraphic> createState() => _Animate3DGraphicState();
}

class _Animate3DGraphicState extends State<Animate3DGraphic>
    with TickerProviderStateMixin, SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  // The graphic for the plane.
  Graphic? _planeGraphic;

  // The camera controller that follows the plane.
  late OrbitGeoElementCameraController _cameraController;

  // Whether the animation is currently playing.
  var _isPlaying = false;

  // The current frame index in the animation.
  var _currentFrameIndex = 0;

  // The list of animation frames.
  var _frames = <Frame>[];

  // The ticker that drives the animation.
  late final Ticker _ticker;

  // The currently selected mission.
  var _currentMission = Mission.grandCanyon;

  // The selected animation speed.
  var _animationSpeed = AnimationSpeed.medium;

  // Camera controller settings.
  double _cameraDistance = 1000;
  double _cameraHeading = 0;
  double _cameraPitch = 0;
  var _autoHeading = true;
  var _autoPitch = false;
  var _autoRoll = false;

  // The current progress of the animation.
  double get _progress {
    if (_frames.isEmpty) return 0;
    return _currentFrameIndex / _frames.length;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Button to open mission settings.
                    ElevatedButton(
                      onPressed: _showMissionSettings,
                      child: const Text('Mission'),
                    ),
                    // Play/pause button.
                    IconButton(
                      onPressed: _toggleAnimation,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    // Button to open camera settings.
                    ElevatedButton(
                      onPressed: _showCameraSettings,
                      child: const Text('Camera'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a loading indicator until the scene is ready.
            if (!_ready) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  // Called when the scene view is ready.
  Future<void> onSceneViewReady() async {
    // Create and configure the scene with elevation.
    final scene = _createScene();
    // Assign the scene to the scene view controller.
    _sceneViewController.arcGISScene = scene;

    // Load the 3D plane graphic from local sample data.
    _planeGraphic = await _loadPlaneGraphic();

    // Add the plane graphic to the scene and set the initial viewpoint.
    await _addPlaneToScene(_planeGraphic!);

    // Set up the orbit camera controller to follow the plane.
    _setupCameraController(_planeGraphic!);

    // Load the default mission animation frames.
    await _loadMissionFrames(_currentMission);

    // Enable the UI once everything is ready.
    setState(() => _ready = true);
  }

  // Creates a scene with an imagery basemap and adds elevation data.
  ArcGISScene _createScene() {
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);

    // Add world elevation source to the scene's surface.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    return scene;
  }

  // Loads the 3D plane model from local sample data and returns it as a Graphic.
  Future<Graphic> _loadPlaneGraphic() async {

    await downloadSampleData(['681d6f7694644709a7c830ec57a2d72b']);
    final documentsDirPath =
        (await getApplicationDocumentsDirectory()).absolute.path;
    final planeModelPath = '$documentsDirPath/Bristol/Bristol.dae';

    // Define the plane symbol.
    final planeSymbol = ModelSceneSymbol.withUri(
      uri: Uri.parse(planeModelPath),
      scale: 20,
    )..anchorPosition = SceneSymbolAnchorPosition.center;

    // Define the initial position of the plane in the scene.
    final planePosition = ArcGISPoint(
      x: -109.937516,
      y: 38.456714,
      z: 5000,
      spatialReference: SpatialReference.wgs84,
    );

    // Return the graphic that combines geometry and symbol.
    return Graphic(geometry: planePosition, symbol: planeSymbol);
  }

  // Adds the plane graphic to a graphics overlay and sets the initial viewpoint.
  Future<void> _addPlaneToScene(Graphic planeGraphic) async {
    final graphicsOverlay = GraphicsOverlay()
      ..graphics.add(planeGraphic)
      ..sceneProperties.surfacePlacement = SurfacePlacement.absolute;

    _sceneViewController.graphicsOverlays.add(graphicsOverlay);

    // Set the initial viewpoint centered on the plane's position.
    final planePosition = planeGraphic.geometry! as ArcGISPoint;
    _sceneViewController.setViewpoint(
      Viewpoint.withPointScaleCamera(
        center: planePosition,
        scale: 100000,
        camera: Camera.withLookAtPoint(
          lookAtPoint: planePosition,
          distance: _cameraDistance,
          heading: _cameraHeading,
          pitch: _cameraPitch,
          roll: 0,
        ),
      ),
    );
  }

  // Configures the orbit camera controller to follow the plane graphic.
  void _setupCameraController(Graphic planeGraphic) {
    _cameraController =
    OrbitGeoElementCameraController(
      targetGeoElement: planeGraphic,
      distance: _cameraDistance,
    )
      ..cameraHeadingOffset = _cameraHeading
      ..cameraPitchOffset = _cameraPitch
      ..isAutoHeadingEnabled = _autoHeading
      ..isAutoPitchEnabled = _autoPitch
      ..isAutoRollEnabled = _autoRoll
      ..minCameraDistance = 500
      ..maxCameraDistance = 8000;

    _sceneViewController.cameraController = _cameraController;
  }

  // Loads mission frames from a CSV file using a PortalItem.
  Future<void> _loadMissionFrames(Mission mission) async {
    final portal = Portal.arcGISOnline();
    final item = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: mission.itemId,
    );
    final data = await item.fetchData();
    final csv = utf8.decode(data);

    final lines = const LineSplitter().convert(csv);
    final frames = <Frame>[];

    for (final line in lines) {
      final parts = line.split(',');
      if (parts.length < 6) continue;

      try {
        final x = double.parse(parts[0]);
        final y = double.parse(parts[1]);
        final z = double.parse(parts[2]);
        final heading = double.parse(parts[3]);
        final pitch = double.parse(parts[4]);
        final roll = double.parse(parts[5]);

        final position = ArcGISPoint(
          x: x,
          y: y,
          z: z,
          spatialReference: SpatialReference.wgs84,
        );

        frames.add(
          Frame(position: position, heading: heading, pitch: pitch, roll: roll),
        );
      } catch (_) {
        continue;
      }
    }

    setState(() {
      _frames = frames;
      _currentFrameIndex = 0;
      _isPlaying = false;
    });

    if (_frames.isNotEmpty) {
      _updateFrame(_frames.first);
    }
  }

  // Updates the plane graphic with the current frame data.
  void _updateFrame(Frame frame) {
    if (_planeGraphic == null) return;

    _planeGraphic!.geometry = frame.position;
    _planeGraphic!.attributes['HEADING'] = frame.heading;
    _planeGraphic!.attributes['PITCH'] = frame.pitch;
    _planeGraphic!.attributes['ROLL'] = frame.roll;
  }

  // Called on each tick to advance the animation.
  void _onTick(Duration elapsed) {
    if (!_isPlaying || _frames.isEmpty || _planeGraphic == null) return;

    setState(() {
      _currentFrameIndex += _animationSpeed.frameStep;
      if (_currentFrameIndex >= _frames.length) {
        _currentFrameIndex = 0;
        _isPlaying = false;
      }
      _updateFrame(_frames[_currentFrameIndex]);
    });
  }

  // Toggles the animation play/pause state.
  void _toggleAnimation() {
    if (_planeGraphic == null || _frames.isEmpty) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Shows the mission settings in a bottom sheet.
  void _showMissionSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mission Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Progress bar showing animation progress.
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 24),
              // Dropdown to select mission.
              DropdownButton<Mission>(
                value: _currentMission,
                isExpanded: true,
                onChanged: (mission) {
                  if (mission != null) {
                    Navigator.pop(context);
                    setState(() {
                      _currentMission = mission;
                      _currentFrameIndex = 0;
                      _isPlaying = false;
                    });
                    _loadMissionFrames(mission);
                  }
                },
                items: Mission.values.map((mission) {
                  return DropdownMenuItem(
                    value: mission,
                    child: Text(mission.label),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Dropdown to select animation speed.
              DropdownButton<AnimationSpeed>(
                value: _animationSpeed,
                isExpanded: true,
                onChanged: (speed) {
                  if (speed != null) {
                    setState(() => _animationSpeed = speed);
                  }
                },
                items: AnimationSpeed.values.map((speed) {
                  return DropdownMenuItem(
                    value: speed,
                    child: Text('Speed: ${speed.label}'),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Shows the camera settings in a bottom sheet.
  void _showCameraSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Camera Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    label: 'Distance',
                    value: _cameraDistance,
                    min: 500,
                    max: 8000,
                    onChanged: (value) {
                      setModalState(() => _cameraDistance = value);
                      setState(() => _cameraController.cameraDistance = value);
                    },
                  ),
                  _buildSlider(
                    label: 'Heading Offset',
                    value: _cameraHeading,
                    min: -180,
                    max: 180,
                    onChanged: (value) {
                      setModalState(() => _cameraHeading = value);
                      setState(
                            () => _cameraController.cameraHeadingOffset = value,
                      );
                    },
                  ),
                  _buildSlider(
                    label: 'Pitch Offset',
                    value: _cameraPitch,
                    min: 0,
                    max: 180,
                    onChanged: (value) {
                      setModalState(() => _cameraPitch = value);
                      setState(
                            () => _cameraController.cameraPitchOffset = value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Heading'),
                    value: _autoHeading,
                    onChanged: (value) {
                      setModalState(() => _autoHeading = value);
                      setState(
                            () => _cameraController.isAutoHeadingEnabled = value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Pitch'),
                    value: _autoPitch,
                    onChanged: (value) {
                      setModalState(() => _autoPitch = value);
                      setState(
                            () => _cameraController.isAutoPitchEnabled = value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Roll'),
                    value: _autoRoll,
                    onChanged: (value) {
                      setModalState(() => _autoRoll = value);
                      setState(
                            () => _cameraController.isAutoRollEnabled = value,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Builds a labeled slider widget.
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(0)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// An enum of the different mission selections available in this sample.
enum Mission { grandCanyon, hawaii, pyrenees, snowdon }

// To provide labels and ArcGIS Online item IDs for each mission.
extension MissionLabel on Mission {
  /// A human-readable label of the mission name.
  String get label {
    switch (this) {
      case Mission.grandCanyon:
        return 'Grand Canyon';
      case Mission.hawaii:
        return 'Hawaii';
      case Mission.pyrenees:
        return 'Pyrenees';
      case Mission.snowdon:
        return 'Snowdon';
    }
  }

  // The ArcGIS Online item ID for the mission CSV file.
  String get itemId {
    switch (this) {
      case Mission.grandCanyon:
        return '290f0c571c394461a8b58b6775d0bd63';
      case Mission.hawaii:
        return 'e87c154fb9c2487f999143df5b08e9b1';
      case Mission.pyrenees:
        return '5a9b60cee9ba41e79640a06bcdf8084d';
      case Mission.snowdon:
        return '12509ffdc684437f8f2656b0129d2c13';
    }
  }
}

// An enumeration representing the speed of the animation.
enum AnimationSpeed { slow, medium, fast }

// Extension to provide speed values and labels.
extension AnimationSpeedValue on AnimationSpeed {
  /// The number of frames to advance per tick.
  int get frameStep {
    switch (this) {
      case AnimationSpeed.slow:
        return 1;
      case AnimationSpeed.medium:
        return 2;
      case AnimationSpeed.fast:
        return 4;
    }
  }

  // A label for the speed.
  String get label => name[0].toUpperCase() + name.substring(1);
}

// A struct containing the location data for a single frame in a 3D animation.
class Frame {
  Frame({
    required this.position,
    required this.heading,
    required this.pitch,
    required this.roll,
  });

  final ArcGISPoint position;
  final double heading;
  final double pitch;
  final double roll;
}
