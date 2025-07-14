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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class EditGeometriesWithProgrammaticReticleTool extends StatefulWidget {
  const EditGeometriesWithProgrammaticReticleTool({super.key});

  @override
  State<EditGeometriesWithProgrammaticReticleTool> createState() =>
      _EditGeometriesWithProgrammaticReticleToolState();
}

class _EditGeometriesWithProgrammaticReticleToolState
    extends State<EditGeometriesWithProgrammaticReticleTool>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a geometry editor.
  final _geometryEditor = GeometryEditor();
  // Create a programmatic reticle tool to be used by the geometry editor for editing.
  final _programmaticReticleTool = ProgrammaticReticleTool();

  // Create a graphics overlay to hold graphics created and edited by the geometry editor.
  final _graphicsOverlay = GraphicsOverlay();

  // Create a list of geometry types to make available for editing.
  final _geometryTypes = [
    GeometryType.point,
    GeometryType.multipoint,
    GeometryType.polyline,
    GeometryType.polygon,
  ];
  // The symbols used for displaying different geometry types.
  late final SimpleFillSymbol _polygonSymbol;
  late final SimpleLineSymbol _polylineSymbol;
  late final SimpleMarkerSymbol _pointSymbol;
  late final SimpleMarkerSymbol _multipointSymbol;

  // Create variables for holding state relating to the geometry editor for controlling the UI.
  Graphic? _selectedGraphic;
  GeometryType? _selectedGeometryType;
  var _allowVertexCreation = true;
  var _geometryEditorCanUndo = false;
  var _geometryEditorCanRedo = false;
  var _geometryEditorIsStarted = false;
  var _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Creates the top menu used for adjusting settings in the geometry editor.
                buildTopMenu(),
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    // Configure interactions with the map view using the onTap callback.
                    onTap: onTap,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Creates the button which controls the current action of the geometry editor.
                      Expanded(child: buildGeometryEditorActionButton()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // A bottom sheet that shows/hides settings relating to the geometry editor depending on the value of the showSettings flag.
      bottomSheet: _showSettings ? buildBottomSheet() : null,
    );
  }

  void onMapViewReady() {
    // Create a map with the imagery basemap style and set to the map view controller.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);
    _mapViewController.arcGISMap = map;

    // Configure some initial graphics and add to the graphics overlay.
    _graphicsOverlay.graphics.addAll(initialGraphics());
    // Add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Set an initial viewpoint over the graphics.
    _mapViewController.setViewpoint(
      Viewpoint.fromCenter(
        ArcGISPoint(
          x: -0.775395,
          y: 51.523806,
          spatialReference: SpatialReference(wkid: 4326),
        ),
        scale: 20000,
      ),
    );

    // Set the programmatic reticle tool as the active tool on the geometry editor.
    _geometryEditor.tool = _programmaticReticleTool;
    // Listen to changes in the geometry editor to manage the UI.
    // When the picked up element changes, we update the state.
    _geometryEditor.onPickedUpElementChanged.listen((_) => setState(() {}));
    // When the hovered element changes, we update the state.
    _geometryEditor.onHoveredElementChanged.listen((_) => setState(() {}));
    // Set the initial state of variables relating to the geometry editor.
    setState(() {
      _selectedGeometryType = GeometryType.point;
      // No UI controls update canUndo or canRedo in this sample, so we just set once.
      // Listen to the relevant events if you want to handle changes to these values.
      _geometryEditorCanUndo = _geometryEditor.canUndo;
      _geometryEditorCanRedo = _geometryEditor.canRedo;
    });
    // Set the geometry editor to the map view controller.
    _mapViewController.geometryEditor = _geometryEditor;
  }

  Future<void> onTap(Offset localPosition) async {
    if (_geometryEditorIsStarted) {
      // If the geometry editor is started, we use the identify geometry editor method at the tapped location.
      final identifyGeometryEditorResult = await _mapViewController
          .identifyGeometryEditor(screenPoint: localPosition, tolerance: 12);

      if (identifyGeometryEditorResult.elements.isNotEmpty) {
        // Get the first element from the result.
        final geometryEditorElement =
            identifyGeometryEditorResult.elements.first;
        if (geometryEditorElement is GeometryEditorVertex) {
          // If the element is a vertex, set the viewpoint to its position and select it using the vertex index.
          zoomToPoint(geometryEditorElement.point);
          _geometryEditor.selectVertex(
            partIndex: geometryEditorElement.partIndex,
            vertexIndex: geometryEditorElement.vertexIndex,
          );
        } else if (geometryEditorElement is GeometryEditorMidVertex &&
            _allowVertexCreation) {
          // If the element is a mid-vertex, set the viewpoint to its position and select it using the segment index.
          // We only select a mid-vertex if vertex creation is allowed because mid-vertices only exist in the display as a visual cue
          // to indicate new vertices can be inserted between existing vertices.
          zoomToPoint(geometryEditorElement.point);
          _geometryEditor.selectMidVertex(
            partIndex: geometryEditorElement.partIndex,
            segmentIndex: geometryEditorElement.segmentIndex,
          );
        }
      }
    } else {
      // If the geometry editor is not started, we perform an identify operation on the graphics overlays at the tapped location.
      final identifyGraphicsOverlayResult = await _mapViewController
          .identifyGraphicsOverlays(screenPoint: localPosition, tolerance: 12);

      if (identifyGraphicsOverlayResult.isNotEmpty &&
          identifyGraphicsOverlayResult.first.graphics.isNotEmpty) {
        // Get the first graphic from the first result.
        final identifiedGraphic =
            identifyGraphicsOverlayResult.first.graphics.first;
        if (identifiedGraphic.geometry != null) {
          // Select the graphic, hide it, and start an editing session with a copy of it.
          identifiedGraphic.isSelected = true;
          identifiedGraphic.isVisible = false;
          _geometryEditor.startWithGeometry(_selectedGraphic!.geometry!);
          setState(() {
            _geometryEditorIsStarted = true;
            _selectedGraphic = identifiedGraphic;
          });

          if (_allowVertexCreation) {
            // If vertex creation is allowed, set the viewpoint to the center of the selected graphic's geometry.
            zoomToPoint(_selectedGraphic!.geometry!.extent.center);
          } else {
            // Otherwise, set the viewpoint to the end point of the first part of the respective geometry.
            switch (_selectedGraphic!.geometry) {
              case final Polygon polygon:
                zoomToPoint(polygon.parts.first.endPoint!);
              case final Polyline polyline:
                zoomToPoint(polyline.parts.first.endPoint!);
              case final Multipoint multiPoint:
                zoomToPoint(multiPoint.points.last);
              case final ArcGISPoint point:
                zoomToPoint(point);
            }
          }
        }
      }
    }
  }

  // Called from the UI when finishing editing to stop the geometry editor and save the results to the map.
  void stopAndSaveEdits() {
    // Stop the geometry editor and get the resulting geometry.
    final geometry = _geometryEditor.stop();
    if (geometry != null) {
      if (_selectedGraphic != null) {
        // If there is a selected graphic, update the geometry of the graphic being edited and make it visible again.
        _selectedGraphic!.geometry = geometry;
        _selectedGraphic!.isVisible = true;
        _selectedGraphic!.isSelected = false;
      } else {
        // If there is not a selected graphic, create a new graphic based on the geometry and add it to the graphics overlay.
        final graphic = Graphic(geometry: geometry);
        // Apply a symbol to the graphic depending on the geometry type.
        final geometryType = geometry.geometryType;
        if (geometryType == GeometryType.point) {
          graphic.symbol = _pointSymbol;
        } else if (geometryType == GeometryType.multipoint) {
          graphic.symbol = _multipointSymbol;
        } else if (geometryType == GeometryType.polyline) {
          graphic.symbol = _polylineSymbol;
        } else if (geometryType == GeometryType.polygon) {
          graphic.symbol = _polygonSymbol;
        }
        _graphicsOverlay.graphics.add(graphic);
      }
    }
    // Reset the state.
    setState(() {
      _geometryEditorIsStarted = false;
      _selectedGraphic = null;
      _selectedGeometryType = null;
    });
  }

  // Called from the UI to undo edits in the geometry editor.
  void onUndo() {
    if (_geometryEditor.pickedUpElement != null) {
      // If there is a picked up element, use the cancelCurrentAction function to move the picked up geometry back to its original position before it is placed.
      _geometryEditor.cancelCurrentAction();
    } else {
      // Otherwise use the undo function to undo the last action.
      _geometryEditor.undo();
    }
  }

  // Called from the UI to redo edits in the geometry editor.
  void onRedo() {
    _geometryEditor.redo();
  }

  // Called from the UI to stop the geometry and discard all edits.
  void stopAndDiscardEdits() {
    // Stop the geometry editor and discard the geometry.
    _geometryEditor.stop();

    // Reset the state.
    _selectedGraphic?.isVisible = true;
    _selectedGraphic?.isSelected = false;
    setState(() {
      _geometryEditorIsStarted = false;
      _selectedGraphic = null;
      _selectedGeometryType = null;
    });
  }

  // Returns the relevant button to control the next programmatic action of the geometry editor based on its current state.
  ElevatedButton buildGeometryEditorActionButton() {
    if (!_geometryEditorIsStarted) {
      // If the geometry editor is not started, the button will start it.
      return ElevatedButton(
        onPressed: () {
          // Use the selected geometry type or default to using points.
          if (_selectedGeometryType == null) {
            setState(() => _selectedGeometryType = GeometryType.point);
          }
          // Start the geometry editor using the selected geometry type.
          _geometryEditor.startWithGeometryType(_selectedGeometryType!);
          setState(() => _geometryEditorIsStarted = true);
        },
        child: const Text('Start geometry editor'),
      );
    } else {
      if (_geometryEditor.pickedUpElement != null) {
        // If something is picked up - the button will drop it.
        return ElevatedButton(
          onPressed: () {
            _programmaticReticleTool.placeElementAtReticle();
            // We also update the state so that the button can redraw now that the element has been placed.
            setState(() {});
          },
          child: const Text('Drop point'),
        );
      }
      // If a hovered element exists - the button will select it and pick it up.
      if (_geometryEditor.hoveredElement is GeometryEditorVertex) {
        return ElevatedButton(
          onPressed: () {
            _programmaticReticleTool.selectElementAtReticle();
            _programmaticReticleTool.pickUpSelectedElement();
            setState(() {});
          },
          child: const Text('Pick up point'),
        );
      }
      if (_geometryEditor.hoveredElement is GeometryEditorMidVertex) {
        return ElevatedButton(
          // We only pick up a mid-vertex if vertex creation is allowed because mid-vertices only exist in the display
          // as a visual cue to indicate new vertices can be inserted between existing vertices.
          onPressed: _allowVertexCreation
              ? () {
                  _programmaticReticleTool.selectElementAtReticle();
                  _programmaticReticleTool.pickUpSelectedElement();
                  setState(() {});
                }
              : null,
          child: const Text('Pick up point'),
        );
      }
      // If there is no picked up or hovered element and vertex creation is allowed,
      // the button insers a new vertex.
      return ElevatedButton(
        onPressed: _allowVertexCreation
            ? () {
                _programmaticReticleTool.placeElementAtReticle();
                setState(() {});
              }
            : null,
        child: const Text('Insert point'),
      );
    }
  }

  // Returns a series of buttons used to control and configue the geometry editor.
  Widget buildTopMenu() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // A button to stop and discard edits.
          ElevatedButton(
            onPressed: _geometryEditorIsStarted ? stopAndDiscardEdits : null,
            child: const Text('Cancel'),
          ),
          // A button to show the settings UI.
          ElevatedButton(
            onPressed: () => setState(() => _showSettings = true),
            child: const Text('Settings'),
          ),
          // A button to stop and save edits.
          ElevatedButton(
            onPressed: _geometryEditorIsStarted ? stopAndSaveEdits : null,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // Build out a settings UI within the bottom sheet.
  Widget buildBottomSheet() {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _showSettings = false),
      settingsWidgets: (context) => [buildSettings()],
    );
  }

  // Returns a toolbar of buttons with icons for editing functions. Tooltips are used to aid the user experience.
  Widget buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        spacing: 10,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              // Create a switch with a label that toggles whether vertex creation is allowed.
              const Text('Allow vertex creation:'),
              Switch(
                value: _allowVertexCreation,
                onChanged: (value) {
                  setState(() => _allowVertexCreation = value);
                  // Update the programmatic reticle tool and geometry editor settings based on the switch state.
                  _programmaticReticleTool.vertexCreationPreviewEnabled =
                      _allowVertexCreation;
                  _programmaticReticleTool
                          .style
                          .growEffect!
                          .applyToMidVertices =
                      _allowVertexCreation;
                },
              ),
            ],
          ),
          // A drop down button for selecting geometry type. Only visible if the geometry editor is not started.
          Visibility(
            visible: !_geometryEditorIsStarted,
            child: DropdownButton(
              alignment: Alignment.center,
              hint: Text(
                'Geometry Type',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              icon: const Icon(Icons.arrow_drop_down),
              iconEnabledColor: Theme.of(context).colorScheme.primary,
              iconDisabledColor: Theme.of(context).disabledColor,
              style: Theme.of(context).textTheme.labelMedium,
              value: _selectedGeometryType,
              items: configureGeometryTypeMenuItems(),
              onChanged: (GeometryType? geometryType) {
                setState(() => _selectedGeometryType = geometryType);
              },
            ),
          ),
          // Buttons to undo or redo actions on the geometry editor.
          // Only visible if the geometry editor is started.
          Visibility(
            visible: _geometryEditorIsStarted,
            child: Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Undo',
                  child: ElevatedButton(
                    onPressed: _geometryEditorCanUndo
                        ? _geometryEditor.undo
                        : null,
                    child: const Icon(Icons.undo),
                  ),
                ),
                Tooltip(
                  message: 'Redo',
                  child: ElevatedButton(
                    onPressed: _geometryEditorCanRedo
                        ? _geometryEditor.redo
                        : null,
                    child: const Icon(Icons.redo),
                  ),
                ),
              ],
            ),
          ),
          // Button to delete the selected element.
          // Only visible if the geometry editor is started.
          Visibility(
            visible: _geometryEditorIsStarted,
            child: Tooltip(
              message: 'Delete selected element',
              child: ElevatedButton(
                onPressed:
                    _geometryEditor.selectedElement != null &&
                        _geometryEditor.selectedElement!.canDelete
                    ? _geometryEditor.deleteSelectedElement
                    : null,
                child: const Text('Delete selected'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns a list of drop down menu items for each geometry type.
  List<DropdownMenuItem<GeometryType>> configureGeometryTypeMenuItems() {
    return _geometryTypes.map((type) {
      return DropdownMenuItem(
        enabled: !_geometryEditorIsStarted,
        value: type,
        child: Text(
          type.name.capitalize(),
          style: !_geometryEditorIsStarted
              ? null
              : const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
        ),
      );
    }).toList();
  }

  // Configure initial graphics to display on the map.
  List<Graphic> initialGraphics() {
    // Create symbols for each geometry type.
    _pointSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.square,
      color: Colors.red,
      size: 10,
    );
    _multipointSymbol = SimpleMarkerSymbol(color: Colors.yellow, size: 5);
    _polylineSymbol = SimpleLineSymbol(color: Colors.blue, width: 2);
    final outlineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.dash,
      color: Colors.black,
    );
    _polygonSymbol = SimpleFillSymbol(
      color: Colors.red.withValues(alpha: 0.3),
      outline: outlineSymbol,
    );

    // Create geometries from JSON strings.
    const pinkneysGreenJson = '''
{"rings":[[[-84843.262719916485,6713749.9329888355],[-85833.376589175183,6714679.7122141244],
                    [-85406.822347959576,6715063.9827222107],[-85184.329997390232,6715219.6195847588],
                    [-85092.653857582554,6715119.5391713539],[-85090.446872787768,6714792.7656492386],
                    [-84915.369168906298,6714297.8798246197],[-84854.295522911285,6714080.907587287],
                    [-84843.262719916485,6713749.9329888355]]],"spatialReference":{"wkid":102100,"latestWkid":3857}}''';
    final pinkneysGreenGeometry = Geometry.fromJsonString(pinkneysGreenJson);

    const beechLodgeBoundaryJson = '''
{"paths":[[[-87090.652708065536,6714158.9244240439],[-87247.362370337316,6714232.880689906],
                    [-87226.314032974493,6714605.4697726099],[-86910.499335316243,6714488.006312645],
                    [-86750.82198052686,6714401.1768307304],[-86749.846825938366,6714305.8450344801]]],"spatialReference":{"wkid":102100,"latestWkid":3857}}''';
    final beechLodgeBoundaryGeometry = Geometry.fromJsonString(
      beechLodgeBoundaryJson,
    );

    const treeMarkersJson = '''
{"points":[[-86750.751150056443,6713749.4529355941],[-86879.381793060631,6713437.3335486846],
                    [-87596.503104619667,6714381.7342108283],[-87553.257569537804,6714402.0910389507],
                    [-86831.019903597829,6714398.4128562529],[-86854.105933315877,6714396.1957954112],
                    [-86800.624094892439,6713992.3374453448]],"spatialReference":{"wkid":102100,"latestWkid":3857}}''';
    final treeMarkersGeometry = Geometry.fromJsonString(treeMarkersJson);

    // Return a list of graphics for each geometry type.
    return [
      Graphic(geometry: pinkneysGreenGeometry, symbol: _polygonSymbol),
      Graphic(geometry: beechLodgeBoundaryGeometry, symbol: _polylineSymbol),
      Graphic(geometry: treeMarkersGeometry, symbol: _multipointSymbol),
    ];
  }

  // Zooms to the provided point using the current map scale.
  void zoomToPoint(ArcGISPoint point) {
    unawaited(
      _mapViewController.setViewpointAnimated(
        Viewpoint.fromCenter(point, scale: _mapViewController.scale),
      ),
    );
  }
}

extension on String {
  // An extension on String to capitalize the first character of the String.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
