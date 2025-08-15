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
import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

class Animate3dGraphic extends StatefulWidget {
  const Animate3dGraphic({super.key});

  @override
  State<Animate3dGraphic> createState() => _Animate3dGraphicState();
}

class _Animate3dGraphicState extends State<Animate3dGraphic>
    with TickerProviderStateMixin, SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  // The graphic for the plane.
  Graphic? _planeGraphic;

  // Track mission modal status.
  StateSetter? _modalStateSetter;

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

  // State variables for real-time telemetry tracking.
  double _altitude = 0;
  double _heading = 0;
  double _pitch = 0;
  double _roll = 0;

  // The current progress of the animation.
  double get _progress {
    if (_frames.isEmpty) return 0;
    return _currentFrameIndex.toDouble() / _frames.length.toDouble();
  }

  @override
  void initState() {
    super.initState();
    // Start the animation ticker.
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    // Cleanup the ticker.
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
            // Show real-time telemetry data.
            Visibility(
              visible: _ready,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    width: 170,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTelemetryRow('Altitude', _altitude),
                        _buildTelemetryRow('Heading', _heading),
                        _buildTelemetryRow('Pitch', _pitch),
                        _buildTelemetryRow('Roll', _roll),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Display a loading indicator until the scene is ready.
            LoadingIndicator(visible: !_ready),
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
    const downloadFileName = 'Bristol';
    final appDir = await getApplicationDocumentsDirectory();
    final zipFile = File('${appDir.absolute.path}/$downloadFileName.zip');
    // Download the plane model files.
    if (!zipFile.existsSync()) {
      await downloadSampleDataWithProgress(
        itemIds: ['681d6f7694644709a7c830ec57a2d72b'],
        destinationFiles: [zipFile],
      );
    }
    final planeModelPath =
        '${appDir.absolute.path}/$downloadFileName/$downloadFileName.dae';

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

    // Apply renderer expressions for heading, pitch, and roll.
    final renderer = SimpleRenderer()
      ..sceneProperties.headingExpression = '[HEADING]'
      ..sceneProperties.pitchExpression = '[PITCH]'
      ..sceneProperties.rollExpression = '[ROLL]';
    graphicsOverlay.renderer = renderer;

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
      } on Exception {
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

    setState(() {
      _altitude = frame.position.z ?? 0;
      _heading = frame.heading;
      _pitch = frame.pitch;
      _roll = frame.roll;
    });
  }

  // Telemetry Row Widget.
  Widget _buildTelemetryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(
            label == 'Altitude'
                ? '${value.toStringAsFixed(0)} m'
                : '${value.toStringAsFixed(0)}°',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
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
    });

    // Update modal sheet if it's open.
    _modalStateSetter?.call(() {});

    _updateFrame(_frames[_currentFrameIndex]);
  }

  // Toggles the animation play/pause state.
  void _toggleAnimation() {
    if (_planeGraphic == null || _frames.isEmpty) return;

    setState(() => _isPlaying = !_isPlaying);
  }

  // Shows the mission settings in a bottom sheet.
  void _showMissionSettings() {
    showModalBottomSheet<void>(
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

              // Progress widgets have to update for every frame, so wrapped with a StatefulBuilder.
              StatefulBuilder(
                builder: (context, setModalState) {
                  // Store the setter.
                  _modalStateSetter = setModalState;
                  return Column(
                    children: [
                      // Progress Indicator
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              '${(_progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      LinearProgressIndicator(value: _progress),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              // Dropdown to select mission.
              DropdownMenu(
                initialSelection: _currentMission,
                onSelected: (mission) {
                  if (mission != null) {
                    setState(() {
                      _currentMission = mission;
                      _currentFrameIndex = 0;
                      _isPlaying = false;
                    });
                    // Update the modal to show progress reset to 0
                    _modalStateSetter?.call(() {});

                    _loadMissionFrames(mission);
                  }
                },
                dropdownMenuEntries: Mission.values.map((mission) {
                  return DropdownMenuEntry(
                    value: mission,
                    label: mission.label,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownMenu(
                initialSelection: _animationSpeed,
                onSelected: (speed) {
                  if (speed != null) {
                    setState(() => _animationSpeed = speed);
                  }
                },
                dropdownMenuEntries: AnimationSpeed.values.map((speed) {
                  return DropdownMenuEntry(
                    value: speed,
                    label: 'Speed: ${speed.label}',
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _modalStateSetter = null;
    });
  }

  // Shows the camera settings in a bottom sheet.
  void _showCameraSettings() {
    showModalBottomSheet<void>(
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
                      _cameraController.cameraDistance = value;
                    },
                  ),
                  _buildSlider(
                    label: 'Heading Offset',
                    value: _cameraHeading,
                    min: -180,
                    max: 180,
                    onChanged: (value) {
                      setModalState(() => _cameraHeading = value);
                      _cameraController.cameraHeadingOffset = value;
                    },
                  ),
                  _buildSlider(
                    label: 'Pitch Offset',
                    value: _cameraPitch,
                    min: 0,
                    max: 180,
                    onChanged: (value) {
                      setModalState(() => _cameraPitch = value);
                      _cameraController.cameraPitchOffset = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Heading'),
                    value: _autoHeading,
                    onChanged: (value) {
                      setModalState(() => _autoHeading = value);
                      _cameraController.isAutoHeadingEnabled = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Pitch'),
                    value: _autoPitch,
                    onChanged: (value) {
                      setModalState(() => _autoPitch = value);
                      _cameraController.isAutoPitchEnabled = value;
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Roll'),
                    value: _autoRoll,
                    onChanged: (value) {
                      setModalState(() => _autoRoll = value);
                      _cameraController.isAutoRollEnabled = value;
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
enum Mission {
  grandCanyon('Grand Canyon', '290f0c571c394461a8b58b6775d0bd63'),
  hawaii('Hawaii', 'e87c154fb9c2487f999143df5b08e9b1'),
  pyrenees('Pyrenees', '5a9b60cee9ba41e79640a06bcdf8084d'),
  snowdon('Snowdon', '12509ffdc684437f8f2656b0129d2c13');

  const Mission(this.label, this.itemId);

  // A human-readable label of the mission name.
  final String label;

  // The ArcGIS Online item ID for the mission CSV file.
  final String itemId;
}

// An enum representing the speed of the animation.
enum AnimationSpeed {
  slow(1),
  medium(2),
  fast(4);

  const AnimationSpeed(this.frameStep);

  // The number of frames to advance per tick.
  final int frameStep;

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
