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
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Contingent values birds nests geodatabase.
  late final Geodatabase _geodatabase;

  // Feature table with contingent values definitions.
  late final ArcGISFeatureTable _featureTable;

  // Graphics overlay for buffer visualization.
  final _graphicsOverlay = GraphicsOverlay();

  // Current feature being edited.
  ArcGISFeature? _currentFeature;

  // UI state.
  var _ready = false;
  var _showAddFeatureSheet = false;

  // Attribute selections.
  String? _selectedStatus;
  String? _selectedProtection;
  int _selectedBufferSize = 0;

  // Available options.
  List<CodedValue> _statusOptions = [];
  List<String> _protectionOptionNames = [];
  int _minBufferSize = 0;
  int _maxBufferSize = 0;

  // Validation state.
  var _isValid = false;

  // Field group names.
  static const _protectionFieldGroup = 'ProtectionFieldGroup';
  static const _bufferSizeFieldGroup = 'BufferSizeFieldGroup';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
              onTap: onTap,
            ),
            if (!_ready) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      bottomSheet: _showAddFeatureSheet ? _buildAddFeatureSheet(context) : null,
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Load the geodatabase and feature table.
    await _loadGeodatabase();

    // Create a feature layer and add it to the map.
    final featureLayer = FeatureLayer.withFeatureTable(_featureTable);
    map.operationalLayers.add(featureLayer);

    // Configure graphics overlay for buffers.
    _configureGraphicsOverlay();
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Load existing buffer graphics.
    await _refreshAllBuffers();

    // Zoom to layer extent.
    await featureLayer.load();
    if (featureLayer.fullExtent != null) {
      await _mapViewController.setViewpointGeometry(
        featureLayer.fullExtent!,
        paddingInDiPs: 15,
      );
    }

    setState(() => _ready = true);
  }

  // Loads the geodatabase and feature table.
  Future<void> _loadGeodatabase() async {
    // Get the geodatabase path from router extras.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final originalPath = listPaths.first;

    // Create and load the geodatabase from the mobile geodatabase location.
    _geodatabase = Geodatabase.withFileUri(Uri.file(originalPath));
    await _geodatabase.load();

    // Get the first feature table.
    _featureTable = _geodatabase.geodatabaseFeatureTables.first;

    // Load the contingent values definition.
    final cvDef = _featureTable.contingentValuesDefinition;
    await cvDef.load();
    debugPrint('Contingent values definition loaded');
    debugPrint('Field groups: ${cvDef.fieldGroups.length}');
    for (final group in cvDef.fieldGroups) {
      debugPrint(
        'Group: ${group.name}, Fields: ${group.fields.map((f) => f).join(", ")}',
      );
    }
  }

  // Configures the graphics overlay with a buffer symbol.
  void _configureGraphicsOverlay() {
    // Create outline symbol.
    final outlineSymbol = SimpleLineSymbol(
      color: const Color(0xFF000000),
      width: 2,
    );

    // Create fill symbol with red diagonal pattern.
    final fillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.forwardDiagonal,
      color: const Color(0xFFFF0000),
      outline: outlineSymbol,
    );

    _graphicsOverlay.renderer = SimpleRenderer(symbol: fillSymbol);
  }

  // Refreshes all buffer graphics by querying features with BufferSize > 0.
  Future<void> _refreshAllBuffers() async {
    // Clear existing graphics.
    _graphicsOverlay.graphics.clear();

    // Query features with buffer size > 0.
    final params = QueryParameters()..whereClause = 'BufferSize > 0';

    try {
      final result = await _featureTable.queryFeatures(params);

      // Create buffer graphics for each feature.
      for (final feature in result.features()) {
        final bufferSize = feature.attributes['BufferSize'] as int?;
        if (bufferSize != null && bufferSize > 0 && feature.geometry != null) {
          final buffer = GeometryEngine.buffer(
            geometry: feature.geometry!,
            distance: bufferSize.toDouble(),
          );
          _graphicsOverlay.graphics.add(Graphic(geometry: buffer));
        }
      }
    } catch (e) {
      debugPrint('Error refreshing buffers: $e');
    }
  }

  // Called when the map is tapped.
  Future<void> onTap(Offset offset) async {
    if (!_ready) return;

    // Convert screen point to map point.
    final mapPoint = _mapViewController.screenToLocation(screen: offset);
    if (mapPoint == null) return;

    // Create a new feature with geometry at the tapped location.
    final feature =
        _featureTable.createFeature(attributes: {}, geometry: mapPoint)
            as ArcGISFeature;

    // Add feature to the table immediately.
    await _featureTable.addFeature(feature);
    _currentFeature = feature;

    // Load status options from the Status field's coded value domain.
    _loadStatusOptions();

    // Reset UI state.
    _resetUIState();

    // Show the add feature bottom sheet.
    setState(() => _showAddFeatureSheet = true);
  }

  // Loads the Status field's coded value options.
  void _loadStatusOptions() {
    final statusField = _featureTable.fields.firstWhere(
      (f) => f.name == 'Status',
      orElse: () => throw Exception('Status field not found'),
    );

    if (statusField.domain is CodedValueDomain) {
      _statusOptions = (statusField.domain! as CodedValueDomain).codedValues;
    }
  }

  // Resets the UI state when opening the add feature sheet.
  void _resetUIState() {
    _selectedStatus = null;
    _selectedProtection = null;
    _selectedBufferSize = 0;
    _protectionOptionNames = [];
    _minBufferSize = 0;
    _maxBufferSize = 0;
    _isValid = false;
  }

  // Gets contingent coded value names for a field.
  List<String> _getContingentCodedValueNames(
    String fieldName,
    String fieldGroupName,
  ) {
    if (_currentFeature == null) return [];

    try {
      final result = _featureTable.getContingentValues(
        feature: _currentFeature!,
        field: fieldName,
      );
      final values = result.contingentValuesByFieldGroup[fieldGroupName] ?? [];

      return values
          .whereType<ContingentCodedValue>()
          .map((cv) => cv.codedValue.name)
          .toList();
    } catch (e) {
      debugPrint('Error getting contingent coded values: $e');
      return [];
    }
  }

  // Gets contingent range values (min, max) for a field.
  List<num> _getContingentRange(String fieldName, String fieldGroupName) {
    if (_currentFeature == null) return [0, 0];

    try {
      final result = _featureTable.getContingentValues(
        feature: _currentFeature!,
        field: fieldName,
      );
      final values = result.contingentValuesByFieldGroup[fieldGroupName] ?? [];

      final rangeValue = values.whereType<ContingentRangeValue>().firstOrNull;
      if (rangeValue != null) {
        return [
          (rangeValue.minValue ?? 0) as num,
          (rangeValue.maxValue ?? 0) as num,
        ];
      }
    } catch (e) {
      debugPrint('Error getting contingent range: $e');
    }

    return [0, 0];
  }

  // Updates a field value and triggers cascading updates.
  void _updateField(String field, dynamic value) {
    if (_currentFeature == null) return;

    // Update attribute immediately (synchronous).
    _currentFeature!.attributes[field] = value;

    // Trigger cascading updates based on which field changed.
    if (field == 'Status') {
      _selectedStatus = value as String;
      _updateProtectionOptions();
    } else if (field == 'Protection') {
      _selectedProtection = value as String;
      _updateBufferSizeRange();
    } else if (field == 'BufferSize') {
      _selectedBufferSize = value as int;
    }

    // Validate and update UI immediately.
    _validateAndUpdateUI();
  }

  // Updates the Protection options based on the selected Status.
  void _updateProtectionOptions() {
    _protectionOptionNames = _getContingentCodedValueNames(
      'Protection',
      _protectionFieldGroup,
    );

    // Reset downstream selections.
    _selectedProtection = null;
    _currentFeature!.attributes['Protection'] = null;
    _selectedBufferSize = 0;
    _currentFeature!.attributes['BufferSize'] = 0;
    _minBufferSize = 0;
    _maxBufferSize = 0;

    setState(() {});
  }

  // Updates the BufferSize range based on the selected Protection.
  void _updateBufferSizeRange() {
    final range = _getContingentRange('BufferSize', _bufferSizeFieldGroup);
    _minBufferSize = range[0].toInt();
    _maxBufferSize = range[1].toInt();
    _selectedBufferSize = _minBufferSize;

    // Update attribute with min value.
    _currentFeature!.attributes['BufferSize'] = _selectedBufferSize;

    setState(() {});
  }

  // Validates the feature and updates the UI state.
  void _validateAndUpdateUI() {
    if (_currentFeature == null) {
      _isValid = false;
      setState(() {});
      return;
    }

    try {
      final violations = _featureTable.validateContingencyConstraints(
        feature: _currentFeature!,
      );
      setState(() {
        _isValid = violations.isEmpty;
      });

      if (violations.isNotEmpty) {
        for (final violation in violations) {
          debugPrint(
            'Violation: ${violation.type} on field group ${violation.fieldGroup?.name}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error validating feature: $e');
      _isValid = false;
      setState(() {});
    }
  }

  // Confirms adding the feature (Save button).
  Future<void> _confirmAddFeature() async {
    if (_currentFeature == null) return;

    try {
      // Update the feature in the table.
      await _featureTable.updateFeature(_currentFeature!);

      // Refresh all buffers.
      await _refreshAllBuffers();

      _currentFeature = null;
      setState(() => _showAddFeatureSheet = false);
    } catch (e) {
      debugPrint('Error saving feature: $e');
    }
  }

  // Cancels adding the feature (Discard button).
  Future<void> _cancelAddFeature() async {
    if (_currentFeature == null) return;

    try {
      // Delete the feature from the table.
      await _featureTable.deleteFeature(_currentFeature!);

      _currentFeature = null;
      setState(() => _showAddFeatureSheet = false);
    } catch (e) {
      debugPrint('Error discarding feature: $e');
    }
  }

  // Builds the add feature bottom sheet UI.
  Widget _buildAddFeatureSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _cancelAddFeature,
                child: const Text('Discard'),
              ),
              const Text(
                'Add Bird Nest',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: _isValid ? _confirmAddFeature : null,
                child: const Text('Save'),
              ),
            ],
          ),
          const Divider(),

          // Attribute editing form
          Expanded(
            child: ListView(
              children: [
                const Text(
                  'Set the attributes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Status Picker
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statusOptions.map((cv) {
                    return DropdownMenuItem(
                      value: cv.code.toString(),
                      child: Text(cv.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _updateField('Status', value);
                  },
                ),
                const SizedBox(height: 12),

                // Protection Picker (enabled only after Status is selected)
                DropdownButtonFormField<String>(
                  value: _selectedProtection,
                  decoration: const InputDecoration(
                    labelText: 'Protection',
                    border: OutlineInputBorder(),
                  ),
                  items: _protectionOptionNames.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: _selectedStatus == null
                      ? null
                      : (value) {
                          if (value != null) _updateField('Protection', value);
                        },
                ),
                const SizedBox(height: 16),

                // BufferSize Slider (enabled only after Protection is selected)
                Text(
                  'Exclusion Area Buffer Size: $_selectedBufferSize',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (_minBufferSize > 0 || _maxBufferSize > 0)
                  Text(
                    'Range: $_minBufferSize to $_maxBufferSize',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                Slider(
                  value: _selectedBufferSize.toDouble(),
                  min: _minBufferSize.toDouble(),
                  max: _maxBufferSize > 0 ? _maxBufferSize.toDouble() : 1,
                  divisions: _maxBufferSize > _minBufferSize
                      ? _maxBufferSize - _minBufferSize
                      : null,
                  label: _selectedBufferSize.toString(),
                  onChanged: _selectedProtection == null
                      ? null
                      : (value) {
                          _updateField('BufferSize', value.round());
                        },
                ),
                const SizedBox(height: 8),
                const Text(
                  'The options will vary depending on which values are selected.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
