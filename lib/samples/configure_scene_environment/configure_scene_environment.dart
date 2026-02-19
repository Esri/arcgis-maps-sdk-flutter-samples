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

class ConfigureSceneEnvironment extends StatefulWidget {
  const ConfigureSceneEnvironment({super.key});

  @override
  State<ConfigureSceneEnvironment> createState() =>
      _ConfigureSceneEnvironmentState();
}

class _ConfigureSceneEnvironmentState extends State<ConfigureSceneEnvironment>
    with SampleStateSupport {
  // Get a controller for the ArcGISLocalSceneView
  final _localSceneViewController = ArcGISLocalSceneView.createController();

  // Flag to activate the settings bottom sheet.
  bool _showBottomSheet = false;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
                  // Add a local scene view to the widget tree and set a controller.
                  child: ArcGISLocalSceneView(
                    controllerProvider: () => _localSceneViewController,
                    onLocalSceneViewReady: onLocalSceneReady,
                  ),
                ),
                Center(
                  // Button to summon the scene environment settings.
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _showBottomSheet = !_showBottomSheet),
                    child: const Text('Show scene environment settings'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // Bottom sheet to show the scene environment settings controls.
      bottomSheet: _showBottomSheet
          ? SceneEnvironmentBottomSheet(
              localSceneViewController: _localSceneViewController,
              onClose: () => setState(() => _showBottomSheet = false),
            )
          : null,
    );
  }

  Future<void> onLocalSceneReady() async {
    // Create and load the local scene from a ArcGISOnline web scene.
    final websceneUri = Uri.parse(
      'https://maps.arcgis.com/home/item.html?id=fcebd77958634ac3874bbc0e6b0677a4',
    ); // Local scene with 3D trees and buildings
    final scene = ArcGISScene.withUri(websceneUri)!;
    await scene.load();

    // Set the scene on the local scene view.
    _localSceneViewController.arcGISScene = scene;

    setState(() {
      // The view is ready for interaction.
      _ready = true;
    });
  }
}

// Bottom sheet for the scene environment controls widget.
class SceneEnvironmentBottomSheet extends StatelessWidget {
  const SceneEnvironmentBottomSheet({
    required this.localSceneViewController,
    required this.onClose,
    super.key,
  });

  final ArcGISLocalSceneViewController localSceneViewController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BottomSheetSettings(
      title: 'Scene Environment Settings',
      onCloseIconPressed: onClose,
      settingsWidgets: (context) => [
        SceneEnvironmentSettings(scene: localSceneViewController.arcGISScene!),
      ],
    );
  }
}

// Widget containing all of the controls for configuring the scene environment settings.
class SceneEnvironmentSettings extends StatefulWidget {
  const SceneEnvironmentSettings({required this.scene, super.key});

  final ArcGISScene scene;

  @override
  State<StatefulWidget> createState() => _SceneEnvironmentSettingsState();
}

class _SceneEnvironmentSettingsState extends State<SceneEnvironmentSettings> {
  // Listing used for background color drop down.
  final _backgroundColorOptions = [
    (name: 'None', color: const Color.fromARGB(0, 0, 0, 0)),
    (name: 'Black', color: Colors.black),
    (name: 'Red', color: Colors.red),
    (name: 'Orange', color: Colors.orange),
    (name: 'Yellow', color: Colors.yellow),
    (name: 'Green', color: Colors.green),
    (name: 'Blue', color: Colors.blue),
    (name: 'Purple', color: Colors.purple),
    (name: 'White', color: Colors.white),
  ];

  // Initialize state variables for the control panel.
  var _isStarsEnabled = true;
  var _isAtmosphereEnabled = true;
  var _isDirectShadowsEnabled = false;
  var _backgroundColor = Colors.black;
  var _isSunLighting = false;
  var _lightingDateTime = DateTime.utc(2026, 3, 20, 12);
  var _lightingTimeZoneOffset = Duration.zero;
  var _lightingHour = 12;

  // Convenience variable to get the ArcGISScene from the widget.
  ArcGISScene get _scene => widget.scene;

  @override
  void initState() {
    super.initState();

    // Set the state variables based on the actual scene environment.
    _isAtmosphereEnabled = _scene.environment.isAtmosphereEnabled;
    _isStarsEnabled = _scene.environment.areStarsEnabled;
    _isDirectShadowsEnabled =
        _scene.environment.lighting.areDirectShadowsEnabled;
    _backgroundColor = _scene.environment.backgroundColor;

    if (_scene.environment.lighting is SunLighting) {
      // Record the simulated time from the web scene.
      final sunLighting = _scene.environment.lighting as SunLighting;
      _isSunLighting = true;

      _lightingDateTime = sunLighting.simulatedDate;

      // Record the time zone offset if one was set on the web scene.
      if (sunLighting.displayTimeZone != null) {
        _lightingTimeZoneOffset = Duration(
          hours: sunLighting.displayTimeZone!.hours,
          minutes: sunLighting.displayTimeZone!.minutes,
        );
      }

      _lightingHour = sunLighting.simulatedDate
          .add(_lightingTimeZoneOffset)
          .hour;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        // Section for the Sky setting controls.
        Row(
          children: [
            const Text('Sky:'),
            const Spacer(),
            ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: [_isStarsEnabled],
              onPressed: _isSunLighting
                  ? (_) => changeEnableStars(!_isStarsEnabled)
                  : null,
              children: const [
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                  child: Text('Stars'),
                ),
              ],
            ),
            // Space between buttons.
            const SizedBox(width: 8),
            ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: [_isAtmosphereEnabled],
              onPressed: (_) {
                changeEnableAtmosphere(!_isAtmosphereEnabled);
              },
              children: const [
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                  child: Text('Atmosphere'),
                ),
              ],
            ),
          ],
        ),
        const Divider(),
        // Section for the background color setting controls.
        Row(
          children: [
            const Text('Background color:'),
            const Spacer(),
            DropdownButton(
              value: _backgroundColor,
              items: _backgroundColorOptions
                  .map<DropdownMenuItem<Color>>(
                    (colorOption) => DropdownMenuItem(
                      value: colorOption.color,
                      child: Text(colorOption.name),
                    ),
                  )
                  .toList(),
              onChanged: changeBackgroundColor,
            ),
          ],
        ),
        const Divider(),
        // Section for the lighting controls.
        Column(
          children: [
            Row(
              children: [
                const Text('Lighting:'),
                const Spacer(),
                ToggleButtons(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  isSelected: [_isSunLighting, !_isSunLighting],
                  onPressed: (index) => changeLightingType(index == 0),
                  children: const [
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                      child: Text('Sun'),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                      child: Text('Virtual'),
                    ),
                  ],
                ),
                const Spacer(),
                ToggleButtons(
                  isSelected: [_isDirectShadowsEnabled],
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  onPressed: (_) =>
                      changeEnableShadows(!_isDirectShadowsEnabled),
                  children: const [
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                      child: Text('Direct Shadows'),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const Text('Hour:'),
                Expanded(
                  child: Slider(
                    value: _lightingHour.toDouble(),
                    max: 23,
                    divisions: 23,
                    label: '$_lightingHour:00',
                    onChanged: _isSunLighting ? updateLightingHour : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Function that handles a change in the stars flag.
  void changeEnableStars(bool enabled) {
    if (enabled == _isStarsEnabled) return;

    _scene.environment.areStarsEnabled = enabled;
    setState(() => _isStarsEnabled = enabled);
  }

  // Function that handles a change in the atmoshpere flag.
  void changeEnableAtmosphere(bool enabled) {
    if (enabled == _isAtmosphereEnabled) return;

    _scene.environment.isAtmosphereEnabled = enabled;
    setState(() => _isAtmosphereEnabled = enabled);
  }

  // Function that handles a change in the background color.
  void changeBackgroundColor(Color? backgroundColor) {
    final newColor = backgroundColor ?? _backgroundColorOptions.first.color;
    _scene.environment.backgroundColor = newColor;
    setState(() {
      _backgroundColor = newColor;
    });

    // Disable atmosphere and stars to see new color.
    changeEnableAtmosphere(false);
    changeEnableStars(false);
  }

  // Function that handles a change in the direct shadows flag.
  void changeEnableShadows(bool enabled) {
    if (enabled == _isDirectShadowsEnabled) return;

    _scene.environment.lighting.areDirectShadowsEnabled = enabled;
    setState(() => _isDirectShadowsEnabled = enabled);
  }

  // Function to change the scene lighting type.
  void changeLightingType(bool isSunLighting) {
    // Build the new scene lighting object.
    final SceneLighting newSceneLighting;
    if (isSunLighting) {
      newSceneLighting = SunLighting(
        simulatedDate: _lightingDateTime,
        areDirectShadowsEnabled: _isDirectShadowsEnabled,
      );
    } else {
      newSceneLighting = VirtualLighting(
        areDirectShadowsEnabled: _isDirectShadowsEnabled,
      );
    }

    // Set the new lighting object to the scene.
    _scene.environment.lighting = newSceneLighting;

    setState(() {
      // Set the lighting type button state.
      _isSunLighting = isSunLighting;

      if (_isSunLighting) {
        // Ensure the slider is showing the correct hour.
        _lightingHour = _lightingDateTime.add(_lightingTimeZoneOffset).hour;
      }
    });
  }

  // Function to handle the change in the lighting hour.
  void updateLightingHour(double newHourValue) {
    final newHourInt = newHourValue.round();
    final hourDif = newHourInt - _lightingHour;

    // Update the slider control.
    setState(() => _lightingHour = newHourInt);

    // Update the time on the lightning object.
    final hourChangeDuration = Duration(hours: hourDif);
    _lightingDateTime = _lightingDateTime.add(hourChangeDuration);
    (_scene.environment.lighting as SunLighting).simulatedDate =
        _lightingDateTime;
  }
}
