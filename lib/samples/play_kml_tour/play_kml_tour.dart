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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlayKmlTour extends StatefulWidget {
  const PlayKmlTour({super.key});

  @override
  State<PlayKmlTour> createState() => _PlayKmlTourState();
}

class _PlayKmlTourState extends State<PlayKmlTour> with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // Create a controller for playing the KML tour.
  final _tourController = KmlTourController();
  // Listen for changes to the KML tour status.
  StreamSubscription<KmlTourStatus>? _tourStatusSubscription;
  // Track the scene to restore its initial viewpoint.
  ArcGISScene? _scene;
  // Track whether the tour is currently playing.
  var _isPlaying = false;
  // Track whether the tour can be reset.
  var _canReset = false;
  // Track when the scene and tour are ready.
  var _ready = false;

  @override
  void dispose() {
    // Stop the tour and release its listeners before disposing the sample.
    _tourController.pause();
    _tourController.reset();
    _tourStatusSubscription?.cancel().ignore();
    _tourController.dispose();
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
                    onSceneViewReady: _onSceneViewReady,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Play or pause the tour according to its current status.
                          ElevatedButton.icon(
                            onPressed: _ready ? _toggleTour : null,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(_isPlaying ? 'Pause' : 'Play'),
                          ),
                          // Reset a tour that has started playing.
                          ElevatedButton.icon(
                            onPressed: _canReset ? _resetTour : null,
                            icon: const Icon(Icons.replay),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display tour instructions in a banner at the top.
            const MapBanner(
              text: 'Use the buttons to control the tour. Contains audio.',
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> _onSceneViewReady() async {
    // Create a scene with imagery and world elevation.
    final scene = ArcGISScene.withBasemapStyle(
      BasemapStyle.arcGISImageryStandard,
    );
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );
    _scene = scene;
    _sceneViewController.arcGISScene = scene;

    try {
      // Get the path to the downloaded KMZ file.
      final extra = GoRouter.of(context).state.extra;
      if (extra is! List<String> || extra.isEmpty) {
        throw Exception(
          'Offline data path not available. Download the sample data first.',
        );
      }

      // Create a KML dataset from the local KMZ file and add its layer.
      final dataset = KmlDataset(Uri.file(extra.first));
      scene.operationalLayers.add(KmlLayer(dataset));
      // Load the dataset before traversing the node hierarchy because its
      // root nodes are populated during loading.
      await dataset.load();

      // Find the first tour in the KML node hierarchy.
      final tour = _findTour(dataset.rootNodes);
      if (tour == null) {
        throw Exception('No tour was found in the KML file.');
      }

      // Listen before assigning the tour to capture its initial status event.
      _tourStatusSubscription = tour.onTourStatusChanged.listen(
        _onTourStatusChanged,
      );
      _tourController.tour = tour;
    } on Exception catch (exception) {
      // Report a failure to load or initialize the KML tour.
      showExceptionDialog('Failed to load KML tour', exception);
    }
  }

  KmlTour? _findTour(List<KmlNode> rootNodes) {
    // Search the KML hierarchy breadth-first for the first tour.
    final nodesToExplore = List<KmlNode>.of(rootNodes);
    while (nodesToExplore.isNotEmpty) {
      final node = nodesToExplore.removeAt(0);
      if (node is KmlTour) return node;
      if (node is KmlContainer) {
        nodesToExplore.addAll(node.childNodes);
      }
    }
    return null;
  }

  void _onTourStatusChanged(KmlTourStatus status) {
    // Prevent user gestures from competing with tour-driven camera movement.
    final isPlaying = status == KmlTourStatus.playing;
    _sceneViewController.interactionOptions.enabled = !isPlaying;
    if (!mounted) return;
    setState(() {
      // Mark the controls ready when the controller reports its first status.
      _ready = true;
      _isPlaying = isPlaying;
      // Enable reset only while the tour is playing or paused.
      _canReset =
          status == KmlTourStatus.playing || status == KmlTourStatus.paused;
    });

    // Return to the initial viewpoint when the tour completes.
    if (status == KmlTourStatus.completed) {
      _restoreInitialViewpoint();
    }
  }

  void _toggleTour() {
    // Pause a playing tour or play the initialized or paused tour.
    if (_isPlaying) {
      _tourController.pause();
    } else {
      _tourController.play();
    }
  }

  void _resetTour() {
    // Reset the tour and return to the scene's initial viewpoint.
    _tourController.reset();
    _restoreInitialViewpoint();
  }

  void _restoreInitialViewpoint() {
    // Restore the viewpoint captured from the KML layer during loading.
    final initialViewpoint = _scene?.initialViewpoint;
    if (initialViewpoint != null) {
      _sceneViewController.setViewpoint(initialViewpoint);
    }
  }
}
