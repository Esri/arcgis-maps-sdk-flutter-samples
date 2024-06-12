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
  // the symbol for the route line.
  final _routeLineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid, color: Colors.blue, width: 5.0);
  // the symbol for the start and end stops.
  final _routeStartSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle, color: Colors.green, size: 8.0);
  final _routeEndSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.circle, color: Colors.red, size: 8.0);
  // the stops for the route.
  final List<Stop> _stops = [];
  // whether the route has been generated.
  var _isRouteGenerated = false;
  // whether the map is ready.
  var _isReady = false;
  // the directions for the route.
  List<DirectionManeuver> _directions = [];
  // the parameters for the route.
  late final RouteParameters _routeParameters;
  // the route task.
  final _routeTask = RouteTask.withUrl(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRouteGenerated || !_isReady
                        ? null
                        : () => generateRoute(),
                    child: const Text('Route'),
                  ),
                  ElevatedButton(
                    onPressed: _isRouteGenerated
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

  Future<void> onMapViewReady() async {
    initMap();
    initStops();
    await initRouteParameters();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void initMap() {
    // a map with a topographic basemap style and an initial viewpoint.
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
    _mapViewController.graphicsOverlays.add(_routeGraphicsOverlay);
    _mapViewController.graphicsOverlays.add(_stopsGraphicsOverlay);
  }

  void initStops() {
    // the start and end points for the route.
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

    final originStop = Stop(point: startPoint);
    originStop.name = 'Origin';

    final destinationStop = Stop(point: endPoint);
    destinationStop.name = 'Destination';

    _stops.add(originStop);
    _stops.add(destinationStop);

    // add the start and end points to the stops graphics overlay.
    _stopsGraphicsOverlay.graphics.add(
      Graphic(geometry: startPoint, symbol: _routeStartSymbol),
    );
    _stopsGraphicsOverlay.graphics.add(
      Graphic(geometry: endPoint, symbol: _routeEndSymbol),
    );
  }

  Future<void> initRouteParameters() async {
    // create default route parameters.
    final parameters = await _routeTask.createDefaultParameters();
    parameters.setStops(_stops);
    parameters.returnDirections = true;
    parameters.directionsDistanceUnits = UnitSystem.imperial;
    parameters.returnRoutes = true;
    parameters.returnStops = true;

    _routeParameters = parameters;
  }

  void resetRoute() {
    // clear the route graphics overlay.
    _routeGraphicsOverlay.graphics.clear();

    setState(() {
      _directions = [];
      _isRouteGenerated = false;
    });
  }

  Future<void> generateRoute() async {
    // reset the route.
    resetRoute();

    // solve the route.
    final routeResult =
        await _routeTask.solveRoute(routeParameters: _routeParameters);
    if (routeResult.routes.isEmpty) {
      if (mounted) {
        showAlertDialog('No routes have been generated.', title: 'Info');
      }
      return;
    }

    // get the first route.
    final route = routeResult.routes[0];
    final routeGeometry = route.routeGeometry;

    //  add the route to the route graphics overlay.
    if (routeGeometry != null) {
      final routeGraphic =
          Graphic(geometry: routeGeometry, symbol: _routeLineSymbol);
      _routeGraphicsOverlay.graphics.add(routeGraphic);
    }

    if (mounted) {
      setState(() {
        _directions = route.directionManeuvers;
        _isRouteGenerated = true;
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
