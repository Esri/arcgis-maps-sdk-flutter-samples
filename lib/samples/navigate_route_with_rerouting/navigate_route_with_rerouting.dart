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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

class NavigateRouteWithRerouting extends StatefulWidget {
  const NavigateRouteWithRerouting({super.key});

  @override
  State<NavigateRouteWithRerouting> createState() =>
      _NavigateRouteWithReroutingState();
}

class _NavigateRouteWithReroutingState extends State<NavigateRouteWithRerouting>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A text-to-speech plugin to provide voice guidance.
  late FlutterTts _flutterTts;

  // A RouteTask to solve the route.
  late RouteTask _routeTask;

  // A RouteTracker to track the route.
  late RouteTracker _routeTracker;

  // A RouteResult to store the route result.
  late RouteResult _routeResult;

  // Rerouting parameters to enable rerouting.
  late ReroutingParameters _reroutingParameters;

  // The path to the downloaded geodatabase.
  late String _geodatabasePath;

  // A SimulatedLocationDataSource to simulate the sequence of location updates.
  SimulatedLocationDataSource? _simulatedLocationDataSource;

  // Graphics to show progress on the route.
  late Graphic _remainingRouteGraphic;
  late Graphic _routeTraveledGraphic;

  // A PolylineBuilder to store the traversed route.
  var _traversedRouteBuilder = PolylineBuilder(
    spatialReference: SpatialReference.wgs84,
  );

  // San Diego Convention Center.
  final _startPoint = ArcGISPoint(
    x: -117.160386727,
    y: 32.706608,
    spatialReference: SpatialReference.wgs84,
  );

  // RH Fleet Aerospace Museum.
  final _endPoint = ArcGISPoint(
    x: -117.146679,
    y: 32.730351,
    spatialReference: SpatialReference.wgs84,
  );

  // Indicate whether the route is being navigated.
  var _isNavigating = false;
  var _resetToNavigationMode = false;
  var _reset = false;
  var _setupDataAndInitNavigation = false;

  // Variables to show the remaining distance, time, and next direction.
  var _routeStatus = '';
  var _remainingDistance = '';
  var _remainingTime = '';
  var _nextDirection = '';

  // Stream subscriptions tracking various events.
  StreamSubscription<VoiceGuidance>? _voiceGuidanceSubscription;
  StreamSubscription<TrackingStatus>? _trackingStatusSubscription;
  StreamSubscription<void>? _rerouteStartedSubscription;
  StreamSubscription<void>? _rerouteCompletedSubscription;
  StreamSubscription<LocationDisplayAutoPanMode>?
  _autoPanModeChangedSubscription;
  StreamSubscription<LoadStatus>? _mapLoadingSubscription;

  @override
  void initState() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    // Store the path of the downloaded geodatabase.
    _geodatabasePath = listPaths[0];
    // Create a simulated location data source using the downloaded JSON file.
    _simulatedLocationDataSource = getLocationDataSource(listPaths[1]);

    super.initState();
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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      // Add a button to reset navigation if it has started.
                      child: IconButton(
                        onPressed: _reset ? reset : null,
                        color: Colors.white,
                        icon: const Icon(Icons.restore),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      // Add a button to start/stop navigation.
                      child: IconButton(
                        onPressed: _setupDataAndInitNavigation
                            ? null
                            : (_isNavigating ? stop : start),
                        color: Colors.white,
                        icon: _isNavigating
                            ? const Icon(Icons.stop)
                            : const Icon(Icons.play_arrow),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      // Add a button to reset location display to navigation mode.
                      child: IconButton(
                        onPressed: _resetToNavigationMode
                            ? resetToNavigationMode
                            : null,
                        color: Colors.white,
                        icon: const Icon(Icons.navigation),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Route status: $_routeStatus',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Distance remaining: $_remainingDistance',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Time remaining: $_remainingTime',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Next direction: $_nextDirection',
                          style: Theme.of(context).textTheme.labelMedium,
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a progress indicator while the navigation data is loading.
            Visibility(
              visible: _setupDataAndInitNavigation,
              child: const Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(),
                      Text('Initializing navigation...'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _simulatedLocationDataSource?.stop();
    _voiceGuidanceSubscription?.cancel();
    _trackingStatusSubscription?.cancel();
    _rerouteStartedSubscription?.cancel();
    _rerouteCompletedSubscription?.cancel();

    _autoPanModeChangedSubscription?.cancel();
    _mapLoadingSubscription?.cancel();
    super.dispose();
  }

  // Set up the map with a navigation basemap style.
  Future<void> onMapViewReady() async {
    // Create a map with a navigation basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
    _mapViewController.arcGISMap = map;

    // Once the map finishes loading, initialize navigation.
    _mapLoadingSubscription = map.onLoadStatusChanged.listen((
      loadStatus,
    ) async {
      if (loadStatus == LoadStatus.loaded) {
        setState(() => _setupDataAndInitNavigation = true);
        await initRouteTask();
        setState(() => _setupDataAndInitNavigation = false);
      }
    });

    // Initialize FlutterTts.
    await initFlutterTts();

    setState(() => _ready = true);
  }

  // Initialize the FlutterTts plugin.
  Future<void> initFlutterTts() async {
    // Detect the user's locale.
    final locale = Localizations.localeOf(context).toLanguageTag();

    _flutterTts = FlutterTts();

    // Set the language based on the user's locale.
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1);
    await _flutterTts.setPitch(1.3);

    // Perform iOS-specific initialization.
    final isIOS = !kIsWeb && Platform.isIOS;
    if (isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
  }

  // Initialize the route task, route parameters, and route result.
  Future<void> initRouteTask() async {
    // Create a route task.
    _routeTask = RouteTask.withGeodatabase(
      pathToDatabase: Uri.file(_geodatabasePath),
      networkName: 'Streets_ND',
    );

    // Create route parameters.
    final routeParameters = await _routeTask.createDefaultParameters()
      ..returnDirections = true
      ..returnStops = true
      ..returnRoutes = true
      ..outputSpatialReference = SpatialReference.wgs84;

    // Sets the start and destination stops for the route.
    routeParameters.setStops([
      Stop(_startPoint)..name = 'San Diego Convention Center',
      Stop(_endPoint)..name = 'RH Fleet Aerospace Museum',
    ]);

    // Solve the route and store the result.
    _routeResult = await _routeTask.solveRoute(routeParameters);

    // Initializes and adds graphics to the map view to visually represent the route,
    // including the remaining route, traveled route, and start/end points.
    initRouteGraphics();

    // Create Rerouting parameters with the route task and parameters.
    _reroutingParameters =
        ReroutingParameters.create(
            routeTask: _routeTask,
            routeParameters: routeParameters,
          )!
          ..strategy = ReroutingStrategy.toNextWaypoint
          ..visitFirstStopOnStart = false;

    // Initialize the route tracker, location display, and route graphics.
    await initNavigation();
  }

  // Initialize the route tracker, location display, and route graphics.
  Future<void> initNavigation() async {
    // Create the route tracker with rerouting enabled.
    _routeTracker = RouteTracker.create(
      routeResult: _routeResult,
      routeIndex: 0,
      skipCoincidentStops: true,
    )!;

    // Enable rerouting on the route tracker.
    if (_routeTask.getRouteTaskInfo().supportsRerouting) {
      await _routeTracker.enableRerouting(parameters: _reroutingParameters);
    } else {
      showMessageDialog('Rerouting is not supported.');
    }

    // Create a route tracker location data source to snap the location display to the route.
    final routeTrackerLocationDataSource = RouteTrackerLocationDataSource(
      routeTracker: _routeTracker,
      locationDataSource: _simulatedLocationDataSource,
    );
    // Set the location data source.
    _mapViewController.locationDisplay.dataSource =
        routeTrackerLocationDataSource;
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;
    _autoPanModeChangedSubscription = _mapViewController
        .locationDisplay
        .onAutoPanModeChanged
        .listen((event) {
          if (event != LocationDisplayAutoPanMode.navigation) {
            setState(() => _resetToNavigationMode = true);
          } else {
            setState(() => _resetToNavigationMode = false);
          }
        });

    // Update the remaining route graphic and center the map view on the route.
    await zoomToRoute();

    // Set the route tracker locale.
    _routeTracker.voiceGuidanceUnitSystem =
        const Locale.fromSubtags().languageCode == 'en'
        ? UnitSystem.imperial
        : UnitSystem.metric;

    // Listen for voice guidance and tracking status changes.
    _voiceGuidanceSubscription = _routeTracker.onNewVoiceGuidance.listen(
      updateGuidance,
    );
    _trackingStatusSubscription = _routeTracker.onTrackingStatusChanged.listen(
      updateProgress,
    );
    _rerouteStartedSubscription = _routeTracker.onRerouteStarted.listen((_) {
      _flutterTts.speak('Rerouting');
      setState(() => _routeStatus = 'Rerouting');
    });
    _rerouteCompletedSubscription = _routeTracker.onRerouteCompleted.listen((
      _,
    ) {
      setState(() => _routeStatus = 'Reroute completed');
    });
  }

  // Speak the voice guidance.
  void updateGuidance(VoiceGuidance voiceGuidance) {
    final nextDirection = voiceGuidance.text;
    if (nextDirection.isEmpty) return;
    _routeTracker.setSpeechEngineReady(() => false);
    _flutterTts.speak(nextDirection).then((value) {
      _routeTracker.setSpeechEngineReady(() => true);
    });
  }

  // Listen for tracking status changes and update the route status.
  Future<void> updateProgress(TrackingStatus status) async {
    // Update the route graphics.
    _remainingRouteGraphic.geometry = status.routeProgress.remainingGeometry;

    final currentPosition =
        _mapViewController.locationDisplay.location?.position;
    if (currentPosition != null) {
      _traversedRouteBuilder.addPoint(currentPosition);
      _routeTraveledGraphic.geometry = _traversedRouteBuilder.toGeometry();
    }

    // Update the status message.
    switch (status.destinationStatus) {
      case DestinationStatus.approaching:
      case DestinationStatus.notReached:
        // Format the route's remaining distance and time.
        final distanceRemainingText =
            status.routeProgress.remainingDistance.displayText;
        final displayUnit = status
            .routeProgress
            .remainingDistance
            .displayTextUnits
            .abbreviation;
        final remainingTimeInSeconds = status.routeProgress.remainingTime * 60;
        final timeRemainingText = formatDuration(
          remainingTimeInSeconds.toInt(),
        );
        // Get the next direction from the route's direction maneuvers.
        var nextDirection = '';
        final directionManeuvers =
            status.routeResult.routes.first.directionManeuvers;
        final nextManeuverIndex = status.currentManeuverIndex + 1;
        if (nextManeuverIndex < directionManeuvers.length) {
          nextDirection = directionManeuvers[nextManeuverIndex].directionText;
        }

        setState(() {
          _routeStatus = '${status.destinationStatus}';
          _remainingDistance = '$distanceRemainingText $displayUnit';
          _remainingTime = timeRemainingText;
          _nextDirection = nextDirection;
        });

      case DestinationStatus.reached:
        if (status.remainingDestinationCount > 1) {
          setState(() {
            _routeStatus = 'Intermediate stop reached, continue to next stop.';
          });
          await _routeTracker.switchToNextDestination();
        } else {
          await stop();
          await reset();
          setState(() {
            _routeStatus = 'Destination reached.';
          });
        }
    }
  }

  // Zoom to the route.
  Future<void> zoomToRoute() async {
    final routeLine = _routeResult.routes.first.routeGeometry;
    _remainingRouteGraphic.geometry = routeLine;
    await _mapViewController.setViewpointCenter(
      routeLine!.extent.center,
      scale: 25000,
    );
    await _mapViewController.setViewpointRotation(angleDegrees: 0);
  }

  // Start the navigation.
  Future<void> start() async {
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;
    await _mapViewController.locationDisplay.dataSource.start();
    setState(() {
      _isNavigating = true;
      _reset = true;
    });
  }

  // Reset the LocationDisplay to the navigation mode.
  void resetToNavigationMode() {
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;
  }

  // Stop the navigation.
  Future<void> stop() async {
    await _flutterTts.stop();
    // Stop the location display.
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.off;
    await _mapViewController.locationDisplay.dataSource.stop();
    setState(() {
      _isNavigating = false;
      _resetToNavigationMode = false;
    });
  }

  // Reset the navigation to begin again.
  Future<void> reset() async {
    await stop();
    _traversedRouteBuilder = PolylineBuilder(
      spatialReference: SpatialReference.wgs84,
    );
    setState(() {
      _routeStatus = '';
      _remainingDistance = '';
      _remainingTime = '';
      _nextDirection = '';
      _reset = false;
    });
    _simulatedLocationDataSource!.currentLocationIndex = 0;

    await initNavigation();
    _routeTraveledGraphic.geometry = null;
    _remainingRouteGraphic.geometry = _routeResult.routes.first.routeGeometry;
  }

  // Create a simulated location data source.
  SimulatedLocationDataSource getLocationDataSource(String jsonPath) {
    // Load the route point JSON file.
    final jsonString = File(jsonPath).readAsStringSync();
    final routeLine = Geometry.fromJsonString(jsonString) as Polyline;

    final simulatedLocationDataSource = SimulatedLocationDataSource()
      ..setLocationsWithPolyline(
        routeLine,
        simulationParameters: SimulationParameters(
          startTime: DateTime.now(),
          horizontalAccuracy: 5,
          verticalAccuracy: 5,
        ),
      );
    return simulatedLocationDataSource;
  }

  // Set up the route graphics.
  void initRouteGraphics() {
    _mapViewController.graphicsOverlays.clear();
    _mapViewController.graphicsOverlays.add(GraphicsOverlay());

    _remainingRouteGraphic = Graphic(
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dash,
        color: Colors.purple,
        width: 5,
      ),
    );

    _routeTraveledGraphic = Graphic(
      symbol: SimpleLineSymbol(color: Colors.blue, width: 3),
    );

    // Create symbols to use for the start and end stops of the route.
    final routeStartCircleSymbol = SimpleMarkerSymbol(
      color: Colors.blue,
      size: 15,
    );
    final routeEndCircleSymbol = SimpleMarkerSymbol(
      color: Colors.blue,
      size: 15,
    );
    final routeStartNumberSymbol = TextSymbol(
      text: 'A',
      color: Colors.white,
      size: 10,
    );
    final routeEndNumberSymbol = TextSymbol(
      text: 'B',
      color: Colors.white,
      size: 10,
    );

    _mapViewController.graphicsOverlays.first.graphics.addAll([
      _remainingRouteGraphic,
      _routeTraveledGraphic,
      Graphic(geometry: _startPoint, symbol: routeStartCircleSymbol)
        ..zIndex = 100,
      Graphic(geometry: _endPoint, symbol: routeEndCircleSymbol)..zIndex = 100,
      Graphic(geometry: _startPoint, symbol: routeStartNumberSymbol)
        ..zIndex = 100,
      Graphic(geometry: _endPoint, symbol: routeEndNumberSymbol)..zIndex = 100,
    ]);
  }
}

String formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$secs';
}
