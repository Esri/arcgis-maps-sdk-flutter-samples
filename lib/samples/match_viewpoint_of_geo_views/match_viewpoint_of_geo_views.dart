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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class MatchViewpointOfGeoViews extends StatefulWidget {
  const MatchViewpointOfGeoViews({super.key});

  @override
  State<MatchViewpointOfGeoViews> createState() =>
      _MatchViewpointOfGeoViewsState();
}

class _MatchViewpointOfGeoViewsState extends State<MatchViewpointOfGeoViews>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag to indicate if the map view is currently interacting.
  bool _isMapViewInteraction = false;
  // A flag to indicate if the scene view is currently interacting.
  bool _isSceneViewInteraction = false;
  // Stream subscriptions for viewpoint changes.
  late StreamSubscription _mapViewViewpointChangedSubscription;
  late StreamSubscription _sceneViewViewpointChangedSubscription;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void dispose() {
    _mapViewViewpointChangedSubscription.cancel();
    _sceneViewViewpointChangedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            if (isPortrait)
              Column(children: getViews())
            else
              Row(children: getViews()),

            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  List<Widget> getViews() {
    return [
      // Add a map view to the widget tree and set a controller.
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => setState(() {
            _isMapViewInteraction = true;
            _isSceneViewInteraction = false;
          }),
          onDoubleTapDown: (details) => setState(() {
            _isMapViewInteraction = true;
            _isSceneViewInteraction = false;
          }),
          child: ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
        ),
      ),
      // Add a scene view to the widget tree and set a controller.
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTapDown: (details) => setState(() {
            _isMapViewInteraction = false;
            _isSceneViewInteraction = true;
          }),
          onTapDown: (details) => setState(() {
            _isMapViewInteraction = false;
            _isSceneViewInteraction = true;
          }),

          child: ArcGISSceneView(
            controllerProvider: () => _sceneViewController,
            onSceneViewReady: onSceneViewReady,
          ),
        ),
      ),
    ];
  }

  void onMapViewReady() {
    setState(() => _ready = false);
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
    _mapViewController.arcGISMap = map;

    // Listen for viewpoint changes in the map view.
    _mapViewViewpointChangedSubscription = _mapViewController.onViewpointChanged
        .listen((_) {
          if (_isMapViewInteraction) {
            final mapViewViewpoint = _mapViewController.getCurrentViewpoint(
              ViewpointType.centerAndScale,
            );
            _sceneViewController.setViewpoint(mapViewViewpoint!);
          }
        });

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onSceneViewReady() {
    setState(() => _ready = false);
    // Create a scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Listen for viewpoint changes in the scene view.
    // This will update the map view's viewpoint when the scene view changes.
    _sceneViewViewpointChangedSubscription = _sceneViewController
        .onViewpointChanged
        .listen((_) {
          if (_isSceneViewInteraction) {
            final sceneViewViewpoint = _sceneViewController.getCurrentViewpoint(
              ViewpointType.centerAndScale,
            );
            _mapViewController.setViewpoint(sceneViewViewpoint!);
          }
        });

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
