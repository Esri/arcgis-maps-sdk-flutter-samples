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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddFeaturesWithContingentValues extends StatefulWidget {
  const AddFeaturesWithContingentValues({super.key});

  @override
  State<AddFeaturesWithContingentValues> createState() =>
      _AddFeaturesWithContingentValuesState();
}

class _AddFeaturesWithContingentValuesState
    extends State<AddFeaturesWithContingentValues>
    with SampleStateSupport {
  // Controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the local map view is ready and controls can be used.
  var _ready = false;

  // A flag for when the bottom sheet is visible.
  var _sheetVisible = false;

  // Downloaded local resource paths.
  String? _geodatabasePath;
  String? _vtpkPath;

  // Contingent values birds nests geodatabase.
  late final Geodatabase _geodatabase;

  // Bird Nests Feature Table.
  late final ArcGISFeatureTable _birdNestsTable;

  // Persisted buffers (queried from table where BufferSize > 0).
  final _bufferOverlay = GraphicsOverlay();

  // Draft graphics shown while user is editing a new feature.
  final _draftOverlay = GraphicsOverlay();

  // Draft point marker graphic for the tap location.
  Graphic? _draftPointGraphic;

  // Draft buffer graphic shown while the slider changes.
  Graphic? _draftBufferGraphic;

  // Draft feature used when adding a new feature and is either discarded or added to the table while editing.
  ArcGISFeature? _draftFeature;

  // Draft Symbols.
  late final SimpleMarkerSymbol _draftPointSymbol;
  late final SimpleFillSymbol _draftFillSymbol;

  // Status options from coded value domain.
  List<CodedValue> _statusOptions = const [];

  // Currently selected status coded value.
  CodedValue? _selectedStatus;

  // Protection options (names) based on contingent values for the current draft.
  List<String> _protectionOptions = const [];

  // Currently selected protection name.
  String? _selectedProtectionName;

  // Buffer range derived from contingent range values.
  int _bufferMin = 0;
  int _bufferMax = 0;

  // Currently selected buffer size.
  int? _selectedBufferSize;

  // Whether the current draft selections satisfy all contingencies.
  var _isValid = false;

  // Constants for table/field names.
  static const _tableName = 'BirdNests';

  static const _fieldStatus = 'Status';
  static const _fieldProtection = 'Protection';
  static const _fieldBufferSize = 'BufferSize';

  static const _protectionGroup = 'ProtectionFieldGroup';
  static const _bufferGroup = 'BufferSizeFieldGroup';

  @override
  void initState() {
    super.initState();
    _initDownloadResources();
  }

  // Reads the resolved file paths passed via GoRouter extras.
  void _initDownloadResources() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _geodatabasePath = listPaths[0];
    _vtpkPath = listPaths[1];
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
            // Add a map view to the widget tree and set a controller.
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: _onMapViewReady,
              onTap: _onTap,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // Show the settings as a bottom sheet when the map is tapped.
      bottomSheet: _sheetVisible ? _buildBottomSheet(context) : null,
    );
  }

  Future<void> _onMapViewReady() async {
    // Create a vector tiled layer from a local file.
    final vtpkPath = _vtpkPath;
    if (vtpkPath == null) return;
    final vtpkLayer = ArcGISVectorTiledLayer.withUri(Uri.file(vtpkPath));

    // Create a basemap using the vector tiled layer and set to a map.
    final basemap = Basemap.withBaseLayer(vtpkLayer);
    final map = ArcGISMap.withBasemap(basemap);
    // Set the map to the controller.
    _mapViewController.arcGISMap = map;

    // Load the geodatabase and configure the table and contingent values definition.
    await _configureData();

    // Add feature layer to map.
    final featureLayer = FeatureLayer.withFeatureTable(_birdNestsTable);
    await featureLayer.load();
    map.operationalLayers.add(featureLayer);

    // Configure overlays.
    _configureBufferOverlay(); // persisted buffers
    _configureDraftOverlay(); // draft point + draft buffer
    _mapViewController.graphicsOverlays
      ..add(_bufferOverlay)
      ..add(_draftOverlay);

    // Load static domain options.
    _loadStatusOptions();

    // Draw existing persisted buffer graphics.
    await _refreshPersistedBuffers();

    // Zoom to feature layer extent.
    await _mapViewController.setViewpointGeometry(
      featureLayer.fullExtent!,
      paddingInDiPs: -20,
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> _configureData() async {
    final gdbPath = _geodatabasePath;
    if (gdbPath == null) return;

    // Create and load a geodatabase from a local file.
    _geodatabase = Geodatabase.withFileUri(File(gdbPath).uri);
    await _geodatabase.load();

    final table = _geodatabase.getGeodatabaseFeatureTable(
      tableName: _tableName,
    );

    if (table == null) return;

    // Contingent values require the definition to be loaded.
    await table.contingentValuesDefinition.load();

    _birdNestsTable = table;
  }

  // OnTap starts the draft edit session.
  Future<void> _onTap(Offset offset) async {
    if (!_ready) return;

    // Convert screen point to map point.
    final mapPoint = _mapViewController.screenToLocation(screen: offset);
    if (mapPoint == null) return;

    // Shift the viewpoint upward so the point is visible above the bottom sheet.
    final screenPoint = offset.translate(0, 200);
    final adjustedLocation = _mapViewController.screenToLocation(
      screen: screenPoint,
    );

    if (adjustedLocation != null) {
      await _mapViewController.setViewpointCenter(adjustedLocation);
    }

    // Create a draft feature (not inserted into the table yet).
    final draft =
        _birdNestsTable.createFeature(
              attributes: <String, dynamic>{},
              geometry: mapPoint,
            )
            as ArcGISFeature;

    // Reset all editor state and show bottom sheet.
    _startDraftEditing(draft);
  }

  // Starts editing a draft feature and shows the editor sheet.
  void _startDraftEditing(ArcGISFeature draft) {
    setState(() {
      _draftFeature = draft;

      _selectedStatus = null;
      _protectionOptions = const [];
      _selectedProtectionName = null;

      _bufferMin = 0;
      _bufferMax = 0;
      _selectedBufferSize = null;

      _isValid = false;
      _sheetVisible = true;
    });

    // Show a draft point marker at the tapped geometry.
    _showDraftPointGraphic();
    // Clear any prior draft buffer.
    _clearDraftBufferGraphic();
  }

  void _configureBufferOverlay() {
    // Persisted buffers: red diagonal fill with black outline.
    final outline = SimpleLineSymbol(color: const Color(0xFF000000), width: 2);

    final fill = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.forwardDiagonal,
      color: const Color(0xFFFF0000),
      outline: outline,
    );

    _bufferOverlay.renderer = SimpleRenderer(symbol: fill);
  }

  void _configureDraftOverlay() {
    // Draft point symbol (tap location).
    _draftPointSymbol = SimpleMarkerSymbol(
      color: const Color(0xFF000000),
      size: 11,
    );

    // Draft buffer symbol (same visual style as persisted buffers).
    final outline = SimpleLineSymbol(color: const Color(0xFF000000), width: 2);

    _draftFillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.forwardDiagonal,
      color: const Color(0xFFFF0000),
      outline: outline,
    );
  }

  void _showDraftPointGraphic() {
    final feature = _draftFeature;
    final geom = feature?.geometry;
    if (geom == null) return;

    // Remove any existing draft point graphic first.
    if (_draftPointGraphic != null) {
      _draftOverlay.graphics.remove(_draftPointGraphic);
      _draftPointGraphic = null;
    }

    final g = Graphic(geometry: geom, symbol: _draftPointSymbol);
    _draftOverlay.graphics.add(g);
    _draftPointGraphic = g;
  }

  // Removes the graphic from the graphics overlay and resets the state.
  void _clearDraftPointGraphic() {
    if (_draftPointGraphic != null) {
      _draftOverlay.graphics.remove(_draftPointGraphic);
      _draftPointGraphic = null;
    }
  }

  void _clearDraftBufferGraphic() {
    if (_draftBufferGraphic != null) {
      _draftOverlay.graphics.remove(_draftBufferGraphic);
      _draftBufferGraphic = null;
    }
  }

  // Clears the graphics overlay and resets the draft graphic variables.
  void _clearDraftGraphics() {
    _draftOverlay.graphics.clear();
    _draftPointGraphic = null;
    _draftBufferGraphic = null;
  }

  // Updates the draft buffer graphic to match the current BufferSize.
  void _updateDraftBufferGraphic(double distance) {
    final feature = _draftFeature;
    final geom = feature?.geometry;
    if (geom == null) return;

    if (distance <= 0) {
      _clearDraftBufferGraphic();
      return;
    }

    final buffer = GeometryEngine.buffer(geometry: geom, distance: distance);

    if (_draftBufferGraphic == null) {
      final g = Graphic(geometry: buffer, symbol: _draftFillSymbol);
      _draftOverlay.graphics.add(g);
      _draftBufferGraphic = g;
    } else {
      _draftBufferGraphic!.geometry = buffer;
    }
  }

  // Domain + contingent values
  // Loads the Status field's coded value domain options.
  void _loadStatusOptions() {
    try {
      final statusField = _birdNestsTable.fields.firstWhere(
        (f) => f.name == _fieldStatus,
      );

      final domain = statusField.domain;
      if (domain is CodedValueDomain) {
        // Store options once. Bottom sheet will read from this list.
        _statusOptions = domain.codedValues;
      }
    } on Exception catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load status options.')),
      );
    }
  }

  // Refresh contingent Protection dropdown options based on the draft feature.
  Future<void> _refreshProtectionOptions() async {
    final feature = _draftFeature;
    if (feature == null) return;

    final result = _birdNestsTable.getContingentValues(
      feature: feature,
      field: _fieldProtection,
    );

    final values =
        result.contingentValuesByFieldGroup[_protectionGroup] ?? const [];

    final names = <String>[];
    for (final v in values) {
      if (v is ContingentCodedValue) {
        names.add(v.codedValue.name);
      }
    }

    setState(() {
      _protectionOptions = names;
    });
  }

  // Applies the selected protection name to the draft feature attribute map.
  void _applyProtectionByName(String name) {
    final feature = _draftFeature;
    if (feature == null) return;

    final result = _birdNestsTable.getContingentValues(
      feature: feature,
      field: _fieldProtection,
    );

    final values =
        result.contingentValuesByFieldGroup[_protectionGroup] ?? const [];

    for (final v in values) {
      if (v is ContingentCodedValue && v.codedValue.name == name) {
        feature.attributes[_fieldProtection] = v.codedValue.code;
        return;
      }
    }
  }

  // Refreshes buffer min/max range based on contingent range values.
  Future<void> _refreshBufferRange() async {
    final feature = _draftFeature;
    if (feature == null) return;

    final result = _birdNestsTable.getContingentValues(
      feature: feature,
      field: _fieldBufferSize,
    );

    final values =
        result.contingentValuesByFieldGroup[_bufferGroup] ?? const [];

    var minV = 0;
    var maxV = 0;

    for (final v in values) {
      if (v is ContingentRangeValue) {
        minV = (v.minValue as num).toInt();
        maxV = (v.maxValue as num).toInt();
        break;
      }
    }

    setState(() {
      _bufferMin = minV;
      _bufferMax = maxV;
    });

    // If range collapses to a single value, auto-set it and update draft buffer.
    if (minV == maxV) {
      feature.attributes[_fieldBufferSize] = minV;
      setState(() => _selectedBufferSize = minV);
      _updateDraftBufferGraphic(minV.toDouble());
      _validateDraft();
    }
  }

  // Validates contingent constraints for the current draft feature.
  void _validateDraft() {
    final feature = _draftFeature;
    if (feature == null) return;

    final violations = _birdNestsTable.validateContingencyConstraints(
      feature: feature,
    );
    final ok = violations.isEmpty;

    setState(() => _isValid = ok);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid contingent values')),
      );
    }
  }

  // Refreshes all persisted buffer graphics by querying features with BufferSize > 0.
  Future<void> _refreshPersistedBuffers() async {
    _bufferOverlay.graphics.clear();

    final params = QueryParameters()..whereClause = '$_fieldBufferSize > 0';

    try {
      final result = await _birdNestsTable.queryFeatures(params);

      for (final feature in result.features()) {
        final bufferSize = feature.attributes[_fieldBufferSize] as num?;
        if (bufferSize == null || bufferSize <= 0 || feature.geometry == null) {
          continue;
        }

        final buffer = GeometryEngine.buffer(
          geometry: feature.geometry!,
          distance: bufferSize.toDouble(),
        );

        _bufferOverlay.graphics.add(Graphic(geometry: buffer));
      }
    } on Exception catch (e) {
      debugPrint('Error refreshing persisted buffers: $e');
    }
  }

  Future<void> _saveAndClose() async {
    final feature = _draftFeature;
    if (feature == null) return;

    // Ensure final validation passed.
    _validateDraft();
    if (!_isValid) return;

    try {
      // Add to the table.
      await _birdNestsTable.addFeature(feature);

      // Refresh persisted buffers so the saved feature appears in the overlay.
      await _refreshPersistedBuffers();

      // Clear draft UI and dismiss.
      _endDraftEditing(dismissSheet: true);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save feature: $e')));
    }
  }

  void _discardAndClose() {
    // Draft-only: just clear graphics and reset state.
    _endDraftEditing(dismissSheet: true);
  }

  // Ends draft editing by clearing draft graphics and resetting draft state.
  void _endDraftEditing({required bool dismissSheet}) {
    _clearDraftGraphics();

    setState(() {
      _draftFeature = null;

      _selectedStatus = null;
      _protectionOptions = const [];
      _selectedProtectionName = null;

      _bufferMin = 0;
      _bufferMax = 0;
      _selectedBufferSize = null;

      _isValid = false;

      if (dismissSheet) {
        _sheetVisible = false;
      }
    });
  }

  // Bottom sheet UI.
  Widget _buildBottomSheet(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: _discardAndClose,
      settingsWidgets: (context) => [
        Text('Add Bird Nest', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        // Status (coded value domain).
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<CodedValue?>(
          isExpanded: true,
          value: _selectedStatus,
          hint: const Text('Select status'),
          items: [
            const DropdownMenuItem<CodedValue?>(child: Text('')),
            ..._statusOptions.map(
              (cv) => DropdownMenuItem<CodedValue?>(
                value: cv,
                child: Text(cv.name),
              ),
            ),
          ],
          onChanged: (cv) async {
            final feature = _draftFeature;
            if (feature == null) return;

            if (cv == null) {
              // Reset only selection-dependent state (keep draft feature + point).
              setState(() {
                _selectedStatus = null;
                _protectionOptions = const [];
                _selectedProtectionName = null;
                _bufferMin = 0;
                _bufferMax = 0;
                _selectedBufferSize = null;
                _isValid = false;
              });
              _clearDraftBufferGraphic();
              return;
            }

            setState(() {
              _selectedStatus = cv;
              _protectionOptions = const [];
              _selectedProtectionName = null;
              _bufferMin = 0;
              _bufferMax = 0;
              _selectedBufferSize = null;
              _isValid = false;
            });

            // Apply status code to draft attributes.
            feature.attributes[_fieldStatus] = cv.code;

            // Refresh next field options.
            await _refreshProtectionOptions();
          },
        ),
        const SizedBox(height: 12),

        // Protection (contingent coded values).
        Text('Protection', style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<String?>(
          isExpanded: true,
          value: _selectedProtectionName,
          hint: const Text('Select protection'),
          items: [
            const DropdownMenuItem<String?>(child: Text('')),
            ..._protectionOptions.map(
              (name) =>
                  DropdownMenuItem<String?>(value: name, child: Text(name)),
            ),
          ],
          onChanged: (_selectedStatus == null)
              ? null
              : (name) async {
                  final feature = _draftFeature;
                  if (feature == null) return;
                  if (name == null) return;

                  setState(() {
                    _selectedProtectionName = name;
                    _bufferMin = 0;
                    _bufferMax = 0;
                    _selectedBufferSize = null;
                    _isValid = false;
                  });

                  // Apply protection code to draft attributes.
                  _applyProtectionByName(name);

                  // Refresh buffer range options.
                  await _refreshBufferRange();
                },
        ),
        const SizedBox(height: 12),

        // Buffer size (contingent range values) and buffer preview.
        Text('Buffer Size', style: Theme.of(context).textTheme.titleMedium),
        Text('$_bufferMin to $_bufferMax'),
        Slider(
          value: (_selectedBufferSize ?? _bufferMin).toDouble().clamp(
            _bufferMin.toDouble(),
            _bufferMax.toDouble(),
          ),
          min: _bufferMin.toDouble(),
          max: (_bufferMax == 0 ? 1 : _bufferMax).toDouble(),
          divisions: (_bufferMax - _bufferMin).abs() == 0
              ? 1
              : (_bufferMax - _bufferMin).abs(),
          label: (_selectedBufferSize ?? _bufferMin).toString(),
          onChanged: (_selectedProtectionName == null || _bufferMax == 0)
              ? null
              : (value) {
                  final feature = _draftFeature;
                  if (feature == null) return;

                  final intVal = value.round();

                  setState(() {
                    _selectedBufferSize = intVal;
                    _isValid = false;
                  });

                  // Apply buffer size to draft attributes.
                  feature.attributes[_fieldBufferSize] = intVal;

                  // Update the draft buffer graphic as the slider changes.
                  _updateDraftBufferGraphic(intVal.toDouble());

                  // Validate contingent constraints.
                  _validateDraft();
                },
        ),
        const SizedBox(height: 12),

        // Buttons to either discard or save feature edits.
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _discardAndClose,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isValid ? _saveAndClose : null,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
