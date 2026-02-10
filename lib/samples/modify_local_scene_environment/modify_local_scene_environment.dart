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

class ModifyLocalSceneEnvironment extends StatefulWidget {
  const ModifyLocalSceneEnvironment({super.key});

  @override
  State<ModifyLocalSceneEnvironment> createState() =>
      _ModifyLocalSceneEnvironmentState();
}

class _ModifyLocalSceneEnvironmentState
    extends State<ModifyLocalSceneEnvironment>
    with SampleStateSupport {
  // Get a controller for the ArcGISLocalSceneView
  final _localSceneViewController = ArcGISLocalSceneView.createController();

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
                  child: ArcGISLocalSceneView(
                    controllerProvider: () => _localSceneViewController,
                    onLocalSceneViewReady: onLocalSceneReady,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      const Text(
                        'Scene Environment Settings:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Spacer(),
                          const Text('Sky:'),
                          const Spacer(),
                          ToggleButtons(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            isSelected: [_isStarsEnabled],
                            onPressed: _isSunLighting
                                ? (_) => changeEnableStars(!_isStarsEnabled)
                                : null,
                            children: const [
                              Padding(
                                padding: EdgeInsetsGeometry.fromLTRB(
                                  10,
                                  0,
                                  10,
                                  0,
                                ),
                                child: Text('Stars'),
                              ),
                            ],
                          ),
                          // Space between buttons.
                          const SizedBox(width: 8),
                          ToggleButtons(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            isSelected: [_isAtmosphereEnabled],
                            onPressed: (_) {
                              changeEnableAtmosphere(!_isAtmosphereEnabled);
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsetsGeometry.fromLTRB(
                                  10,
                                  0,
                                  10,
                                  0,
                                ),
                                child: Text('Atmosphere'),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Spacer(),
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
                          const Spacer(),
                        ],
                      ),
                      const Divider(),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              const Text('Lighting:'),
                              const Spacer(),
                              ToggleButtons(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                isSelected: [_isSunLighting, !_isSunLighting],
                                onPressed: (index) =>
                                    changeLightingType(index == 0),
                                children: const [
                                  Padding(
                                    padding: EdgeInsetsGeometry.fromLTRB(
                                      10,
                                      0,
                                      10,
                                      0,
                                    ),
                                    child: Text('Sun'),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsGeometry.fromLTRB(
                                      10,
                                      0,
                                      10,
                                      0,
                                    ),
                                    child: Text('Virtual'),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              ToggleButtons(
                                isSelected: [_isDirectShadowsEnabled],
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                onPressed: (_) => changeEnableShadows(
                                  !_isDirectShadowsEnabled,
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsetsGeometry.fromLTRB(
                                      10,
                                      0,
                                      10,
                                      0,
                                    ),
                                    child: Text('Direct Shadows'),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                          Slider(
                            value: _lightingHour.toDouble(),
                            max: 23,
                            divisions: 23,
                            label: '$_lightingHour:00',
                            onChanged: _isSunLighting
                                ? updateLightingHour
                                : null,
                          ),
                        ],
                      ),
                    ],
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

  Future<void> onLocalSceneReady() async {
    // Create and load the web scene
    final websceneUri = Uri.parse(
      'https://maps.arcgis.com/home/item.html?id=fcebd77958634ac3874bbc0e6b0677a4',
    ); // Local scene with 3D trees and buildings
    final scene = ArcGISScene.withUri(websceneUri)!;
    await scene.load();

    // Set the scene on the local scene view.
    _localSceneViewController.arcGISScene = scene;

    // Set the state variables based on the actual scene environment.
    setState(() {
      _isAtmosphereEnabled = scene.environment.isAtmosphereEnabled;
      _isStarsEnabled = scene.environment.areStarsEnabled;
      _isDirectShadowsEnabled =
          scene.environment.lighting.areDirectShadowsEnabled;
      _backgroundColor = scene.environment.backgroundColor;

      if (scene.environment.lighting is SunLighting) {
        // Record the simulated time from the web scene.
        final sunLighting = scene.environment.lighting as SunLighting;
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

      // The view is ready for interaction.
      _ready = true;
    });
  }

  /// Function that handles a change in the stars flag.
  void changeEnableStars(bool enabled) {
    if (enabled == _isStarsEnabled) return;

    _localSceneViewController.arcGISScene!.environment.areStarsEnabled =
        enabled;
    setState(() => _isStarsEnabled = enabled);
  }

  /// Function that handles a change in the atmoshpere flag.
  void changeEnableAtmosphere(bool enabled) {
    if (enabled == _isAtmosphereEnabled) return;

    _localSceneViewController.arcGISScene!.environment.isAtmosphereEnabled =
        enabled;
    setState(() => _isAtmosphereEnabled = enabled);
  }

  /// Function that handles a change in the background color.
  void changeBackgroundColor(Color? backgroundColor) {
    final newColor = backgroundColor ?? _backgroundColorOptions.first.color;
    _localSceneViewController.arcGISScene!.environment.backgroundColor =
        newColor;
    setState(() {
      _backgroundColor = newColor;
    });

    // Disable atmosphere and stars to see new color.
    changeEnableAtmosphere(false);
    changeEnableStars(false);
  }

  /// Function that handles a change in the direct shadows flag.
  void changeEnableShadows(bool enabled) {
    if (enabled == _isDirectShadowsEnabled) return;

    _localSceneViewController
            .arcGISScene!
            .environment
            .lighting
            .areDirectShadowsEnabled =
        enabled;
    setState(() => _isDirectShadowsEnabled = enabled);
  }

  /// Function to change the scene lighting type.
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
    _localSceneViewController.arcGISScene?.environment.lighting =
        newSceneLighting;

    setState(() {
      // Set the lighting type button state.
      _isSunLighting = isSunLighting;

      if (_isSunLighting) {
        // Ensure the slider is showing the correct hour.
        _lightingHour = _lightingDateTime.add(_lightingTimeZoneOffset).hour;
      }
    });
  }

  /// Function to handle the change in the lighting hour.
  void updateLightingHour(double newHourValue) {
    if (!_isSunLighting) return;

    final newHourInt = newHourValue.round();

    final hourDif = newHourInt - _lightingHour;
    setState(() => _lightingHour = newHourInt);

    final hourChangeDuration = Duration(hours: hourDif);
    _lightingDateTime = _lightingDateTime.add(hourChangeDuration);

    (_localSceneViewController.arcGISScene!.environment.lighting as SunLighting)
            .simulatedDate =
        _lightingDateTime;
  }
}
