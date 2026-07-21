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
import 'dart:math' as math;

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class DisplayGeometryEditorInformationDuringInteraction extends StatefulWidget {
  const DisplayGeometryEditorInformationDuringInteraction({super.key});

  @override
  State<DisplayGeometryEditorInformationDuringInteraction> createState() =>
      _DisplayGeometryEditorInformationDuringInteractionState();
}

class _DisplayGeometryEditorInformationDuringInteractionState
    extends State<DisplayGeometryEditorInformationDuringInteraction>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create a geometry editor to edit selected graphics.
  final _geometryEditor = GeometryEditor();

  // Create a graphics overlay to display editable geometries.
  final _graphicsOverlay = GraphicsOverlay();

  // Keep stream subscriptions so they can be cancelled when the sample closes.
  final _subscriptions = <StreamSubscription<dynamic>>[];
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Track the graphic currently being edited.
  Graphic? _editingGraphic;

  // Track the current editing state for the action controls.
  var _geometryEditorIsStarted = false;

  // Track whether the undo action is currently available.
  var _geometryEditorCanUndo = false;

  // Track whether the redo action is currently available.
  var _geometryEditorCanRedo = false;

  // Store the current preview information text for display.
  String? _interactionPreviewDescription;

  // Store the current preview value text for display.
  String? _interactionPreviewValue;

  @override
  void dispose() {
    // Cancel geometry editor subscriptions before disposing the widget.
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            ],
          ),
          // Display the editing controls over the map.
          Positioned(top: 10, right: 10, child: buildEditingPanel(context)),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with the streets basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    _mapViewController.arcGISMap = map;

    // Add graphics that can be selected and edited.
    _graphicsOverlay.graphics.addAll(initialGraphics());
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Set the initial viewpoint over the editable geometries.
    _mapViewController.setViewpoint(
      Viewpoint.fromJsonString('''
{"rotation":0.0,"scale":35000,"targetGeometry":{"spatialReference":{"wkid":3857},"x":-13045202.018086127,"y":4035612.571361517}}
'''),
    );

    // Configure the vertex tool to transform complete geometries only.
    final configuration = InteractionConfiguration()
      ..allowVertexCreation = false
      ..allowMidVertexSelection = false
      ..allowDeletingSelectedElement = false
      ..allowVertexSelection = false
      ..allowPartCreation = false;
    _geometryEditor.tool = VertexTool()..configuration = configuration;

    // Listen for preview changes and update the feedback panel.
    _subscriptions.add(
      _geometryEditor.onInteractionPreviewChanged.listen(
        updateInteractionPreview,
      ),
    );
    // Listen for undo and redo changes to enable the toolbar buttons.
    _subscriptions.add(
      _geometryEditor.onCanUndoChanged.listen(
        (canUndo) => setState(() => _geometryEditorCanUndo = canUndo),
      ),
    );
    _subscriptions.add(
      _geometryEditor.onCanRedoChanged.listen(
        (canRedo) => setState(() => _geometryEditorCanRedo = canRedo),
      ),
    );
    // Set the geometry editor to the map view controller.
    _mapViewController.geometryEditor = _geometryEditor;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    // Ignore taps while editing is already in progress.
    if (_geometryEditorIsStarted) return;

    // Identify a graphic to edit at the tapped location.
    final results = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 12,
    );
    if (results.graphics.isEmpty) return;

    // Start editing the identified graphic's geometry.
    final identifiedGraphic = results.graphics.first;
    final geometry = identifiedGraphic.geometry;
    if (geometry == null) return;

    identifiedGraphic.isVisible = false;
    _geometryEditor.startWithGeometry(geometry);
    _geometryEditor.selectGeometry();

    setState(() {
      _editingGraphic = identifiedGraphic;
      _geometryEditorIsStarted = true;
      _interactionPreviewDescription = null;
      _interactionPreviewValue = null;
    });
  }

  void updateInteractionPreview(
    GeometryEditorInteractionPreview? interactionPreview,
  ) {
    // Clear the preview panel when an interaction finishes.
    if (interactionPreview == null) {
      setState(() {
        _interactionPreviewDescription = null;
        _interactionPreviewValue = null;
      });
      return;
    }

    // Select the feedback text based on the current interaction type.
    switch (interactionPreview.interactionType) {
      case GeometryEditorInteractionType.move:
        setMovingGeometryLabel(interactionPreview);
      case GeometryEditorInteractionType.rotate:
        setRotationAngleLabel(interactionPreview);
      case GeometryEditorInteractionType.scale:
        setScaleFactorLabel(interactionPreview);
      case GeometryEditorInteractionType.create:
        setState(() {
          _interactionPreviewDescription = 'Interaction:';
          _interactionPreviewValue = 'Creating geometry';
        });
    }
  }

  void setMovingGeometryLabel(
    GeometryEditorInteractionPreview interactionPreview,
  ) {
    // Get the center point of the preview geometry.
    final previewCenter = interactionPreview.previewGeometry.extent.center;

    // Update the feedback label with the preview center point.
    setState(() {
      _interactionPreviewDescription = 'Center (X, Y):';
      _interactionPreviewValue =
          '(${previewCenter.x.toStringAsFixed(2)}, '
          '${previewCenter.y.toStringAsFixed(2)})';
    });
  }

  void setRotationAngleLabel(
    GeometryEditorInteractionPreview interactionPreview,
  ) {
    // Get the current geometry and its center point for the rotation calculation.
    final originalGeometry = _geometryEditor.geometry;
    if (originalGeometry == null) return;

    final center = originalGeometry.extent.center;

    // Get comparable points from the original and preview geometries.
    final originalPoint = pointForRotation(originalGeometry, center);
    final previewPoint = pointForRotation(
      interactionPreview.previewGeometry,
      center,
    );
    if (originalPoint == null || previewPoint == null) return;

    // Calculate the clockwise rotation angle in degrees.
    final vector1X = originalPoint.x - center.x;
    final vector2X = previewPoint.x - center.x;
    final vector1Y = originalPoint.y - center.y;
    final vector2Y = previewPoint.y - center.y;
    final cross = vector1X * vector2Y - vector1Y * vector2X;
    final dot = vector1X * vector2X + vector1Y * vector2Y;
    final angle = math.atan2(cross, dot) * (180.0 / math.pi);
    final clockwiseNormalized = ((-angle % 360) + 360) % 360;

    // Update the feedback label with the rotation angle.
    setState(() {
      _interactionPreviewDescription = 'Rotation Angle (degrees):';
      _interactionPreviewValue = clockwiseNormalized.toStringAsFixed(2);
    });
  }

  void setScaleFactorLabel(
    GeometryEditorInteractionPreview interactionPreview,
  ) {
    // Get the current geometry extents for the scale calculation.
    final originalGeometry = _geometryEditor.geometry;
    if (originalGeometry == null) return;

    final originalExtent = originalGeometry.extent;
    final previewExtent = interactionPreview.previewGeometry.extent;
    if (originalExtent.width == 0 || originalExtent.height == 0) return;

    // Calculate the X and Y scale factors.
    final scaleX = previewExtent.width / originalExtent.width;
    final scaleY = previewExtent.height / originalExtent.height;

    // Update the feedback label with the scale factors.
    setState(() {
      _interactionPreviewDescription = 'Scale Factor (X, Y):';
      _interactionPreviewValue =
          '(${scaleX.toStringAsFixed(2)}, ${scaleY.toStringAsFixed(2)})';
    });
  }

  ArcGISPoint? pointForRotation(Geometry geometry, ArcGISPoint center) {
    // Get a stable non-center point from multipart and multipoint geometries.
    switch (geometry) {
      case final Multipart multipart:
        return multipart.parts.first.endPoint;
      case final Multipoint multipoint:
        return multipoint.points.firstWhere(
          (point) => point.x != center.x || point.y != center.y,
        );
      default:
        return null;
    }
  }

  void stopAndSaveEdits() {
    // Stop the geometry editor and save the edited geometry back to the graphic.
    final geometry = _geometryEditor.stop();
    if (geometry != null && _editingGraphic != null) {
      _editingGraphic!
        ..geometry = geometry
        ..isVisible = true;
    }

    // Reset the editing state.
    setState(() {
      _editingGraphic = null;
      _geometryEditorIsStarted = false;
      _interactionPreviewDescription = null;
      _interactionPreviewValue = null;
    });
  }

  void stopAndDiscardEdits() {
    // Stop the geometry editor and restore the original graphic.
    _geometryEditor.stop();
    _editingGraphic?.isVisible = true;

    // Reset the editing state.
    setState(() {
      _editingGraphic = null;
      _geometryEditorIsStarted = false;
      _interactionPreviewDescription = null;
      _interactionPreviewValue = null;
    });
  }

  Widget buildEditingPanel(BuildContext context) {
    // Build a compact panel for editing actions and interaction feedback.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(
                _geometryEditorIsStarted
                    ? 'Use the handles to move, rotate, or scale.'
                    : 'Tap a graphic to start the geometry editor.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_geometryEditorIsStarted) ...[
                // Add buttons to save, discard, undo, and redo edits.
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Save edits',
                        child: ElevatedButton(
                          onPressed: stopAndSaveEdits,
                          child: const Icon(Icons.check_circle_outline),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Tooltip(
                        message: 'Discard edits',
                        child: ElevatedButton(
                          onPressed: stopAndDiscardEdits,
                          child: const Icon(Icons.cancel_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Undo',
                        child: ElevatedButton(
                          onPressed: _geometryEditorCanUndo
                              ? _geometryEditor.undo
                              : null,
                          child: const Icon(Icons.undo),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Tooltip(
                        message: 'Redo',
                        child: ElevatedButton(
                          onPressed: _geometryEditorCanRedo
                              ? _geometryEditor.redo
                              : null,
                          child: const Icon(Icons.redo),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_interactionPreviewDescription != null &&
                    _interactionPreviewValue != null)
                  // Display information about the current interaction preview.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        _interactionPreviewDescription!,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Expanded(
                        child: Text(
                          _interactionPreviewValue!,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Graphic> initialGraphics() {
    // Create symbols for each editable geometry type.
    final lineSymbol = SimpleLineSymbol(color: Colors.red, width: 2);
    final markerSymbol = SimpleMarkerSymbol(color: Colors.blue);

    // Create a polygon, polyline, and multipoint in Redlands, California.
    final redlandsPolygon = Geometry.fromJsonString('''
{"rings":[[[-13046991.222211758,4034618.5047884779],[-13046991.222211758,4035962.0723415823],[-13045677.652220398,4035962.0723415823],[-13045677.652220398,4034618.5047884779],[-13046991.222211758,4034618.5047884779]]],"spatialReference":{"wkid":3857}}
''');
    final redlandsPolyline = Geometry.fromJsonString('''
{"paths":[[[-13044533.805088846,4034221.5100018946],[-13043597.938505623,4034197.1337576872],[-13043597.938505623,4035135.572073034],[-13044522.634505576,4035170.5449295067]]],"spatialReference":{"wkid":3857}}
''');
    final redlandsMultipoint = Geometry.fromJsonString('''
{"points":[[-13045283.292102993,4035739.1925106063],[-13045314.922186911,4036533.8852012255],[-13044798.24723932,4036138.7808295386],[-13044354.514637273,4035719.3623426706],[-13044281.57229173,4036473.0999132735]],"spatialReference":{"wkid":3857}}
''');

    // Return graphics for each editable geometry.
    return [
      Graphic(geometry: redlandsMultipoint, symbol: markerSymbol),
      Graphic(geometry: redlandsPolygon, symbol: lineSymbol),
      Graphic(geometry: redlandsPolyline, symbol: lineSymbol),
    ];
  }
}
