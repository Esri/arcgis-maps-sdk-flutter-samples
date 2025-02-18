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
import 'package:flutter_tts/flutter_tts.dart';

class NavigateRoute extends StatefulWidget {
  const NavigateRoute({super.key});

  @override
  State<NavigateRoute> createState() => _NavigateRouteState();
}

class _NavigateRouteState extends State<NavigateRoute> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Variables for tracking the navigation route.
  late RouteTracker _routeTracker;
  late RouteResult _routeResult;
  late ArcGISRoute _route;

  // List of driving directions for the route.
  final _directionsList = <DirectionManeuver>[];

  // Third-party plugin for text-to-speech.
  final _flutterTts = FlutterTts();

  // Create a simulated location data source from the route geometry.
  final _simulatedLocationDataSource = SimulatedLocationDataSource();

  // Graphics to show progress along the route.
  late Graphic _routeAheadGraphic;
  late Graphic _routeTravelledGraphic;

  // GraphicsOverlay for route graphics
  final _routeGraphicsOverlay = GraphicsOverlay();

  // A flag to indicate if the destination is reached.
  var _destinationReached = false;

  // ValueNotifier for status text.
  final _statusTextNotifier = ValueNotifier('Directions are shown here.');

  // Track Speech Engine Status.
  var _speechEngineReady = true;

  // San Diego Convention Center.
  final _conventionCenter = ArcGISPoint(
    x: -117.160386727,
    y: 32.706608,
    spatialReference: SpatialReference.wgs84,
  );

  // USS San Diego Memorial.
  final _memorial = ArcGISPoint(
    x: -117.173034,
    y: 32.712327,
    spatialReference: SpatialReference.wgs84,
  );

  // RH Fleet Aerospace Museum.
  final _aerospaceMuseum = ArcGISPoint(
    x: -117.147230,
    y: 32.730467,
    spatialReference: SpatialReference.wgs84,
  );

  // Feature service URI for routing in San Diego.
  final _routingUri = Uri.parse(
    'https://sampleserver7.arcgisonline.com/server/rest/services/NetworkAnalysis/SanDiego/NAServer/Route',
  );

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1);
  }

  @override
  void dispose() {
    _simulatedLocationDataSource.stop();
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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to start navigation.
                    ElevatedButton(
                      onPressed: _destinationReached ? null : toggleRouting,
                      child: Text(
                        _mapViewController.locationDisplay.started
                            ? 'Stop Routing'
                            : 'Start Routing',
                      ),
                    ),
                    // A button to recenter the map.
                    ElevatedButton(
                      onPressed: recenter,
                      child: const Text('Recenter'),
                    ),
                    // A button to reset navigation.
                    ElevatedButton(
                      onPressed: resetNavigation,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a banner with the current status at the top.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _statusTextNotifier,
                          builder: (context, statusText, child) {
                            return Text(
                              statusText,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium,
                            );
                          },
                        ),
                      ),
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

  Future<void> onMapViewReady() async {
    // Create a map with a navigation basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
    _mapViewController.arcGISMap = map;

    // Add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_routeGraphicsOverlay);

    // Solve the route.
    await solveRoute();

    // Set the initial viewpoint to encompass the route geometry.
    setInitialViewpoint();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void setInitialViewpoint() {
    // Set the initial viewpoint to encompass the route geometry.
    final routeGeometry = _route.routeGeometry;
    if (routeGeometry != null) {
      final viewpoint = Viewpoint.fromTargetExtent(routeGeometry);
      _mapViewController.setViewpoint(viewpoint);
    }
  }

  Future<void> solveRoute() async {
    // Create a route with the routing URI.
    final routeTask = RouteTask.withUri(_routingUri);

    // Create default parameters for the route task.
    final parameters = await _createRouteParameters(routeTask);
    await _solveRouteAndSetGraphics(routeTask, parameters);
  }

  Future<RouteParameters> _createRouteParameters(RouteTask routeTask) async {
    // Create default parameters for the route task.
    final parameters = await routeTask.createDefaultParameters();

    // Set stops for the route.
    parameters.setStops([
      Stop(_conventionCenter),
      Stop(_memorial),
      Stop(_aerospaceMuseum),
    ]);

    // Configure the parameters.
    parameters.returnDirections = true;
    parameters.returnStops = true;
    parameters.returnRoutes = true;
    parameters.outputSpatialReference = SpatialReference.wgs84;

    return parameters;
  }

  Future<void> _solveRouteAndSetGraphics(
    RouteTask routeTask,
    RouteParameters parameters,
  ) async {
    // Solve the route and get the result.
    _routeResult = await routeTask.solveRoute(parameters);
    _route = _routeResult.routes.first;
    _directionsList.addAll(_route.directionManeuvers);

    // Create graphics for the route ahead and traveled.
    _routeAheadGraphic = Graphic(
      geometry: _route.routeGeometry,
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dash,
        color: Colors.purple,
        width: 5,
      ),
    );

    _routeTravelledGraphic = Graphic(
      symbol: SimpleLineSymbol(
        color: Colors.blue,
        width: 3,
      ),
    );

    // Add the route graphics to the overlay.
    _routeGraphicsOverlay.graphics.add(_routeAheadGraphic);
    _routeGraphicsOverlay.graphics.add(_routeTravelledGraphic);
  }

  Future<void> toggleRouting() async {
    setState(() => _ready = false);

    if (_mapViewController.locationDisplay.started) {
      _mapViewController.locationDisplay.stop();
    } else {
      await _initializeSimulatedLocationDataSource();
      await _createAndConfigureRouteTracker();
      await _startLocationDisplay();
    }
    setState(() => _ready = true);
  }

  Future<void> _initializeSimulatedLocationDataSource() async {
    // Set locations with polyline for the simulated location data source.
    _simulatedLocationDataSource.setLocationsWithPolyline(
      _route.routeGeometry!,
      simulationParameters: SimulationParameters(
        startTime: DateTime.now(),
      ),
    );
  }

  Future<void> _createAndConfigureRouteTracker() async {
    // Create a route tracker with the route result.
    _routeTracker = RouteTracker.create(
      routeResult: _routeResult,
      routeIndex: 0,
      skipCoincidentStops: true,
    )!;
    _routeTracker.voiceGuidanceUnitSystem = UnitSystem.imperial;

    // Set the speech engine ready callback.
    _routeTracker.setSpeechEngineReady(() => _speechEngineReady);

    // Listen for tracking status updates.
    _routeTracker.onTrackingStatusChanged.listen((status) async {
      _updateRouteGraphics(status);
      _updateStatusText(status);

      // Handle destination status changes.
      if (status.destinationStatus == DestinationStatus.reached) {
        if (status.remainingDestinationCount > 1) {
          await _routeTracker.switchToNextDestination();
        } else {
          await _simulatedLocationDataSource.stop();
          setState(() => _destinationReached = true);
        }
      }
    });

    // Listen for voice guidance updates.
    _routeTracker.onNewVoiceGuidance.listen((voiceGuidance) async {
      _speechEngineReady = false;
      await _flutterTts.speak(voiceGuidance.text);
      _speechEngineReady = true;
    });
  }

  Future<void> _startLocationDisplay() async {
    // Start the simulated location data source.
    await _simulatedLocationDataSource.start();

    // Create a RouteTrackerLocationDataSource.
    final routeTrackerLocationSource = RouteTrackerLocationDataSource(
      routeTracker: _routeTracker,
      locationDataSource: _simulatedLocationDataSource,
    );

    // Set the location display data source.
    _mapViewController.locationDisplay.dataSource = routeTrackerLocationSource;

    // Set the auto-pan mode for the location display.
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;

    // Start the location display.
    _mapViewController.locationDisplay.start();
  }

  void _updateRouteGraphics(TrackingStatus status) {
    // Update the graphics for the route traveled and ahead.
    _routeTravelledGraphic.geometry = status.routeProgress.traversedGeometry;
    _routeAheadGraphic.geometry = status.routeProgress.remainingGeometry;
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours Hours, $minutes Minutes, and $seconds Seconds';
    } else if (minutes > 0) {
      return '$minutes Minutes and $seconds Seconds';
    } else {
      return '$seconds Seconds';
    }
  }

  void _updateStatusText(TrackingStatus status) {
    // Updates the status text displayed to the user with the current navigation information.
    final remainingTime =
        Duration(seconds: status.routeProgress.remainingTime.round());
    final formattedTime = formatDuration(remainingTime);
    _statusTextNotifier.value = '''
  Distance remaining: ${status.routeProgress.remainingDistance.displayText} ${status.routeProgress.remainingDistance.displayTextUnits.abbreviation}
  Time remaining: $formattedTime
  Next direction: ${_directionsList[status.currentManeuverIndex + 1].directionText}
  ''';
  }

  void recenter() {
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;
  }

  // Reset the navigation state.
  Future<void> resetNavigation() async {
    setState(() => _ready = false);

    // Stop the location display.
    _mapViewController.locationDisplay.stop();

    // Solve the route again.
    await solveRoute();

    // Clear the existing graphics.
    _routeGraphicsOverlay.graphics.clear();

    // Add the new route graphics to the overlay.
    _routeGraphicsOverlay.graphics.add(_routeAheadGraphic);
    _routeGraphicsOverlay.graphics.add(_routeTravelledGraphic);

    // Stop any ongoing speech.
    await _flutterTts.stop();

    // Reset the status text.
    _statusTextNotifier.value = 'Directions are shown here.';

    // Set the viewpoint to encompass the route geometry.
    setInitialViewpoint();

    // Update the state to reflect the reset.
    setState(() => _ready = true);
  }
}
