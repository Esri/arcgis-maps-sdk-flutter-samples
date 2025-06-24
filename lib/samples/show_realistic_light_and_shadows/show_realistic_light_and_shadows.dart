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
import 'package:intl/intl.dart';

class ShowRealisticLightAndShadows extends StatefulWidget {
  const ShowRealisticLightAndShadows({super.key});

  @override
  State<ShowRealisticLightAndShadows> createState() =>
      _ShowRealisticLightAndShadowsState();
}

class _ShowRealisticLightAndShadowsState
    extends State<ShowRealisticLightAndShadows>
    with SampleStateSupport {
  // Create a controller for the Scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the Scene view is ready and controls can be used.
  var _ready = false;
  final _lightingChoices = {
    'Light and Shadows': LightingMode.lightAndShadows,
    'Light': LightingMode.light,
    'No Light': LightingMode.noLight,
  };
  String _selectedLighting = 'Light and Shadows';
  double _timeValue = 8.5;
  DateTime _sunTime = DateTime(2018, 8, 10, 8, 30);
  final _dateFormat = DateFormat('MMMM dd, yyyy, hh:mm a');

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
              spacing: 5,
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
                    // dropdown for lighting choices
                    DropdownButton(
                      value: _selectedLighting,
                      items: _lightingChoices.keys
                          .map(
                            (label) => DropdownMenuItem(
                              value: label,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLighting = value;
                            // Update the sun lighting based on the selected choice.
                            _sceneViewController.sunLighting =
                                _lightingChoices[value]!;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Slider to change the sun time
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Slider(
                          max: 24,
                          divisions: 24 * 4, // 15-minute increments
                          value: _timeValue,
                          label: '${_timeValue.toStringAsFixed(2)} h',
                          onChanged: (value) {
                            setState(() {
                              _timeValue = value;
                              // Update the sun time based on the slider value.
                              setSunTimeFromValue(_timeValue);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Slider to change the sun time from 0 to 24 hours.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        // Format the sun time as MM dd, yyyy, hh:mm a
                        // ignore: unnecessary_string_interpolations
                        '${_dateFormat.format(_sunTime)}',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
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
    // Create a Scene with a topographic baseScene style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _sceneViewController.arcGISScene = scene;
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);
    // Create a SceneLayer with the provided URL.
    final sceneLayer = ArcGISSceneLayer.withUri(
      Uri.parse(
        'https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_BuildingShells/SceneServer/layers/0',
      ),
    );
    // Add the SceneLayer to the Scene.
    scene.operationalLayers.add(sceneLayer);
    // Set the viewpoint to the extent of the SceneLayer.
    final camera = Camera.withLookAtPoint(
      lookAtPoint: ArcGISPoint(
        x: -122.68711400735646,
        y: 45.539231741174206,
        z: 334.48350897897035,
      ),
      distance: 541.0002111233771,
      heading: 162.58767335295363,
      pitch: 68.44381635828522,
      roll: 1.0259216929482844e-14,
    );
    _sceneViewController.setViewpointCamera(camera);

    // Set the atmosphere effect to realistic.
    _sceneViewController.atmosphereEffect = AtmosphereEffect.realistic;
    // Set the time of day to noon.
    setSunTimeFromValue(8.5);
    // Enable realistic lighting and shadows.
    _sceneViewController.sunLighting = LightingMode.lightAndShadows;
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Update the sun time in the SceneViewController.
  void setSunTimeFromValue(double value) {
    final remainder = value % 1;
    final hours = (value - remainder).toInt();
    final minutes = (remainder * 60).toInt();
    final dateTime = DateTime(2018, 8, 10, hours, minutes);

    _sceneViewController.sunTime = dateTime;
    setState(() => _sunTime = dateTime);
  }
}
