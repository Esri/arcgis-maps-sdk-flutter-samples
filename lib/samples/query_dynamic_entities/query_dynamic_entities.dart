//
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
import 'dart:convert';
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QueryDynamicEntities extends StatefulWidget {
  const QueryDynamicEntities({super.key});

  @override
  State<QueryDynamicEntities> createState() => _QueryDynamicEntitiesState();
}

class _QueryDynamicEntitiesState extends State<QueryDynamicEntities>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Graphics overlay for displaying the PHX airport buffer graphic.
  final _bufferGraphicsOverlay = GraphicsOverlay();

  // The dynamic entity layer displayed on the map.
  late final DynamicEntityLayer _dynamicEntityLayer;

  // The custom data source streaming mock air traffic observations.
  CustomDynamicEntityDataSource? _dataSource;

  // A geometry representing a 15 mile buffer around Phoenix Sky Harbor (PHX).
  late final Polygon _phoenixAirportBuffer;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // State for the non-modal query results sheet.
  var _isResultsSheetVisible = false;
  QuerySelection? _currentSelection;
  List<DynamicEntity> _currentEntities = const [];

  @override
  void dispose() {
    unawaited(_dataSource?.disconnect());
    super.dispose();
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
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Button to toggle overview or full model sublayers.
                    ElevatedButton(
                      onPressed: _showQueryMenu,
                      child: const Text('Query Flights'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _isResultsSheetVisible
          ? _QueryResultsSheet(
              selection: _currentSelection!,
              entities: _currentEntities,
              onClose: _closeResultsSheet,
            )
          : null,
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 33.4352,
        longitude: -112.0101,
        scale: 1266500,
      );

    // Create a 15-mile geodetic buffer around Phoenix airport.
    final phxPoint = ArcGISPoint(
      x: -112.0101,
      y: 33.4352,
      spatialReference: SpatialReference.wgs84,
    );
    _phoenixAirportBuffer = GeometryEngine.bufferGeodetic(
      geometry: phxPoint,
      distance: 15,
      distanceUnit: LinearUnit(unitId: LinearUnitId.miles),
      maxDeviation: double.nan,
      curveType: GeodeticCurveType.geodesic,
    );

    // Configure a graphics overlay to display the buffer polygon.
    _configureBufferOverlay();
    _mapViewController.graphicsOverlays.add(_bufferGraphicsOverlay);

    // Load and configure the dynamic entity layer.
    _loadDynamicEntityLayer();
    _configureDynamicEntityLayer(_dynamicEntityLayer);
    map.operationalLayers.add(_dynamicEntityLayer);

    // Set the map to the map view.
    _mapViewController.arcGISMap = map;

    setState(() => _ready = true);
  }

  // Configure the graphics overlay to display the PHX airport buffer.
  void _configureBufferOverlay() {
    final blackLineSymbol = SimpleLineSymbol(color: Colors.black);
    final fillSymbol = SimpleFillSymbol(
      color: Colors.red.withValues(alpha: 0.1),
      outline: blackLineSymbol,
    );
    final bufferGraphic = Graphic(
      geometry: _phoenixAirportBuffer,
      symbol: fillSymbol,
    );

    _bufferGraphicsOverlay.graphics.clear();
    _bufferGraphicsOverlay.graphics.add(bufferGraphic);
    _bufferGraphicsOverlay.isVisible = false;
  }

  // Load the dynamic entity layer with a custom data source.
  void _loadDynamicEntityLayer() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;

    // Create a custom data source that streams PHX air traffic observations.
    final provider = _PhxAirTrafficProvider(localJsonPath: listPaths.first);
    _dataSource = CustomDynamicEntityDataSource(provider);

    // Create a dynamic entity later from the custom data source.
    _dynamicEntityLayer = DynamicEntityLayer(_dataSource!);
  }

  // Configure the dynamic entity layer to show track lines and labels.
  void _configureDynamicEntityLayer(DynamicEntityLayer layer) {
    layer.trackDisplayProperties
      ..showPreviousObservations = true
      ..showTrackLine = true
      ..maximumObservations = 20;

    // Keep default renderers; only configure labels.
    final labelDefinition = LabelDefinition(
      labelExpression: SimpleLabelExpression(
        simpleExpression: '[flight_number]',
      ),
      textSymbol: TextSymbol(color: Colors.red, size: 12),
    )..placement = LabelingPlacement.pointAboveCenter;

    layer.labelDefinitions.add(labelDefinition);
    layer.labelsEnabled = true;
  }

  // Show a menu for selecting the type of query to perform.
  Future<void> _showQueryMenu() async {
    final selected = await showModalBottomSheet<QuerySelection>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Within 15 Miles of PHX'),
              onTap: () => Navigator.pop(context, (
                type: QueryType.geometry,
                trackId: null,
              )),
            ),
            ListTile(
              leading: const Icon(Icons.flight_land),
              title: const Text('Arriving in PHX'),
              onTap: () => Navigator.pop(context, (
                type: QueryType.attributes,
                trackId: null,
              )),
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('With Flight Number'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final flightNumber = await _promptForFlightNumber();
                if (flightNumber == null || flightNumber.trim().isEmpty) {
                  return;
                }
                navigator.pop((
                  type: QueryType.trackId,
                  trackId: flightNumber.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );

    // If a selection was made, run the corresponding query.
    if (selected == null) return;
    await _runQuery(selected);
  }

  // Prompt the user to enter a flight number for the track ID query.
  Future<String?> _promptForFlightNumber() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter a Flight Number to Query'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '',
              labelText: 'Flight Number',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // Run the selected query and display the results in a bottom sheet.
  Future<void> _runQuery(QuerySelection selection) async {
    final dataSource = _dataSource;
    if (dataSource == null) return;
    // Show the buffer graphic only for geometry queries.
    _bufferGraphicsOverlay.isVisible = selection.type == QueryType.geometry;

    // A list to collect the query results.
    var entities = const <DynamicEntity>[];

    // The result of the dynamic entity query.
    DynamicEntityQueryResult queryResult;

    // Execute the appropriate query based on the selection.
    switch (selection.type) {
      case QueryType.geometry:
        final params = DynamicEntityQueryParameters()
          ..geometry = _phoenixAirportBuffer
          ..spatialRelationship = SpatialRelationship.intersects;
        queryResult = await dataSource.queryDynamicEntities(params);
      case QueryType.attributes:
        final params = DynamicEntityQueryParameters()
          ..whereClause = "status = 'In flight' AND arrival_airport = 'PHX'";
        queryResult = await dataSource.queryDynamicEntities(params);
      case QueryType.trackId:
        queryResult = await dataSource.queryDynamicEntitiesByTrackIds([
          selection.trackId!,
        ]);
    }

    // Collect the query results into a list.
    entities = queryResult.iterator().toList(growable: false);
    _dynamicEntityLayer.clearSelection();
    if (entities.isNotEmpty) {
      _dynamicEntityLayer.selectDynamicEntities(entities);
    }

    // Show the query results in a bottom sheet.
    _showQueryResultsSheet(selection, entities: entities);
  }

  void _showQueryResultsSheet(
    QuerySelection selection, {
    required List<DynamicEntity> entities,
  }) {
    setState(() {
      _currentSelection = selection;
      _currentEntities = entities;
      _isResultsSheetVisible = true;
    });
  }

  void _closeResultsSheet() {
    setState(() {
      _isResultsSheetVisible = false;
      _currentSelection = null;
      _currentEntities = const [];
    });

    // Clear selection and hide buffer when the results sheet is closed.
    _dynamicEntityLayer.clearSelection();
    _bufferGraphicsOverlay.isVisible = false;
  }
}

// Enum representing the types of queries available.
enum QueryType { geometry, attributes, trackId }

typedef QuerySelection = ({QueryType type, String? trackId});

// Create a result label based on the query selection.
String _resultLabel(QuerySelection selection) {
  return switch (selection.type) {
    QueryType.geometry => 'Flights within 15 miles of PHX',
    QueryType.attributes => 'Flights arriving in PHX',
    QueryType.trackId => 'Flights matching number: ${selection.trackId ?? ''}',
  };
}

class _DynamicEntityObservationTile extends StatefulWidget {
  const _DynamicEntityObservationTile({required this.entity});

  // The dynamic entity to observe.
  final DynamicEntity entity;

  @override
  State<_DynamicEntityObservationTile> createState() =>
      _DynamicEntityObservationTileState();
}

class _DynamicEntityObservationTileState
    extends State<_DynamicEntityObservationTile> {
  // Subscribe to the ArcGIS dynamic entity change stream.
  StreamSubscription<DynamicEntityChangedInfo>? _subscription;
  // Latest observation attributes pulled from the ArcGIS entity.
  Map<CaseInsensitiveString, dynamic> _attributes = const {};
  // Tracks whether the tile is expanded to show attributes.
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Seed the attributes with the latest observation, if any.
    // Uses the ArcGIS API to read the entity's most recent observation.
    _attributes = widget.entity.getLatestObservation()?.attributes ?? const {};

    // Listen for dynamic entity changes to keep the UI in sync.
    _subscription = widget.entity.onDynamicEntityChanged.listen((changedInfo) {
      if (changedInfo.dynamicEntityPurged) {
        // Clear attributes when the entity is purged from the stream.
        setState(() => _attributes = const {});
        return;
      }
      final attrs = changedInfo.receivedObservation?.attributes;
      if (attrs != null) {
        // Update attributes when a new observation arrives.
        setState(() => _attributes = attrs);
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription to avoid memory leaks.
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The flight number as the tile title when available.
    final flightNumber = _attributes['flight_number'] as String?;
    // Sort attributes to keep the list stable and readable.
    final sortedEntries = _attributes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ExpansionTile(
      title: Text(flightNumber ?? ''),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
      children: sortedEntries
          // Filter out null values and render the remaining attributes.
          .where((e) => e.value != null)
          .map(
            (e) => ListTile(
              dense: true,
              title: Text(_planeAttributeLabel(e.key)),
              trailing: Text(_formatAttributeValue(e.value)),
            ),
          )
          .toList(),
    );
  }

  // Map attribute keys to labels.
  static String _planeAttributeLabel(String key) {
    switch (key) {
      case 'aircraft':
        return 'Aircraft';
      case 'altitude_feet':
        return 'Altitude (ft)';
      case 'arrival_airport':
        return 'Arrival Airport';
      case 'flight_number':
        return 'Flight Number';
      case 'heading':
        return 'Heading';
      case 'speed':
        return 'Speed';
      case 'status':
        return 'Status';
      default:
        return key;
    }
  }

  // Format attribute values for display.
  static String _formatAttributeValue(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toStringAsFixed(2);
    return value.toString();
  }
}

class _QueryResultsSheet extends StatelessWidget {
  const _QueryResultsSheet({
    required this.selection,
    required this.entities,
    required this.onClose,
  });

  // The query selection that produced the results.
  final QuerySelection selection;
  // The list of dynamic entities returned by the query.
  final List<DynamicEntity> entities;
  // Callback to close the results sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        builder: (context, scrollController) {
          return Material(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Query Results'),
                  subtitle: Text(_resultLabel(selection)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Empty state when no entities matched the query.
                      if (entities.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'There are no flights to display for this query.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      // A scrollable list of dynamic entity observations.
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: entities.length,
                        itemBuilder: (context, index) {
                          return _DynamicEntityObservationTile(
                            entity: entities[index],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Enum representing the keys for plane attributes.
enum _PlaneAttributeKey {
  aircraft,
  altitudeFeet,
  arrivalAirport,
  flightNumber,
  heading,
  speed,
  status;

  // Provide the field name associated with the attribute key.
  String get fieldName {
    return switch (this) {
      _PlaneAttributeKey.aircraft => 'aircraft',
      _PlaneAttributeKey.altitudeFeet => 'altitude_feet',
      _PlaneAttributeKey.arrivalAirport => 'arrival_airport',
      _PlaneAttributeKey.flightNumber => 'flight_number',
      _PlaneAttributeKey.heading => 'heading',
      _PlaneAttributeKey.speed => 'speed',
      _PlaneAttributeKey.status => 'status',
    };
  }

  // Determine the field type based on the attribute key.
  FieldType get fieldType {
    return switch (this) {
      _PlaneAttributeKey.heading ||
      _PlaneAttributeKey.altitudeFeet ||
      _PlaneAttributeKey.speed => FieldType.float64,
      _ => FieldType.text,
    };
  }
}

// A custom dynamic entity data provider that streams mock air traffic data for PHX.
final class _PhxAirTrafficProvider extends CustomDynamicEntityDataProvider {
  // Constructor accepting the local JSON file path.
  _PhxAirTrafficProvider({required this.localJsonPath});

  // The local path to the JSON file containing mock air traffic observations.
  final String localJsonPath;

  // A flag indicating whether the provider is currently connected.
  bool _isConnected = false;

  @override
  Future<DynamicEntityDataSourceInfo> onLoad() async {
    // Define the fields for the dynamic entity data source.
    final fields = _PlaneAttributeKey.values
        .map(
          (k) => Field(
            type: k.fieldType,
            name: k.fieldName,
            alias: '',
            length: 0,
            isEditable: false,
            isNullable: true,
          ),
        )
        .toList(growable: false);

    // Define the data source info with fields and entity ID field.
    final info = DynamicEntityDataSourceInfo(
      entityIdFieldName: 'flight_number',
      fields: fields,
    )..spatialReference = SpatialReference.wgs84;

    return info;
  }

  @override
  Future<void> onConnect() async {
    if (_isConnected) return;
    _isConnected = true;

    // Start streaming mock air traffic observations.
    unawaited(_startStreaming());
  }

  @override
  Future<void> onDisconnect() async {
    if (!_isConnected) return;
    _isConnected = false;
  }

  // Start streaming mock air traffic observations from the local JSON file.
  Future<void> _startStreaming() async {
    final file = File(localJsonPath);

    // Decodes the plane from the line and uses it to create a new observation.
    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    // Stream each line as a new observation until disconnected.
    await for (final line in lines) {
      if (!_isConnected) return;

      final decoded = jsonDecode(line) as Map<String, dynamic>;
      final geometryJson = decoded['geometry'] as Map<String, dynamic>?;
      final attributesJson = decoded['attributes'] as Map<String, dynamic>?;

      final geometry = Geometry.fromJson(geometryJson!);
      handleEntityDataEvent(NewObservation(geometry, attributesJson!));

      // Delay the next observation to simulate live data.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
