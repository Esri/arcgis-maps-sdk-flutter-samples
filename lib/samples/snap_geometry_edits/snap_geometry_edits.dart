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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class SnapGeometryEdits extends StatefulWidget {
  const SnapGeometryEdits({super.key});

  @override
  State<SnapGeometryEdits> createState() => _SnapGeometryEditsState();
}

class _SnapGeometryEditsState extends State<SnapGeometryEdits>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a graphics overlay.
  final _graphicsOverlay = GraphicsOverlay();
  // Create a geometry editor.
  final _geometryEditor = GeometryEditor();
  // Create a geometry editor style for accessing symbol styles.
  final _geometryEditorStyle = GeometryEditorStyle();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Create a list of menu items for each geometry type.
  final _geometryTypeMenuItems = <DropdownMenuItem<GeometryType>>[];

  // Create a selection of tools to make available to the geometry editor.
  final _vertexTool = VertexTool();
  final _reticleVertexTool = ReticleVertexTool();
  final _toolMenuItems = <DropdownMenuItem<GeometryEditorTool>>[];

  // Create lists to hold different types of snap source settings to make available to the geometry editor.
  final _pointLayerSnapSources = <SnapSourceSettings>[];
  final _polylineLayerSnapSources = <SnapSourceSettings>[];
  final _graphicsOverlaySnapSources = <SnapSourceSettings>[];

  // Create variables for holding state relating to the geometry editor for controlling the UI.
  GeometryType? _selectedGeometryType;
  GeometryEditorTool? _selectedTool;
  Graphic? _selectedGraphic;
  // Initial values are based on defaults.
  var _geometryEditorCanUndo = false;
  var _geometryEditorIsStarted = false;
  var _geometryEditorHasSelectedElement = false;
  var _snappingEnabled = false;
  var _geometryGuidesEnabled = false;
  var _featureSnappingEnabled = true;

  // A flag for controlling the visibility of the editing toolbar.
  var _showEditToolbar = true;
  // A flag for controlling the visibility of the snap settings.
  var _snapSettingsVisible = false;

  // A custom style for when the editing toolbar buttons are not enabled.
  final _buttonStyle = ElevatedButton.styleFrom(
    disabledBackgroundColor: Colors.white.withOpacity(0.6),
  );

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
                    // Only select existing graphics to edit if the geometry editor is not started
                    // i.e. editing is not already in progress.
                    onTap: !_geometryEditorIsStarted ? onTap : null,
                  ),
                ),
                // Build the bottom menu.
                buildBottomMenu(),
              ],
            ),
            Visibility(
              visible: _showEditToolbar,
              // Build the editing toolbar.
              child: buildEditingToolbar(),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // The snap settings bottom sheet.
      bottomSheet: _snapSettingsVisible ? buildSnapSettings(context) : null,
    );
  }

  void onMapViewReady() async {
    // Create a map with a URL to a web map.
    const webMapUri =
        'https://www.arcgis.com/home/item.html?id=b95fe18073bc4f7788f0375af2bb445e';
    final map = ArcGISMap.withUri(Uri.parse(webMapUri));
    if (map != null) {
      // Set the feature tiling mode on the map.
      // Snapping is used to maintain data integrity between different sources of data when editing,
      // so full resolution is needed for valid snapping.
      map.loadSettings.featureTilingMode =
          FeatureTilingMode.enabledWithFullResolutionWhenSupported;

      // Set the map to the map view controller.
      _mapViewController.arcGISMap = map;

      // Add the graphics overlay to the map view.
      _mapViewController.graphicsOverlays.add(_graphicsOverlay);

      // Do some initial configuration of the geometry editor.
      // Initially set the created reticle vertex tool as the current tool.
      // Note that the reticle vertex tool makes visibility of snapping easier on touchscreen devices.
      setState(() => _selectedTool = _reticleVertexTool);
      _geometryEditor.tool = _reticleVertexTool;
      // Listen to changes in canUndo in order to enable/disable the UI.
      _geometryEditor.onCanUndoChanged.listen(
        (canUndo) => setState(() => _geometryEditorCanUndo = canUndo),
      );
      // Listen to changes in isStarted in order to enable/disable the UI.
      _geometryEditor.onIsStartedChanged.listen(
        (isStarted) => setState(() => _geometryEditorIsStarted = isStarted),
      );
      // Listen to changes in the selected element in order to enable/disable the UI.
      _geometryEditor.onSelectedElementChanged.listen(
        (selectedElement) => setState(
          () => _geometryEditorHasSelectedElement = selectedElement != null,
        ),
      );

      // Set the geometry editor to the map view controller.
      _mapViewController.geometryEditor = _geometryEditor;

      // Ensure the map and each layer loads in order to synchronize snap settings.
      await map.load();
      await Future.wait(map.operationalLayers.map((layer) => layer.load()));

      // Sync snap settings.
      synchronizeSnapSettings();

      // Configure menu items for selecting tools and geometry types.
      _toolMenuItems.addAll(configureToolMenuItems());
      _geometryTypeMenuItems.addAll(configureGeometryTypeMenuItems());

      // Set the ready state variable to true to enable the sample UI.
      setState(() => _ready = true);
    }
  }

  void onTap(Offset localPosition) async {
    // Perform an identify operation on the graphics overlay at the tapped location.
    final identifyResult = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 12.0,
    );

    // Get the graphics from the identify result.
    final graphics = identifyResult.graphics;
    if (graphics.isNotEmpty) {
      final graphic = graphics.first;
      if (graphic.geometry != null) {
        final geometry = graphic.geometry!;
        // Hide the selected graphic so that only the version of the graphic that is being edited is visible.
        graphic.isVisible = false;
        // Set the graphic as the selected graphic and also set the selected geometry type to update the UI.
        _selectedGraphic = graphic;
        setState(() => _selectedGeometryType = geometry.geometryType);
        // Start the geometry editor using the geometry of the graphic.
        _geometryEditor.startWithGeometry(geometry);
      }
    }
  }

  void synchronizeSnapSettings() {
    // Synchronize the snap source collection with the map's operational layers.
    _geometryEditor.snapSettings.syncSourceSettings();
    // Enable snapping on the geometry editor.
    _geometryEditor.snapSettings.isEnabled = true;
    setState(() => _snappingEnabled = true);
    // Enable geometry guides on the geometry editor.
    _geometryEditor.snapSettings.isGeometryGuidesEnabled = true;
    setState(() => _geometryGuidesEnabled = true);
    // Create a list of snap source settings for each geometry type and graphics overlay.
    for (final sourceSettings in _geometryEditor.snapSettings.sourceSettings) {
      // Enable all the source settings initially.
      setState(() => sourceSettings.isEnabled = true);
      if (sourceSettings.source is FeatureLayer) {
        final featureLayer = sourceSettings.source as FeatureLayer;
        if (featureLayer.featureTable != null) {
          final geometryType = featureLayer.featureTable!.geometryType;
          if (geometryType == GeometryType.point) {
            _pointLayerSnapSources.add(sourceSettings);
          } else if (geometryType == GeometryType.polyline) {
            _polylineLayerSnapSources.add(sourceSettings);
          }
        }
      } else if (sourceSettings.source is GraphicsOverlay) {
        _graphicsOverlaySnapSources.add(sourceSettings);
      }
    }
  }

  void startEditingWithGeometryType(GeometryType geometryType) {
    // Set the selected geometry type and start editing.
    setState(() => _selectedGeometryType = geometryType);
    _geometryEditor.startWithGeometryType(geometryType);
  }

  void stopAndSave() {
    // Get the geometry from the geometry editor.
    final geometry = _geometryEditor.stop();

    if (geometry != null) {
      if (_selectedGraphic != null) {
        // If there was a selected graphic being edited, update it.
        _selectedGraphic!.geometry = geometry;
        _selectedGraphic!.isVisible = true;
        // Reset the selected graphic to null.
        _selectedGraphic = null;
      } else {
        // If there was no existing graphic, create a new one and add to the graphics overlay.
        final graphic = Graphic(geometry: geometry);
        // Apply a symbol to the graphic from the geometry editor style depending on the geometry type.
        final geometryType = geometry.geometryType;
        if (geometryType == GeometryType.point ||
            geometryType == GeometryType.multipoint) {
          graphic.symbol = _geometryEditorStyle.vertexSymbol;
        } else if (geometryType == GeometryType.polyline) {
          graphic.symbol = _geometryEditorStyle.lineSymbol;
        } else if (geometryType == GeometryType.polygon) {
          graphic.symbol = _geometryEditorStyle.fillSymbol;
        }
        _graphicsOverlay.graphics.add(graphic);
      }
    }

    // Reset the selected geometry type to null.
    setState(() => _selectedGeometryType = null);
  }

  void stopAndDiscardEdits() {
    // Stop the geometry editor. No need to capture the geometry as we are discarding.
    _geometryEditor.stop();
    if (_selectedGraphic != null) {
      // If editing a previously existing geometry, reset the selectedGraphic.
      _selectedGraphic!.isVisible = true;
      _selectedGraphic = null;
    }
    // Reset the selected geometry type.
    setState(() => _selectedGeometryType = null);
  }

  Widget buildBottomMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // A drop down button for selecting geometry type.
        DropdownButton(
          alignment: Alignment.center,
          hint: const Text(
            'Geometry Type',
            style: TextStyle(
              color: Colors.deepPurple,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          iconEnabledColor: Colors.deepPurple,
          iconDisabledColor: Colors.grey,
          style: const TextStyle(color: Colors.deepPurple),
          value: _selectedGeometryType,
          items: _geometryTypeMenuItems,
          // If the geometry editor is already started then we fully disable the DropDownButton and prevent editing with another geometry type.
          onChanged: !_geometryEditorIsStarted
              ? (GeometryType? geometryType) {
                  if (geometryType != null) {
                    startEditingWithGeometryType(geometryType);
                  }
                }
              : null,
        ),
        // A drop down button for selecting a tool.
        DropdownButton(
          alignment: Alignment.center,
          hint: const Text(
            'Tool',
            style: TextStyle(color: Colors.deepPurple),
          ),
          iconEnabledColor: Colors.deepPurple,
          style: const TextStyle(color: Colors.deepPurple),
          value: _selectedTool,
          items: _toolMenuItems,
          onChanged: (tool) {
            if (tool != null) {
              setState(() => _selectedTool = tool);
              _geometryEditor.tool = tool;
            }
          },
        ),
        // A button to toggle the visibility of the editing toolbar.
        IconButton(
          onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
          icon: const Icon(Icons.edit, color: Colors.deepPurple),
        ),
      ],
    );
  }

  Widget buildEditingToolbar() {
    // A toolbar of buttons with icons for editing functions. Tooltips are used to aid the user experience.
    return Padding(
      padding: const EdgeInsets.only(bottom: 100, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // A button to toggle the visibility of the snap settings.
              ElevatedButton(
                style: _buttonStyle,
                onPressed: () => setState(() => _snapSettingsVisible = true),
                child: const Text('Show snap settings'),
              ),
              Row(
                children: [
                  // A button to call undo on the geometry editor, if enabled.
                  Tooltip(
                    message: 'Undo',
                    child: ElevatedButton(
                      style: _buttonStyle,
                      onPressed:
                          _geometryEditorIsStarted && _geometryEditorCanUndo
                              ? () => _geometryEditor.undo()
                              : null,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // A button to delete the selected element on the geometry editor.
                  Tooltip(
                    message: 'Delete selected element',
                    child: ElevatedButton(
                      style: _buttonStyle,
                      onPressed: _geometryEditorIsStarted &&
                              _geometryEditorHasSelectedElement &&
                              _geometryEditor.selectedElement != null &&
                              _geometryEditor.selectedElement!.canDelete
                          ? () => _geometryEditor.deleteSelectedElement()
                          : null,
                      child: const Icon(Icons.clear),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // A button to stop and save edits.
                  Tooltip(
                    message: 'Stop and save edits',
                    child: ElevatedButton(
                      style: _buttonStyle,
                      onPressed: _geometryEditorIsStarted ? stopAndSave : null,
                      child: const Icon(Icons.save),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // A button to stop the geometry editor and discard all edits.
                  Tooltip(
                    message: 'Stop and discard edits',
                    child: ElevatedButton(
                      style: _buttonStyle,
                      onPressed:
                          _geometryEditorIsStarted ? stopAndDiscardEdits : null,
                      child: const Icon(Icons.not_interested_sharp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSnapSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _snapSettingsVisible = false),
      settingsWidgets: (context) => [
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            maxWidth: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Snap Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Add a checkbox to toggle all snapping options.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable all'),
                        Checkbox(
                          value: _snappingEnabled &&
                              _geometryGuidesEnabled &&
                              _featureSnappingEnabled,
                          onChanged: (allEnabled) {
                            if (allEnabled != null) {
                              _geometryEditor.snapSettings.isEnabled =
                                  allEnabled;
                              _geometryEditor.snapSettings
                                  .isGeometryGuidesEnabled = allEnabled;
                              _geometryEditor.snapSettings
                                  .isFeatureSnappingEnabled = allEnabled;
                              setState(() {
                                _snappingEnabled = allEnabled;
                                _geometryGuidesEnabled = allEnabled;
                                _featureSnappingEnabled = allEnabled;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether snapping is enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Snapping enabled'),
                    Checkbox(
                      value: _snappingEnabled,
                      onChanged: (snappingEnabled) {
                        if (snappingEnabled != null) {
                          _geometryEditor.snapSettings.isEnabled =
                              snappingEnabled;
                          setState(() => _snappingEnabled = snappingEnabled);
                        }
                      },
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether geometry guides are enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Geometry guides'),
                    Checkbox(
                      value: _geometryGuidesEnabled,
                      onChanged: (geometryGuidesEnabled) {
                        if (geometryGuidesEnabled != null) {
                          _geometryEditor.snapSettings.isGeometryGuidesEnabled =
                              geometryGuidesEnabled;
                          setState(
                            () =>
                                _geometryGuidesEnabled = geometryGuidesEnabled,
                          );
                        }
                      },
                    ),
                  ],
                ),
                // Add a checkbox to toggle whether feature snapping is enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Feature snapping'),
                    Checkbox(
                      value: _featureSnappingEnabled,
                      onChanged: (featureSnappingEnabled) {
                        if (featureSnappingEnabled != null) {
                          _geometryEditor
                                  .snapSettings.isFeatureSnappingEnabled =
                              featureSnappingEnabled;
                          setState(
                            () => _featureSnappingEnabled =
                                featureSnappingEnabled,
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Select snap sources',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Add checkboxes for enabling the point layers as snap sources.
                buildSnapSourcesSelection(
                  'Point layers',
                  _pointLayerSnapSources,
                ),
                // Add checkboxes for the polyline layers as snap sources.
                buildSnapSourcesSelection(
                  'Polyline layers',
                  _polylineLayerSnapSources,
                ),
                // Add checkboxes for the graphics overlay as snap sources.
                buildSnapSourcesSelection(
                  'Graphics Overlay',
                  _graphicsOverlaySnapSources,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSnapSourcesSelection(
    String label,
    List<SnapSourceSettings> allSourceSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                const Text('Enable all'),
                // A checkbox to enable all source settings in the category.
                Checkbox(
                  value: allSourceSettings.every(
                    (snapSourceSettings) => snapSourceSettings.isEnabled,
                  ),
                  onChanged: (allEnabled) {
                    if (allEnabled != null) {
                      allSourceSettings
                          .map(
                            (snapSourceSettings) => setState(
                              () => snapSourceSettings.isEnabled = allEnabled,
                            ),
                          )
                          .toList();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        Column(
          children: allSourceSettings.map((sourceSetting) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display the layer name, or set default text for graphics overlay.
                Text(
                  allSourceSettings == _pointLayerSnapSources ||
                          allSourceSettings == _polylineLayerSnapSources
                      ? (sourceSetting.source as FeatureLayer).name
                      : 'Editor Graphics Overlay',
                ),
                // A checkbox to toggle whether this source setting is enabled.
                Checkbox(
                  value: sourceSetting.isEnabled,
                  onChanged: (isEnabled) {
                    if (isEnabled != null) {
                      setState(() => sourceSetting.isEnabled = isEnabled);
                    }
                  },
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<DropdownMenuItem<GeometryType>> configureGeometryTypeMenuItems() {
    // Create a list of geometry types to make available for editing.
    final geometryTypes = [
      GeometryType.point,
      GeometryType.multipoint,
      GeometryType.polyline,
      GeometryType.polygon,
    ];
    // Returns a list of drop down menu items for each geometry type.
    return geometryTypes
        .map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(type.name.capitalize()),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<GeometryEditorTool>> configureToolMenuItems() {
    // Returns a list of drop down menu items for the required tools.
    return [
      DropdownMenuItem(
        value: _vertexTool,
        child: const Text('Vertex Tool'),
      ),
      DropdownMenuItem(
        value: _reticleVertexTool,
        child: const Text('Reticle Vertex Tool'),
      ),
    ];
  }
}

extension on String {
  // An extension on String to capitalize the first character of the String.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
