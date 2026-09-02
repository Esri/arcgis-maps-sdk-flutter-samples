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
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CreateAndSaveKmlFile extends StatefulWidget {
  const CreateAndSaveKmlFile({super.key});

  @override
  State<CreateAndSaveKmlFile> createState() => _CreateAndSaveKmlFileState();
}

class _CreateAndSaveKmlFileState extends State<CreateAndSaveKmlFile>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a geometry editor for sketching map geometries.
  final _geometryEditor = GeometryEditor();
  // Listen for changes to the geometry being sketched.
  StreamSubscription<Geometry?>? _geometrySubscription;
  // Store the colors that can be used for line and polygon styles.
  final _styleColors = const [
    Colors.red,
    Colors.yellow,
    Colors.white,
    Colors.purple,
    Colors.orange,
    Colors.pinkAccent,
  ];

  // Store the KML document that contains the created placemarks.
  late KmlDocument _kmlDocument;
  // Store the style to apply to the next placemark.
  KmlStyle? _kmlStyle;
  // Store the geometry type currently being sketched.
  GeometryType? _selectedGeometryType;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag indicating whether the KML document contains a saved placemark.
  var _hasSavedSketches = false;
  // A flag indicating whether the active sketch can be saved.
  var _canSaveSketch = false;

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
                    onMapViewReady: _onMapViewReady,
                  ),
                ),
                _buildControls(),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    // Create a map with a dark gray basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISDarkGrayBase);
    _mapViewController.arcGISMap = map;

    // Connect the geometry editor to the map view controller.
    _mapViewController.geometryEditor = _geometryEditor;
    // Update the save control when the active sketch gains or loses geometry.
    _geometrySubscription = _geometryEditor.onGeometryChanged.listen((
      geometry,
    ) {
      if (mounted) {
        setState(() => _canSaveSketch = _isSketchValid(geometry));
      }
    });

    // Create a KML document, its dataset, and its operational layer.
    _createKmlDocumentAndLayer();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Widget _buildControls() {
    // Build feature and export controls when a geometry type has not been selected.
    if (_selectedGeometryType == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 4,
              children: [
                MenuAnchor(
                  menuChildren: _PointStyle.values
                      .map(
                        (style) => MenuItemButton(
                          onPressed: () => _startPointSketch(style),
                          child: Text(style.label),
                        ),
                      )
                      .toList(),
                  builder: (context, controller, child) => Tooltip(
                    message: 'New Point',
                    child: TextButton.icon(
                      onPressed: _ready ? () => controller.open() : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.radio_button_checked),
                      label: const Text('New Point'),
                    ),
                  ),
                ),
                MenuAnchor(
                  menuChildren: _styleColors
                      .map(
                        (color) => MenuItemButton(
                          onPressed: () => _startPolylineSketch(color),
                          child: _buildColorMenuItem(color),
                        ),
                      )
                      .toList(),
                  builder: (context, controller, child) => Tooltip(
                    message: 'New Line',
                    child: TextButton.icon(
                      onPressed: _ready ? () => controller.open() : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.polyline_outlined),
                      label: const Text('New Line'),
                    ),
                  ),
                ),
                MenuAnchor(
                  menuChildren: _styleColors
                      .map(
                        (color) => MenuItemButton(
                          onPressed: () => _startPolygonSketch(color),
                          child: _buildColorMenuItem(color),
                        ),
                      )
                      .toList(),
                  builder: (context, controller, child) => Tooltip(
                    message: 'New Area',
                    child: TextButton.icon(
                      onPressed: _ready ? () => controller.open() : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.pentagon_outlined),
                      label: const Text('New Area'),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _ready && _hasSavedSketches ? _saveKmz : null,
                  child: const Text('Save KMZ file'),
                ),
                ElevatedButton(
                  onPressed: _ready && _hasSavedSketches
                      ? _createKmlDocumentAndLayer
                      : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Build controls for an active sketch.
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _canSaveSketch ? _completeSketch : null,
            child: const Text('Save Sketch'),
          ),
          TextButton(
            onPressed: _cancelSketch,
            child: const Text('Cancel Sketch'),
          ),
        ],
      ),
    );
  }

  void _startSketch(GeometryType geometryType, KmlStyle style) {
    // Store the selected style and start the geometry editor with its geometry type.
    _kmlStyle = style;
    _geometryEditor.startWithGeometryType(geometryType);
    setState(() {
      _selectedGeometryType = geometryType;
      _canSaveSketch = false;
    });
  }

  void _startPointSketch(_PointStyle pointStyle) {
    // Start a point sketch with the selected KML icon style.
    final icon = KmlIcon(Uri.parse(pointStyle.url));
    _startSketch(
      GeometryType.point,
      KmlStyle()..iconStyle = KmlIconStyle(icon: icon),
    );
  }

  void _startPolylineSketch(Color color) {
    // Start a polyline sketch with the selected KML line style.
    _startSketch(
      GeometryType.polyline,
      KmlStyle()..lineStyle = KmlLineStyle(color: color),
    );
  }

  void _startPolygonSketch(Color color) {
    // Start a polygon sketch with the selected KML polygon style.
    _startSketch(
      GeometryType.polygon,
      KmlStyle()
        ..polygonStyle = (KmlPolygonStyle(fillColor: color)
          ..isFilled = true
          ..isOutlined = false),
    );
  }

  void _completeSketch() {
    // Stop the geometry editor and retrieve the completed geometry.
    final geometry = _geometryEditor.stop();
    if (geometry == null || !_isSketchValid(geometry)) {
      setState(() {
        _selectedGeometryType = null;
        _canSaveSketch = false;
      });
      return;
    }

    // Project the geometry to the WGS84 spatial reference required by KML.
    final projectedGeometry = GeometryEngine.project(
      geometry,
      outputSpatialReference: SpatialReference.wgs84,
    );
    // Create a KML geometry and add its placemark to the KML document.
    final kmlGeometry = KmlGeometry.create(
      geometry: projectedGeometry,
      altitudeMode: KmlAltitudeMode.clampToGround,
    );
    if (kmlGeometry == null) {
      setState(() {
        _selectedGeometryType = null;
        _canSaveSketch = false;
      });
      return;
    }
    final placemark = KmlPlacemark.withGeometry(kmlGeometry);
    placemark.style = _kmlStyle;
    _kmlDocument.childNodes.add(placemark);

    // Return to the drawing controls after saving the completed placemark.
    setState(() {
      _selectedGeometryType = null;
      _hasSavedSketches = true;
      _canSaveSketch = false;
    });
  }

  void _cancelSketch() {
    // Stop the geometry editor and discard the active sketch.
    _geometryEditor.stop();
    setState(() {
      _selectedGeometryType = null;
      _canSaveSketch = false;
    });
  }

  Future<void> _saveKmz() async {
    // Create a temporary location for the KMZ file before exporting it.
    final temporaryDirectory = await Directory.systemTemp.createTemp('kml-');
    final temporaryFile = File('${temporaryDirectory.path}/Untitled.kmz');

    try {
      // Save the KML document as a KMZ archive before presenting Save As.
      await _kmlDocument.saveAs(kmzFileUri: temporaryFile.uri);
      // Let the user choose the final name and destination for the KMZ file.
      await FilePicker.saveFile(
        dialogTitle: 'Save KMZ file',
        fileName: 'Untitled.kmz',
        type: FileType.custom,
        allowedExtensions: ['kmz'],
        bytes: await temporaryFile.readAsBytes(),
      );
    } on Exception catch (exception) {
      // Report a failure to save the KMZ file.
      if (mounted) showExceptionDialog('Failed to save KMZ file', exception);
    } finally {
      // Remove the temporary KMZ file after the save dialog closes.
      temporaryDirectory.delete(recursive: true).ignore();
    }
  }

  void _createKmlDocumentAndLayer() {
    // Create a KML document to contain new placemarks.
    _kmlDocument = KmlDocument();
    // Create a dataset that uses the KML document as its root node.
    final kmlDataset = KmlDataset.withRootNode(_kmlDocument);
    // Create a layer that displays the KML dataset on the map.
    final kmlLayer = KmlLayer(kmlDataset);
    // Replace all operational layers with the new KML layer.
    final map = _mapViewController.arcGISMap;
    if (map == null) return;
    map.operationalLayers
      ..clear()
      ..add(kmlLayer);
    // Reset the selected style and controls for the new document.
    setState(() {
      _kmlStyle = null;
      _hasSavedSketches = false;
      _canSaveSketch = false;
    });
  }

  bool _isSketchValid(Geometry? geometry) {
    // Check whether the geometry has enough vertices for its geometry type.
    return switch (geometry) {
      final ArcGISPoint point => PointBuilder.fromPoint(point).isSketchValid,
      final Polyline polyline => PolylineBuilder.fromPolyline(
        polyline,
      ).isSketchValid,
      final Polygon polygon => PolygonBuilder.fromPolygon(
        polygon,
      ).isSketchValid,
      _ => false,
    };
  }

  @override
  void dispose() {
    // Cancel the geometry listener before disposing this sample state.
    _geometrySubscription?.cancel().ignore();
    super.dispose();
  }

  Widget _buildColorMenuItem(Color color) {
    // Build a color swatch and label for a style menu option.
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        const SizedBox(width: 8),
        Text(_colorLabel(color)),
      ],
    );
  }

  String _colorLabel(Color color) {
    // Return the menu label for a KML style color.
    return switch (color) {
      Colors.red => 'Red',
      Colors.yellow => 'Yellow',
      Colors.white => 'White',
      Colors.purple => 'Purple',
      Colors.orange => 'Orange',
      Colors.pinkAccent => 'Pink Accent',
      _ => 'Unknown',
    };
  }
}

// Define the point icon styles available for new KML placemarks.
enum _PointStyle {
  noStyle(
    'No Style',
    'http://resources.esri.com/help/900/arcgisexplorer/sdk/doc/bitmaps/148cca9a-87a8-42bd-9da4-5fe427b6fb7b127.png',
  ),
  star(
    'Star',
    'https://static.arcgis.com/images/Symbols/Shapes/BlueStarLargeB.png',
  ),
  diamond(
    'Diamond',
    'https://static.arcgis.com/images/Symbols/Shapes/BlueDiamondLargeB.png',
  ),
  circle(
    'Circle',
    'https://static.arcgis.com/images/Symbols/Shapes/BlueCircleLargeB.png',
  ),
  square(
    'Square',
    'https://static.arcgis.com/images/Symbols/Shapes/BlueSquareLargeB.png',
  ),
  roundPin(
    'Round pin',
    'https://static.arcgis.com/images/Symbols/Shapes/BluePin1LargeB.png',
  ),
  squarePin(
    'Square pin',
    'https://static.arcgis.com/images/Symbols/Shapes/BluePin2LargeB.png',
  );

  const _PointStyle(this.label, this.url);

  final String label;
  final String url;
}
