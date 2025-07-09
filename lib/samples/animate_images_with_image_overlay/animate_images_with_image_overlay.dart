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
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

class AnimateImagesWithImageOverlay extends StatefulWidget {
  const AnimateImagesWithImageOverlay({super.key});

  @override
  State<AnimateImagesWithImageOverlay> createState() =>
      _AnimateImagesWithImageOverlayState();
}

class _AnimateImagesWithImageOverlayState
    extends State<AnimateImagesWithImageOverlay>
    with TickerProviderStateMixin, SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag to toggle the start/stop of the image animation.
  var _started = false;
  // Define the animated speeds available in the dropdown button.
  final _animatedSpeeds = ['Fast', 'Medium', 'Slow'];
  // The initial selected animated speed.
  var _selectedAnimatedSpeed = 'Slow';
  // The speed of the image frame animation in milliseconds.
  var _imageFrameSpeed = 0;
  // The last frame time in milliseconds to control the animation speed.
  var _lastFrameTime = 0;
  // The initial opacity of the image overlay.
  var _opacity = 0.5;
  // Create an ImageOverlay to display the animated images.
  final _imageOverlay = ImageOverlay();
  // A list to hold the image frames for the animation.
  var _imageFrames = <ImageFrame>[];
  // A string to display the download progress.
  var _downloadProgress = '';
  // An integer to track the current image frame index.
  var _imageFrameIndex = 0;
  // A timer to control and change the image frame periodically.
  Ticker? _ticker;
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    _imageFrameSpeed = getAnimatedSpeed(_selectedAnimatedSpeed);
    super.initState();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _imageFrames.clear();
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
              spacing: 10,
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
                    // A button to start/stop the animation.
                    ElevatedButton(
                      onPressed: () {
                        if (!_started) {
                          startTicker();
                        } else {
                          stopTicker();
                        }
                      },
                      child: _started
                          ? const Text('Stop')
                          : const Text('Start'),
                    ),
                    // A dropdown button to select the animated speed.
                    DropdownButton<String>(
                      value: _selectedAnimatedSpeed,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAnimatedSpeed = value;
                            _imageFrameSpeed = getAnimatedSpeed(value);
                          });
                        }
                      },
                      items: _animatedSpeeds.map((String speed) {
                        return DropdownMenuItem<String>(
                          value: speed,
                          child: Text(
                            speed,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // A Slider to control opacity of the image overlay.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    const SizedBox(width: 20),
                    Text('Opacity: ${(_opacity * 100).toStringAsFixed(0)}%'),
                    Expanded(
                      child: Slider(
                        value: _opacity * 100,
                        onChanged: (value) {
                          setState(() {
                            _opacity = value / 100;
                            // Set the opacity of the image overlay.
                            _imageOverlay.opacity = _opacity;
                          });
                        },
                        max: 100,
                        divisions: 100 * 2,
                        label: '$_opacity Opacity',
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready, text: _downloadProgress),
          ],
        ),
      ),
    );
  }

  int getAnimatedSpeed(String selectedSpeed) {
    // On iOS the FPS is 120, on Android it is 60.
    // The animation speed is reduced to one-quarter on iOS. 
    final factor = Platform.isIOS ? 4 : 1;
    // Returns the speed of the animation based on the selected speed.
    // Usually a frame changes every 15~17 milliseconds.
    return switch (selectedSpeed) {
      'Fast' => 17 * factor,
      'Medium' => 34 * factor,
      'Slow' => 68 * factor,
      _ => 68 * factor,
    };
  }

  void stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    setState(() => _started = false);
  }

  void startTicker() {
    _ticker?.dispose();
    _lastFrameTime = 0;
    // create a ticker to control the image frame animation.
    _ticker = createTicker(_onTicker);
    _ticker!.start();
    setState(() => _started = true);
  }

  // Callback function for the ticker to change the image frame.
  void _onTicker(Duration elapsed) {
    final delta = elapsed.inMilliseconds - _lastFrameTime;
    if (delta >= _imageFrameSpeed) {
      _imageFrameIndex = (_imageFrameIndex + 1) % _imageFrames.length;
      setImageFrame(_imageFrameIndex);
      _lastFrameTime = elapsed.inMilliseconds;
    }
  }

  Future<void> onSceneViewReady() async {
    // Create a Scene with a topographic baseScene style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISDarkGray);
    _sceneViewController.arcGISScene = scene;
    // Add a elevation source for the base surface of the scene.
    final elevationSource = ArcGISTiledElevationSource.withUri(
      Uri.parse(
        'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
      ),
    );
    scene.baseSurface.elevationSources.add(elevationSource);

    // Set the initial camera position and orientation.
    // The camera is positioned over the Pacific South West region.
    final camera = Camera.withLocation(
      location: ArcGISPoint(
        x: -116.621,
        y: 24.7773,
        z: 856977,
        spatialReference: SpatialReference.wgs84,
      ),
      heading: 353.994,
      pitch: 48.5495,
      roll: 0,
    );
    _sceneViewController.setViewpointCamera(camera);
    // Set the initial opacity of the image overlay.
    _imageOverlay.opacity = _opacity;
    // Set the image overlay to the scene view.
    _sceneViewController.imageOverlays.add(_imageOverlay);

    // Initialize the image frames and set them to the image overlay.
    await initImageFrames();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> initImageFrames() async {
    final appDir = await getApplicationDocumentsDirectory();
    // Define the path for the sample data zip file and the directory to extract it.
    // The sample data contains images of the Pacific South West region.
    final imageFile = File('${appDir.absolute.path}/PacificSouthWest.zip');
    final directory = Directory.fromUri(
      Uri.parse('${appDir.absolute.path}/PacificSouthWest/PacificSouthWest'),
    );

    // Download the sample data if it does not exist.
    if (!imageFile.existsSync()) {
      await downloadSampleDataWithProgress(
        itemId: '9465e8c02b294c69bdb42de056a23ab1',
        destinationFile: imageFile,
        onProgress: (progress) {
          setState(
            () => _downloadProgress =
                'Downloading images: ${(progress * 100).toStringAsFixed(0)}%',
          );
        },
      );
      await extractZipArchive(imageFile);
    }
    // Get a list of all PNG image files in the extracted directory.
    final imageList = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.png'))
        .toList();
    // Calculate the extent for the image frames based on a known point and size.
    final pointForImageFrame = ArcGISPoint(
      x: -120.0724273439448,
      y: 35.131016955536694,
      spatialReference: SpatialReference.wgs84,
    );
    final imageEnvelope = Envelope.fromCenter(
      pointForImageFrame,
      width: 15.09589635986124,
      height: -14.3770441522488,
    );
    // Create a list of ImageFrame objects from the image files and the extent.
    _imageFrames = imageList.map((file) {
      return ImageFrame.withImageEnvelope(
        image: ArcGISImage.fromFile(file.uri)!,
        extent: imageEnvelope,
      );
    }).toList();
    // show the first image frame in the image overlay.
    setImageFrame(0);
  }

  void setImageFrame(int index) {
    // Set the image frame to the image overlay.
    _imageOverlay.imageFrame = _imageFrames[index];
  }
}
