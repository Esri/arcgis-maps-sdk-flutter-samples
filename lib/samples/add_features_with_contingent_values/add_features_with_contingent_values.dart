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

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Feature layer to be displayed on the map.
  late ArcGISFeatureTable _featureTable;


  // Contingent values definition.
  ContingentValuesDefinition? _contingentValuesDefinition;

  // Graphics and feature state
  final _graphicsOverlay = GraphicsOverlay();
  ArcGISFeature? _currentFeature;
  Graphic? _currentBufferGraphic;

  // Attribute state
  String? _selectedStatus;
  String? _selectedProtection;
  int _selectedBufferSize = 0;

  // Options
  List<CodedValue> _statusOptions = [];
  List<CodedValue> _protectionOptions = [];
  int _minBufferSize = 0;
  int _maxBufferSize = 100;

  var _isValid = false;
  var _showAddFeatureSheet = false;


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
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(.arcGISTopographic);

    // Add map to the map view.
    _mapViewController.arcGISMap = map;

    // Load the feature table.
    await loadFeatureTable();

    // Create a new FeatureLayer from the feature table and add it to the map.
    final featureLayer = FeatureLayer.withFeatureTable(_featureTable);

    // Add the feature layer to the map.
    map.operationalLayers.add(featureLayer);

    // Configure graphics overlay with buffer symbol.
    configureGraphicsOverlay();
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Load existing features and their buffers.
    await _loadExistingBuffers();

    // Zoom to layer extent.
    await featureLayer.load();
    if (featureLayer.fullExtent != null) {
      await _mapViewController.setViewpointGeometry(
        featureLayer.fullExtent!,
        paddingInDiPs: 15,
      );
    }
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void configureGraphicsOverlay() {
    // Create buffer symbol (red diagonal fill, black outline)
    final outlineSymbol = SimpleLineSymbol(
      color: const Color(0xFF000000),
      width: 2,
    );

    final fillSymbol = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.forwardDiagonal,
      color: const Color(0xFFFF0000),
      outline: outlineSymbol,
    );

    _graphicsOverlay.renderer = SimpleRenderer(symbol: fillSymbol);
  }

  Future<void> _loadExistingBuffers() async {
    final queryParams = QueryParameters()..whereClause = 'BufferSize > 0';

    try {
      final result = await _featureTable.queryFeatures(queryParams);

      for (final feature in result.features()) {
        final bufferSize = feature.attributes['BufferSize'] as int?;
        if (bufferSize != null && bufferSize > 0 && feature.geometry != null) {
          final bufferPolygon = GeometryEngine.buffer(
            geometry: feature.geometry!,
            distance: bufferSize.toDouble(),
          );
          _graphicsOverlay.graphics.add(Graphic(geometry: bufferPolygon));
        }
      }
      // TODO: Remove Catch.
    } catch (e) {
      debugPrint('Error loading buffers: $e');
    }
  }

  Future<void> onTap(Offset offset) async{
    if (!_ready || _contingentValuesDefinition == null) return;
    final mapPoint = _mapViewController.screenToLocation(screen: offset);
    if (mapPoint == null) return;

    // Create feature at tapped location.
    final feature = _featureTable.createFeature() as ArcGISFeature;
    feature.geometry = mapPoint;

    // Add feature to table.
    await _featureTable.addFeature(feature);
    _currentFeature = feature;

    // Create buffer graphic placeholder.
    _currentBufferGraphic = Graphic();
    _graphicsOverlay.graphics.add(_currentBufferGraphic!);


  }

  void _loadStatusOptions() {
    // Get Status field domain
    final statusField = _featureTable.fields.firstWhere(
          (f) => f.name == 'Status',
      orElse: () => throw Exception('Status field not found'),
    );

    if (statusField.domain is CodedValueDomain) {
      final domain = statusField.domain! as CodedValueDomain;
      _statusOptions = domain.codedValues;
    }
  }







  Future<void> loadFeatureTable() async {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final originalPath = listPaths.first;

    // Create and load the Geodatabase from the mobile geodatabase location on file.
    final geodatabase = Geodatabase.withFileUri(Uri.file(originalPath));

    // Load the Geodatabase.
    await geodatabase.load();

    // Load the first GeodatabaseFeatureTable as an ArcGISFeatureTable.
    _featureTable =
        geodatabase.geodatabaseFeatureTables.first as ArcGISFeatureTable;

    // Load the AGSContingentValuesDefinition from the feature table.
    await _loadContingentValuesDefinition();
  }

  Future<void> _loadContingentValuesDefinition() async {
    // Access the contingent values definition from the feature table.
    _contingentValuesDefinition = _featureTable.contingentValuesDefinition;

    if (_contingentValuesDefinition != null) {
      await _contingentValuesDefinition!.load();

      // TODO: Log field groups for debugging
      debugPrint('Field groups: ${_contingentValuesDefinition!.fieldGroups.length}');
      for (final group in _contingentValuesDefinition!.fieldGroups) {
        debugPrint('Group: ${group.name}, Fields: ${group.fields.map((f) => f).join(", ")}');
      }
    }
  }
}
