//
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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class TraceUtilityNetwork extends StatefulWidget {
  const TraceUtilityNetwork({super.key});

  @override
  State<TraceUtilityNetwork> createState() => _TraceUtilityNetworkState();
}

class _TraceUtilityNetworkState extends State<TraceUtilityNetwork>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // The message to display to the user.
  var _message = 'Loading Utility Network...';

  // The utility network used for tracing
  late UtilityNetwork? _utilityNetwork;
  // The medium voltage tier used for the electric distribution domain network
  UtilityTier? _mediumVoltageTier;
  // Create lists for starting locations and barriers
  final List<UtilityElement> _startingLocations = [];
  final List<UtilityElement> _barriers = [];

  // Graphics overlay for the starting locations and barrier graphics
  late GraphicsOverlay _graphicsOverlay;

  // Symbols for starting points and barriers.
  final _startingPointSymbol = SimpleMarkerSymbol(
    style: SimpleMarkerSymbolStyle.cross,
    color: Colors.lightGreen,
    size: 20,
  );
  final _barrierPointSymbol = SimpleMarkerSymbol(
    style: SimpleMarkerSymbolStyle.x,
    color: Colors.red,
    size: 20,
  );

  // The unique value renderer for the electrical distribution layer.
  late UniqueValueRenderer _electricalDistributionUvr;

  // UI state variables.
  var _isAddingStartingLocations = true;
  var _selectedTraceType = UtilityTraceType.connected;
  final List<UtilityTraceType> _traceTypes = [
    UtilityTraceType.connected,
    UtilityTraceType.subnetwork,
    UtilityTraceType.upstream,
    UtilityTraceType.downstream,
  ];

  // Terminal selection state.
  List<UtilityTerminal>? _availableTerminals;
  UtilityElement? _pendingElement;

  @override
  void initState() {
    // Set up authentication for the sample server
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = TokenChallengeHandler(
      'viewer01',
      'I68VGU^nMurF',
    );

    initElectricalDistributionRenderer();
    super.initState();
  }

  @override
  void dispose() {
    // Resets the URL session challenge handler to use default handling
    // and removes all credentials.
    ArcGISEnvironment
            .authenticationManager
            .arcGISAuthenticationChallengeHandler =
        null;
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
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
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: _onMapViewReady,
                    onTap: _onTap,
                  ),
                ),
                // Control panel
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Add starting locations or barriers buttons
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Icon(
                                _isAddingStartingLocations
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _ready ? null : Colors.grey,
                              ),
                              title: const Text('Add starting location(s)'),
                              dense: true,
                              onTap: _ready
                                  ? () => setState(
                                      () => _isAddingStartingLocations = true,
                                    )
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Icon(
                                !_isAddingStartingLocations
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _ready ? null : Colors.grey,
                              ),
                              title: const Text('Add barriers'),
                              dense: true,
                              onTap: _ready
                                  ? () => setState(
                                      () => _isAddingStartingLocations = false,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      // Trace type dropdown
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          const Text('Trace Type: '),
                          const SizedBox(width: 10),
                          //Expanded(
                          //  child:
                          DropdownButton<UtilityTraceType>(
                            value: _selectedTraceType,
                            onChanged: _ready
                                ? (value) => setState(
                                    () => _selectedTraceType = value!,
                                  )
                                : null,
                            items: _traceTypes.map((type) {
                              return DropdownMenuItem<UtilityTraceType>(
                                value: type,
                                child: Text(_getTraceTypeName(type)),
                              );
                            }).toList(),
                          ),
                          //),
                          const SizedBox(width: 10),
                        ],
                      ),
                      //const SizedBox(height: 8),
                      // Action Reset and Trace buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _ready ? _onReset : null,
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _ready && _startingLocations.isNotEmpty
                                  ? _onTrace
                                  : null,
                              child: const Text('Trace'),
                            ),
                          ),
                        ],
                      ),
                      // Status message
                      const SizedBox(height: 8),
                      Text(
                        _message,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Terminal selection dialog
            if (_availableTerminals != null)
              ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select the terminal for this junction.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButton<UtilityTerminal>(
                            value: _availableTerminals!.first,
                            onChanged: (value) {
                              //_selectTerminal(value!);
                            },
                            items: _availableTerminals!.map((terminal) {
                              return DropdownMenuItem<UtilityTerminal>(
                                value: terminal,
                                child: Text(terminal.name),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => {},
                            //_selectTerminal(_availableTerminals!.first),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Loading indicator
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal(
        Uri.parse('https://sampleserver7.arcgisonline.com/portal/'),
        connection: PortalConnection.authenticated,
      ),
      itemId: 'be0e4637620a453584118107931f718b',
    );
    // Create a map with a dark vector basemap.
    final map = ArcGISMap.withItem(portalItem);
    await map.load();

    // Set initial viewpoint in the utility network area.
    map.initialViewpoint = Viewpoint.fromTargetExtent(
      Envelope.fromPoints(
        ArcGISPoint(
          x: -9813547.35557238,
          y: 5129980.36635111,
          spatialReference: SpatialReference.webMercator,
        ),
        ArcGISPoint(
          x: -9813185.0602376,
          y: 5130215.41254146,
          spatialReference: SpatialReference.webMercator,
        ),
      ),
    );
    // Set the map on the controller.
    _mapViewController.arcGISMap = map;

    // Get the utility network
    _utilityNetwork = map.utilityNetworks.first;
    await _utilityNetwork!.load();
    final serviceGeodatabase = _utilityNetwork!.serviceGeodatabase;
    await serviceGeodatabase?.load();

    // Set selection color.
    _mapViewController.selectionProperties = SelectionProperties(
      color: Colors.yellow,
    );

    // Get the utility tier used for traces.
    final electricDistribution = _utilityNetwork!.definition!.getDomainNetwork(
      'ElectricDistribution',
    );
    _mediumVoltageTier = electricDistribution?.getTier('Medium Voltage Radial');

    // Create graphics overlay.
    _graphicsOverlay = GraphicsOverlay();
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    final table = serviceGeodatabase?.getTable(layerId: 3);
    final layer = table!.layer! as FeatureLayer;
    layer.renderer = _electricalDistributionUvr;

    setState(() {
      _ready = true;
      _message =
          'Click on the network lines or points to add a utility element.';
    });
  }

  // Create renderer for line layer with different symbols for voltage levels.
  void initElectricalDistributionRenderer() {
    final lowVoltageValue = UniqueValue(
      description: 'Low voltage',
      label: 'Low voltage',
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dash,
        color: const Color(0xFF008C8C), // DarkCyan
        width: 3,
      ),
      values: [3],
    );

    final mediumVoltageValue = UniqueValue(
      description: 'Medium voltage',
      label: 'Medium voltage',
      symbol: SimpleLineSymbol(
        color: const Color(0xFF008C8C), // DarkCyan
        width: 3,
      ),
      values: [5],
    );

    _electricalDistributionUvr = UniqueValueRenderer(
      fieldNames: ['ASSETGROUP'],
      uniqueValues: [mediumVoltageValue, lowVoltageValue],
    );
  }

  Future<void> _onTap(Offset localPosition) async {
    if (!_ready) return;
    _updateHintMessage('Identifying trace locations...');

    // Identify the feature to be used.
    final identifyResults = await _mapViewController.identifyLayers(
      screenPoint: localPosition,
      tolerance: 10,
    );
    if (identifyResults.isEmpty) {
      _updateHintMessage('Could not identify location.');
    } else {
      final point = _mapViewController.screenToLocation(screen: localPosition);
      print('reults =  ${identifyResults.length}');
      final result = identifyResults.first;
      if (result.geoElements.isNotEmpty) {
        final feature = result.geoElements.first as ArcGISFeature;
        addUtilityElement(feature, point!);
      }
    }
  }

  // Identify the utility element associated with the selected feature.
  void addUtilityElement(ArcGISFeature feature, ArcGISPoint point) {
    // Get the network source of the identified feature
    final networkSource = _utilityNetwork?.definition?.networkSources
        .firstWhere((source) {
          return source.featureTable.tableName ==
              feature.featureTable?.tableName;
        });
        
    if (networkSource == null) {
      _updateHintMessage(
        'Selected feature does not contain a Utility Network Source.',
      );
      return;
    }

    if (networkSource.sourceType == UtilityNetworkSourceType.junction) {
      _createJunctionElement(feature, networkSource);
    } else if (networkSource.sourceType ==
        UtilityNetworkSourceType.edge) {
      _createEdgeJunctionElement(feature, point);
    }
  }

  void _createJunctionElement(
    ArcGISFeature feature,
    UtilityNetworkSource source,
  ) {
    // Find the code matching the asset group name in the feature's attributes
    final assetGroupCode = feature.attributes['assetgroup'] as int;
    // Find the network source's asset group with the matching code
    final assetGroup = source.assetGroups.firstWhere(
      (group) => group.code == assetGroupCode,
    );
    final assetType = assetGroup.assetTypes.firstWhere(
      (type) => type.code == feature.attributes['assettype'] as int,
    );
    // Get the list of terminals for the feature
    final terminals = assetType.terminalConfiguration?.terminals;
    if (terminals == null || terminals.isEmpty) {
      setState(() => _message = 'Error retrieving terminal configuration');
      return;
    }

    // If there is only one terminal, use it to create a utility element
    if (terminals!.length == 1) {
      final element = _utilityNetwork?.createElement(
        arcGISFeature: feature,
        terminal: terminals.first,
      );
      _addUtilityElement(feature, element!, feature.geometry! as ArcGISPoint);
    } else {
      // handle multiple terminals; //TODO
      final element = _utilityNetwork?.createElement(
        arcGISFeature: feature,
        terminal: terminals.first,
      );
      _addUtilityElement(feature, element!, feature.geometry! as ArcGISPoint);
    }
  }

  void _createEdgeJunctionElement(ArcGISFeature feature, ArcGISPoint point) {
    // Create a utility element with the identified feature
    final element = _utilityNetwork?.createElement(arcGISFeature: feature);
    if (element == null) {
      setState(() => _message = 'Error creating element');
      return;
    }
    final line = feature as Polyline;
    element.fractionAlongEdge = GeometryEngine.fractionAlong(
      line: line,
      point: point,
      tolerance: -1,
    );
    _addUtilityElement(feature, element, point);
    // Update the hint text
    _updateHintMessage('Fraction along the edge: ${element.fractionAlongEdge}');
  }

  void _addUtilityElement(
    ArcGISFeature feature,
    UtilityElement element,
    ArcGISPoint mapPoint,
  ) {
    final graphicPoint = GeometryEngine.nearestCoordinate(
      geometry: feature.geometry!,
      point: mapPoint,
    )?.coordinate;
    final graphic = Graphic(geometry: graphicPoint);

    // add a element in either startingLocation(s) or barrier(s) array
    // visually it in a graphic
    if (_isAddingStartingLocations) {
      _startingLocations.add(element);
      graphic.symbol = _startingPointSymbol;
    } else {
      _barriers.add(element);
      graphic.symbol = _barrierPointSymbol;
    }
    _graphicsOverlay.graphics.add(graphic);
  }

  void _onReset() {
    setState(() {
      _message =
          'Click on the network lines or points to add a utility element.';
      _selectedTraceType = UtilityTraceType.connected;
    });

    // Clear collections of starting locations and barriers.
    _startingLocations.clear();
    _barriers.clear();

    // Clear the map of any locations, barriers and trace result.
    _graphicsOverlay.graphics.clear();
  }

  Future<void> _onTrace() async {
    if (_startingLocations.isEmpty) return;

    try {
      setState(() {
        _ready = false;
        _message =
            'Running ${_getTraceTypeName(_selectedTraceType).toLowerCase()} trace...';
      });

      // Clear previous selection from the layers.
      for (final layer in _mapViewController.arcGISMap!.operationalLayers) {
        if (layer is FeatureLayer) {
          layer.clearSelection();
        }
      }

      // Build trace parameters.
      final parameters = UtilityTraceParameters(
        _selectedTraceType,
        startingLocations: _startingLocations,
      );

      // Add barriers.
      parameters.barriers.addAll(_barriers);

      // Set the trace configuration using the tier from the utility domain network.
      if (_mediumVoltageTier != null) {
        parameters.traceConfiguration = _mediumVoltageTier!
            .getDefaultTraceConfiguration();
      }

      // Get the trace result from the utility network.
      final traceResults = await _utilityNetwork!.trace(parameters);

      if (traceResults.isNotEmpty) {
        final elementTraceResult =
            traceResults.first as UtilityElementTraceResult?;

        // Check if there are any elements in the result.
        if (elementTraceResult?.elements.isNotEmpty ?? false) {
          for (final layer in _mapViewController.arcGISMap!.operationalLayers) {
            if (layer is FeatureLayer) {
              final elements = elementTraceResult!.elements
                  .where(
                    (element) =>
                        element.networkSource.featureTable ==
                        layer.featureTable,
                  )
                  .toList();

              if (elements.isNotEmpty) {
                final features = await _utilityNetwork!.getFeaturesForElements(
                  elements,
                );
                layer.selectFeatures(features);
              }
            }
          }
        }
      }

      _updateHintMessage('Trace completed.');
    } on Exception catch (e) {
      _updateHintMessage('Trace failed: $e');
    } finally {
      setState(() => _ready = true);
    }
  }

  void _updateHintMessage(String message) {
    setState(() => _message = message);
  }

  String _getTraceTypeName(UtilityTraceType traceType) {
    switch (traceType) {
      case UtilityTraceType.connected:
        return 'Connected';
      case UtilityTraceType.subnetwork:
        return 'Subnetwork';
      case UtilityTraceType.upstream:
        return 'Upstream';
      case UtilityTraceType.downstream:
        return 'Downstream';
      default:
        return traceType.toString();
    }
  }
}

class TokenChallengeHandler implements ArcGISAuthenticationChallengeHandler {
  TokenChallengeHandler(
    this.username,
    this.password, {
    this.rememberChallenges = true,
  });

  final String username;
  final String password;
  bool rememberChallenges;

  final challenges = <ArcGISAuthenticationChallenge>[];

  @override
  Future<void> handleArcGISAuthenticationChallenge(
    ArcGISAuthenticationChallenge challenge,
  ) async {
    if (rememberChallenges) challenges.add(challenge);

    final credential = await TokenCredential.createWithChallenge(
      challenge,
      username: username,
      password: password,
    );
    challenge.continueWithCredential(credential);
  }
}
