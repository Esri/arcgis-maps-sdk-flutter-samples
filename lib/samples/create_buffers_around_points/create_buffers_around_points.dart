import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class CreateBuffersAroundPoints extends StatefulWidget {
  const CreateBuffersAroundPoints({super.key});

  @override
  State<CreateBuffersAroundPoints> createState() =>
      _CreateBuffersAroundPointsState();
}

class _CreateBuffersAroundPointsState extends State<CreateBuffersAroundPoints>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A polygon that represents the valid area of use for the spatial reference.
  late Polygon _boundaryPolygon;

  // List of tap points.
  final _bufferPoints = <PointAndRadius>[];

  // Current status of the buffer.
  var _status = Status.addPoints;

  // Buffer radius.
  var _bufferRadius = 100.0;

  // Union status.
  var _shouldUnion = false;

  // Define the graphics overlays.
  final bufferGraphicsOverlay = GraphicsOverlay();
  final tapPointGraphicsOverlay = GraphicsOverlay();

  // Fill symbols for buffer and tap points.
  final bufferFillSymbol = SimpleFillSymbol();
  final tapPointSymbol = SimpleMarkerSymbol();

  final statePlanNorthCentralTexasSpatialReference =
      SpatialReference(wkid: 32038);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: onTap,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder:
                                  (BuildContext context, StateSetter setState) {
                                return buildSettings(context, setState);
                              },
                            );
                          },
                        );
                      },
                      child: const Text('Settings'),
                    ),

                    // A button to clear the buffers.
                    ElevatedButton(
                      onPressed: _bufferPoints.isEmpty
                          ? null
                          : () {
                              clearBufferPoints();
                              setState(() => _status = Status.addPoints);
                            },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.4),
                child: Text(
                  _status.label,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeSymbols() {
    // Initialize the fill symbol for the buffer.
    bufferFillSymbol
      ..color = Colors.yellow.withOpacity(0.5)
      ..outline = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid,
        color: Colors.green,
        width: 3,
      );

    // Initialize the tap point symbol.
    tapPointSymbol
      ..style = SimpleMarkerSymbolStyle.circle
      ..color = Colors.red
      ..size = 10;
  }

  // The build method for the Setting bottom sheet.
  Widget buildSettings(BuildContext context, StateSetter setState) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Buffer Radius (miles)'),
              const Spacer(),
              Text(
                _bufferRadius.round().toString(),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                // A slider to adjust the buffer radius.
                child: Slider(
                  value: _bufferRadius,
                  min: 10,
                  max: 300,
                  onChanged: (value) => setState(() => _bufferRadius = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(_shouldUnion ? 'Union Enabled' : 'Union Disabled'),
              const Spacer(),
              Switch(
                value: _shouldUnion,
                onChanged: (value) {
                  setState(() {
                    _shouldUnion = value;
                    if (_bufferPoints.isNotEmpty) {
                      drawBuffers(unionized: _shouldUnion);
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Initialize the boundary polygon and the symbols.
    _boundaryPolygon = _makeBoundaryPolygon();
    _initializeSymbols();

    // Create a map with the spatial reference as the basemap and add it to our map controller.
    final map =
        ArcGISMap(spatialReference: statePlanNorthCentralTexasSpatialReference);

    // Add some base layers (counties, cities, highways).
    final mapServiceUri = Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer',
    );

    // Create a map image layer from the uri.
    final usaLayer = ArcGISMapImageLayer.withUri(mapServiceUri);

    // Add the map image layer to the map.
    map.operationalLayers.add(usaLayer);

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the viewpoint of the map to our boundary polygon extent.
    _mapViewController
        .setViewpoint(Viewpoint.fromTargetExtent(_boundaryPolygon.extent));

    _loadGraphicsOverlays();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void _loadGraphicsOverlays() {
    // Create a graphics overlay to show the spatial reference's valid area:
    final boundaryGraphicsOverlay = GraphicsOverlay();

    // Add the graphics overlay to the mapView.
    _mapViewController.graphicsOverlays.add(boundaryGraphicsOverlay);

    // Create a symbol for the graphics.
    final lineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.dash,
      color: const Color(0xFFFF0000),
      width: 5,
    );

    // Create the graphics.
    final boundaryGraphic =
        Graphic(geometry: _boundaryPolygon, symbol: lineSymbol);

    // Add the graphics to the graphics overlay.
    boundaryGraphicsOverlay.graphics.add(boundaryGraphic);

    // Add the buffer and tap points graphics overlays to the map view.
    _mapViewController.graphicsOverlays.add(bufferGraphicsOverlay);
    _mapViewController.graphicsOverlays.add(tapPointGraphicsOverlay);
  }

  Polygon _makeBoundaryPolygon() {
    // Create a boundary polygon.
    final polygonBuilder =
        PolygonBuilder(spatialReference: SpatialReference.wgs84);

    // Add points to define the boundary where the spatial reference is valid for planar buffers.
    polygonBuilder.addPointXY(x: -103.070, y: 31.720);
    polygonBuilder.addPointXY(x: -103.070, y: 34.580);
    polygonBuilder.addPointXY(x: -94.000, y: 34.580);
    polygonBuilder.addPointXY(x: -94.000, y: 31.720);

    final boundaryGeometry = polygonBuilder.toGeometry();

    final boundaryPolygon = GeometryEngine.project(
      boundaryGeometry,
      outputSpatialReference: statePlanNorthCentralTexasSpatialReference,
    ) as Polygon;

    return boundaryPolygon;
  }

  void onTap(Offset offset) {
    // Convert the screen point to a map point.
    final mapPoint = _mapViewController.screenToLocation(screen: offset);

    // Ensure the map point is within the boundary.
    if (!GeometryEngine.contains(
      geometry1: _boundaryPolygon,
      geometry2: mapPoint!,
    )) {
      setState(() => _status = Status.outOfBoundsTap);
      return;
    }

    // Use the current buffer radius value from the slider.
    addBuffer(point: mapPoint, radius: _bufferRadius);
    drawBuffers(unionized: _shouldUnion);

    setState(() => _status = Status.bufferCreated);
  }

  void drawBuffers({required bool unionized}) {
    // Clear existing buffers before drawing.
    bufferGraphicsOverlay.graphics.clear();
    tapPointGraphicsOverlay.graphics.clear();

    // Reduce the tap bufferPoints tuples into points and radii array
    final points = <ArcGISPoint>[];
    final radii = <double>[];

    for (final pointAndRadius in _bufferPoints) {
      points.add(pointAndRadius.point);
      radii.add(pointAndRadius.radius);
    }

    // Create buffers.
    final bufferPolygons = GeometryEngine.bufferCollection(
      geometries: points,
      distances: radii,
      unionResult: unionized,
    );

    // Add the tap points to the tapPointsGraphicsOverlay.
    for (final point in points) {
      tapPointGraphicsOverlay.graphics.add(
        Graphic(geometry: point, symbol: tapPointSymbol),
      );
    }

    // Add the buffers to the bufferGraphicsOverlay.
    for (final bufferPolygon in bufferPolygons) {
      bufferGraphicsOverlay.graphics.add(
        Graphic(geometry: bufferPolygon, symbol: bufferFillSymbol),
      );
    }
  }

  // Clears the buffer points.
  void clearBufferPoints() {
    _bufferPoints.clear();
    bufferGraphicsOverlay.graphics.clear();
    tapPointGraphicsOverlay.graphics.clear();
  }

  void addBuffer({required ArcGISPoint point, required double radius}) {
    // Ensure the radius is within a valid range before adding the buffer.
    if (radius <= 0 || radius > 300) {
      setState(() => _status = Status.invalidInput);
      return;
    }
    // Convert the radius from miles to feet directly.
    final radiusInFeet = radius * 5280;

    // Add point with radius to bufferPoints list.
    _bufferPoints.add(PointAndRadius(point: point, radius: radiusInFeet));
  }
}

class PointAndRadius {
  final ArcGISPoint point;
  final double radius;

  PointAndRadius({required this.point, required this.radius});
}

enum Status {
  addPoints('Tap on the map to add buffers.'),
  bufferCreated('Buffer created.'),
  outOfBoundsTap('Tap within the boundary to add buffer.'),
  invalidInput('Enter a value between 0 and 300 to create a buffer.'),
  noPoints('Add a point to draw the buffers.');

  final String label;

  const Status(this.label);
}
