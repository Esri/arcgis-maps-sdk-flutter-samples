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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
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
  final _bufferPoints = <ArcGISPoint>[];

  // List of buffer radii.
  final _bufferRadii = <double>[];

  // Current status of the buffer.
  var _status = Status.addPoints;

  // Buffer radius.
  var _bufferRadius = 100.0;

  // Union status.
  var _shouldUnion = false;

  // A flag for when the settings bottom sheet is visible.
  var _showSettings = false;

  // Define the graphics overlays.
  final _bufferGraphicsOverlay = GraphicsOverlay();
  final _tapPointGraphicsOverlay = GraphicsOverlay();

  // Fill symbols for buffer and tap points.
  final _bufferFillSymbol = SimpleFillSymbol();
  final _tapPointSymbol = SimpleMarkerSymbol();

  // Define the spatial reference required by the sample.
  final _statePlaneNorthCentralTexasSpatialReference = SpatialReference(
    wkid: 32038,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    // Conditionally display the settings.
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showSettings = !_showSettings);
                      },
                      child: const Text('Settings'),
                    ),
                    // A button to clear the buffers.
                    ElevatedButton(
                      onPressed:
                          _bufferPoints.isEmpty
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
            LoadingIndicator(visible: !_ready),
            // Display a banner with instructions at the top.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _status.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _showSettings ? buildSettings(context, setState) : null,
    );
  }

  void onMapViewReady() {
    // Initialize the boundary polygon and the symbols.
    _boundaryPolygon = _makeBoundaryPolygon();
    _initializeSymbols();

    // Create a map with the defined spatial reference and add it to our map controller.
    final map = ArcGISMap(
      spatialReference: _statePlaneNorthCentralTexasSpatialReference,
    );

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

    // Set the viewpoint of the map view to our boundary polygon extent.
    _mapViewController.setViewpoint(
      Viewpoint.fromTargetExtent(_boundaryPolygon.extent),
    );

    _configureGraphicsOverlays();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
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

  void _initializeSymbols() {
    // Initialize the fill symbol for the buffer.
    _bufferFillSymbol
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..outline = SimpleLineSymbol(color: Colors.green, width: 3);

    // Initialize the tap point symbol.
    _tapPointSymbol
      ..style = SimpleMarkerSymbolStyle.circle
      ..color = Colors.red
      ..size = 10;
  }

  // The build method for the settings.
  Widget buildSettings(BuildContext context, StateSetter setState) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _showSettings = false),
      settingsWidgets:
          (context) => [
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
                    setState(() => _shouldUnion = value);
                    if (_bufferPoints.isNotEmpty) {
                      drawBuffers(unionized: _shouldUnion);
                    }
                  },
                ),
              ],
            ),
          ],
    );
  }

  void _configureGraphicsOverlays() {
    // Create a graphics overlay to show the spatial reference's valid area.
    final boundaryGraphicsOverlay = GraphicsOverlay();

    // Add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(boundaryGraphicsOverlay);

    // Create a symbol for the graphics.
    final lineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.dash,
      color: const Color(0xFFFF0000),
      width: 5,
    );

    // Create the graphics.
    final boundaryGraphic = Graphic(
      geometry: _boundaryPolygon,
      symbol: lineSymbol,
    );

    // Add the graphics to the graphics overlay.
    boundaryGraphicsOverlay.graphics.add(boundaryGraphic);

    // Add the buffer and tap points graphics overlays to the map view.
    _mapViewController.graphicsOverlays.add(_bufferGraphicsOverlay);
    _mapViewController.graphicsOverlays.add(_tapPointGraphicsOverlay);
  }

  Polygon _makeBoundaryPolygon() {
    // Create a boundary polygon.
    final polygonBuilder = PolygonBuilder(
      spatialReference: SpatialReference.wgs84,
    );

    // Add points to define the boundary where the spatial reference is valid for planar buffers.
    polygonBuilder.addPointXY(x: -103.070, y: 31.720);
    polygonBuilder.addPointXY(x: -103.070, y: 34.580);
    polygonBuilder.addPointXY(x: -94, y: 34.580);
    polygonBuilder.addPointXY(x: -94, y: 31.720);

    // Use the polygon builder to define a boundary geometry.
    final boundaryGeometry = polygonBuilder.toGeometry();

    // Project the boundary geometry to the spatial reference used by the sample.
    final boundaryPolygon =
        GeometryEngine.project(
              boundaryGeometry,
              outputSpatialReference:
                  _statePlaneNorthCentralTexasSpatialReference,
            )
            as Polygon;

    return boundaryPolygon;
  }

  void drawBuffers({required bool unionized}) {
    // Clear existing buffers before drawing.
    _bufferGraphicsOverlay.graphics.clear();
    _tapPointGraphicsOverlay.graphics.clear();

    // Create buffers.
    final bufferPolygons = GeometryEngine.bufferCollection(
      geometries: _bufferPoints,
      distances: _bufferRadii,
      unionResult: unionized,
    );

    // Add the tap points to the tapPointsGraphicsOverlay.
    for (final point in _bufferPoints) {
      _tapPointGraphicsOverlay.graphics.add(
        Graphic(geometry: point, symbol: _tapPointSymbol),
      );
    }

    // Add the buffers to the bufferGraphicsOverlay.
    for (final bufferPolygon in bufferPolygons) {
      _bufferGraphicsOverlay.graphics.add(
        Graphic(geometry: bufferPolygon, symbol: _bufferFillSymbol),
      );
    }
  }

  // Clears the buffer points.
  void clearBufferPoints() {
    _bufferPoints.clear();
    _bufferRadii.clear();
    _bufferGraphicsOverlay.graphics.clear();
    _tapPointGraphicsOverlay.graphics.clear();
  }

  void addBuffer({required ArcGISPoint point, required double radius}) {
    // Ensure the radius is within a valid range before adding the buffer.
    if (radius <= 0 || radius > 300) {
      setState(() => _status = Status.invalidInput);
      return;
    }
    // Convert the radius from miles to feet directly.
    final radiusInFeet = radius * 5280;

    // Add point with radius to bufferPoints  and bufferRadii lists.
    _bufferPoints.add(point);
    _bufferRadii.add(radiusInFeet);
  }
}

enum Status {
  addPoints('Tap on the map to add buffers.'),
  bufferCreated('Buffer created.'),
  outOfBoundsTap('Tap within the boundary to add buffer.'),
  invalidInput('Enter a value between 0 and 300 to create a buffer.'),
  noPoints('Add a point to draw the buffers.');

  const Status(this.label);

  final String label;
}
