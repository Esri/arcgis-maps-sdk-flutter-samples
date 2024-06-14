//
// Copyright 2024 Esri
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
import 'package:flutter/material.dart';

class FindRouteSample extends StatefulWidget {
  const FindRouteSample({super.key});

  @override
  State<FindRouteSample> createState() => _FindRouteSampleState();
}

class _FindRouteSampleState extends State<FindRouteSample> {
  // the map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // the graphics overlay for the stops.
  final _stopsGraphicsOverlay = GraphicsOverlay();
  // the graphics overlay for the route.
  final _routeGraphicsOverlay = GraphicsOverlay();
  // the stops for the route.
  final _stops = <Stop>[];
  // whether the route has been generated.
  var _routeGenerated = false;
  // a flag for when the map view is ready used to control availability of parts of the UI.
  var _ready = false;
  // the directions for the route.
  var _directions = <DirectionManeuver>[];
  // the parameters for the route.
  late final RouteParameters _routeParameters;
  // the route task.
  final _routeTask = RouteTask.withUrl(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // create a column with buttons for generating the route and showing the directions.
        child: Column(
          children: [
            // add the map view to the column.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            SizedBox(
              height: 60,
              // add the buttons to the column.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // create a button to generate the route.
                  ElevatedButton(
                    onPressed: _routeGenerated || !_ready
                        ? null
                        : () => generateRoute(),
                    child: const Text('Route'),
                  ),
                  // create a button to show the directions.
                  ElevatedButton(
                    onPressed: _routeGenerated
                        ? () => showDialog(
                              context: context,
                              builder: (context) => showDirections(context),
                            )
                        : null,
                    child: const Text('Directions'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    initMap();
    initStops();
    await initRouteParameters();
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void initMap() {
    // create a map with a topographic basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -13041154.7153,
        y: 3858170.2368,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 1e5,
    );
    // set the map on the map view controller.
    _mapViewController.arcGISMap = map;
    // add the graphics overlays to the map view.
    _mapViewController.graphicsOverlays.add(_routeGraphicsOverlay);
    _mapViewController.graphicsOverlays.add(_stopsGraphicsOverlay);
  }

  void initStops() {
    // create symbols to use for the start and end stops of the route.
    final routeStartSymbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle, color: Colors.green, size: 8.0);
    final routeEndSymbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle, color: Colors.red, size: 8.0);

    // configure pre-defined start and end points for the route.
    final startPoint = ArcGISPoint(
      x: -13041171.537945,
      y: 3860988.271378,
      spatialReference: SpatialReference.webMercator,
    );

    final endPoint = ArcGISPoint(
      x: -13041693.562570,
      y: 3856006.859684,
      spatialReference: SpatialReference.webMercator,
    );

    final originStop = Stop(point: startPoint)..name = 'Origin';

    final destinationStop = Stop(point: endPoint)..name = 'Destination';

    _stops.add(originStop);
    _stops.add(destinationStop);

    // add the start and end points to the stops graphics overlay.
    _stopsGraphicsOverlay.graphics.add(
      Graphic(geometry: startPoint, symbol: routeStartSymbol),
    );
    _stopsGraphicsOverlay.graphics.add(
      Graphic(geometry: endPoint, symbol: routeEndSymbol),
    );
  }

  Future<void> initRouteParameters() async {
    // create default route parameters.
    _routeParameters = await _routeTask.createDefaultParameters()
      ..setStops(_stops)
      ..returnDirections = true
      ..directionsDistanceUnits = UnitSystem.imperial
      ..returnRoutes = true
      ..returnStops = true;
  }

  void resetRoute() {
    // clear the route graphics overlay.
    _routeGraphicsOverlay.graphics.clear();

    setState(() {
      _directions = [];
      _routeGenerated = false;
    });
  }

  Future<void> generateRoute() async {
    // the symbol for the route line.
    final routeLineSymbol = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid, color: Colors.blue, width: 5.0);

    // reset the route.
    resetRoute();

    // solve the route using the route parameters.
    final routeResult =
        await _routeTask.solveRoute(routeParameters: _routeParameters);
    if (routeResult.routes.isEmpty) {
      if (mounted) {
        showAlertDialog('No routes have been generated.', title: 'Info');
      }
      return;
    }

    // get the first route.
    final route = routeResult.routes.first;
    final routeGeometry = route.routeGeometry;

    //  add the route to the route graphics overlay.
    if (routeGeometry != null) {
      final routeGraphic =
          Graphic(geometry: routeGeometry, symbol: routeLineSymbol);
      _routeGraphicsOverlay.graphics.add(routeGraphic);
    }

    if (mounted) {
      setState(() {
        _directions = route.directionManeuvers;
        _routeGenerated = true;
      });
    }
  }

  Dialog showDirections(BuildContext context) {
    // show the directions in a dialog.
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Center(
              child: Text('Directions',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            Expanded(
                child: _directions.isEmpty
                    ? const Center(child: Text('No directions to show.'))
                    : buildDirectionsListView()),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  ListView buildDirectionsListView() {
    // build a list view of the directions.
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _directions.length,
      itemBuilder: ((context, index) {
        return Text(_directions[index].directionText);
      }),
      separatorBuilder: (context, index) => const Divider(),
    );
  }

  Future<void> showAlertDialog(String message, {String title = 'Alert'}) {
    // show an alert dialog.
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'))
        ],
      ),
    );
  }
}
