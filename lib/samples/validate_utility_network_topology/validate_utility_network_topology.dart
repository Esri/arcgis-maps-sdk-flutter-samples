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

import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/token_challenger_handler.dart';
import 'package:flutter/material.dart';

class ValidateUtilityNetworkTopology extends StatefulWidget {
  const ValidateUtilityNetworkTopology({super.key});

  @override
  State<ValidateUtilityNetworkTopology> createState() =>
      _ValidateUtilityNetworkTopologyState();
}

class _ValidateUtilityNetworkTopologyState
    extends State<ValidateUtilityNetworkTopology>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A utility network.
  UtilityNetwork? _utilityNetwork;
  // Parameters to be used for performing traces.
  UtilityTraceParameters? _traceParameters;
  // A graphics overlay used to display graphics on the map view.
  final _graphicsOverlay = GraphicsOverlay();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Variables used in the UI.
  var _statusTitle = 'Loading webmap...';
  var _statusText = '';
  var _fieldName = '';

  // The feature's field currently being edited.
  Field? field;

  // The coded values from the field's domain.
  List<CodedValue> _codedValues = [];

  // The selected field coded value.
  CodedValue? _selectedCodedValue;

  // Variables used for tracing.
  final assetGroupName = 'Circuit Breaker';
  final assetTypeName = 'Three Phase';
  final globalId = '{1CAF7740-0BF4-4113-8DB2-654E18800028}';
  final domainNetworkName = 'ElectricDistribution';
  final tierName = 'Medium Voltage Radial';

  // Variables used for editing.
  // The name of the "Electric Distribution Line" feature table.
  final lineTableName = 'Electric Distribution Line';
  // The name of the "Electric Distribution Device" feature table.
  final deviceTableName = 'Electric Distribution Device';

  // The name of the device status field in the "Electric Distribution Device" feature table.
  final deviceStatusField = 'devicestatus';

  // The name of the nominal voltage field in the "Electric Distribution Line" feature table.
  final nominalVoltageField = 'nominalvoltage';

  ArcGISFeature? _featureToEdit;

  bool _validateIsEnabled = true;
  bool _traceIsEnabled = true;
  bool _clearIsEnabled = false;
  bool _attributePickerVisible = false;

  @override
  void initState() {
    // Set up authentication for the sample server.
    // Note: Never hardcode login information in a production application.
    // This is done solely for the sake of the sample.
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = TokenChallengeHandler(
      'editor01',
      'S7#i2LWmYH75',
    );
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
                  spacing: 5,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: onGetState,
                      child: const Text('Get State'),
                    ),
                    ElevatedButton(
                      onPressed: _traceIsEnabled ? onTrace : null,
                      child: const Text('Trace'),
                    ),
                    ElevatedButton(
                      onPressed: _validateIsEnabled ? onValidate : null,
                      child: const Text('Validate'),
                    ),
                    ElevatedButton(
                      onPressed: _clearIsEnabled ? onClear : null,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
            IgnorePointer(
              child: Container(
                width: MediaQuery.sizeOf(context).width,
                padding: const EdgeInsets.all(10),
                color: Colors.white.withValues(alpha: 0.95),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _attributePickerVisible ? buildAttributePicker() : null,
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map using a webmap url.
    final map = ArcGISMap.withUri(
      Uri.parse(
        'https://sampleserver7.arcgisonline.com/portal/home/item.html?id=6e3fc6db3d0b4e6589eb4097eb3e5b9b',
      ),
    )!;

    // Load in persistent session mode (workaround for server caching issue)
    // https://support.esri.com/en-us/bug/asynchronous-validate-request-for-utility-network-servi-bug-000160443
    map.loadSettings = LoadSettings()
      ..featureServiceSessionType = FeatureServiceSessionType.persistent;

    // Load the map.
    await map.load();

    // Load the utility network.
    setState(() => _statusTitle = 'Loading utility network...');
    _utilityNetwork = map.utilityNetworks.first;
    await _utilityNetwork!.load();

    // Get the service geodatabase.
    final serviceGeodatabase = _utilityNetwork!.serviceGeodatabase;
    // Restrict editing and tracing to a unique branch.
    final parameters = ServiceVersionParameters();
    parameters.name = 'ValidateNetworkTopology_${Guid()}';
    parameters.access = VersionAccess.private;
    parameters.description = 'Validate network topology with ArcGIS Maps SDK';
    final serviceVersionInfo = await serviceGeodatabase!.createVersion(
      newVersion: parameters,
    );
    await serviceGeodatabase.switchVersion(
      versionName: serviceVersionInfo.name,
    );

    final deviceLabelDefinition = LabelDefinition(
      labelExpression: SimpleLabelExpression(
        simpleExpression: '[devicestatus]',
      ),
      textSymbol: TextSymbol(color: Colors.indigo, size: 12)
        ..haloColor = Colors.white
        ..haloWidth = 2,
    )..useCodedValues = true;
    final lineLabelDefinition = LabelDefinition(
      labelExpression: SimpleLabelExpression(
        simpleExpression: '[nominalvoltage]',
      ),
      textSymbol: TextSymbol(color: Colors.red, size: 12)
        ..haloColor = Colors.white
        ..haloWidth = 2,
    )..useCodedValues = true;

    // Visualize attribute editing using labels
    for (final layer in map.operationalLayers.whereType<FeatureLayer>()) {
      if (layer.name == deviceTableName) {
        layer.labelDefinitions.add(deviceLabelDefinition);
        layer.labelsEnabled = true;
      } else if (layer.name == lineTableName) {
        layer.labelDefinitions.add(lineLabelDefinition);
        layer.labelsEnabled = true;
      }
    }

    // Add the dirty area table to the map to visualize it.
    final dirtyAreaTable = _utilityNetwork!.dirtyAreaTable;
    await dirtyAreaTable!.load();
    final featureLayer = FeatureLayer.withFeatureTable(dirtyAreaTable);
    map.operationalLayers.add(featureLayer);

    // Trace with a subnetwork controller as default starting location
    final networkSource = _utilityNetwork!.definition!.getNetworkSource(
      deviceTableName,
    );
    final assetGroup = networkSource!.getAssetGroup(assetGroupName);
    final assetType = assetGroup!.getAssetType(assetTypeName);
    final startingLocation = _utilityNetwork!.createElementWithAssetType(
      assetType!,
      globalId: Guid.fromString(globalId)!,
    );
    // Set the terminal for the location, in our case, the "Load" terminal.
    final terminal = startingLocation.assetType.terminalConfiguration?.terminals
        .firstWhere((terminal) => terminal.name == 'Load');
    startingLocation.terminal = terminal;

    // Add a graphic to indicate the location on the map.
    final features = await _utilityNetwork!.getFeaturesForElements([
      startingLocation,
    ]);
    final feature = features.first;
    await feature.load();
    final graphic = Graphic(
      geometry: feature.geometry,
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.cross,
        color: Colors.green,
        size: 25,
      ),
    );
    _graphicsOverlay.graphics.add(graphic);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Trace with a configuration that stops traversability on an open device.
    final domainNetwork = _utilityNetwork!.definition!.getDomainNetwork(
      domainNetworkName,
    );
    final sourceTier = domainNetwork!.getTier(tierName);
    _traceParameters = UtilityTraceParameters(
      UtilityTraceType.downstream,
      startingLocations: [startingLocation],
    )..traceConfiguration = sourceTier!.getDefaultTraceConfiguration();

    // Add the map to the map view.
    _mapViewController.arcGISMap = map;

    // Set an initial viewpoint.
    _mapViewController.setViewpoint(
      Viewpoint.fromTargetExtent(
        Envelope.fromXY(
          xMin: -9815489.0660101417,
          yMin: 5128463.4221229386,
          xMax: -9814625.2768726498,
          yMax: 5128968.4911854975,
          spatialReference: SpatialReference.webMercator,
        ),
      ),
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() {
      _ready = true;
      _statusTitle = 'Utility Network loaded';
      _statusText = '''
            Tap on a feature to edit.
            Tap 'Get State' to check if validating is necessary or if tracing is available.
            Tap 'Trace' to run a trace.
            ''';
    });
  }

  Future<void> onTap(Offset tappedLocation) async {
    setState(() {
      _ready = false;
      _statusTitle = 'Identifying feature to edit...';
      _statusText = '';
    });

    // Clear previous selection.
    clearSelectionsFromAllLayers();

    // Perform an identify to determine if a user tapped on a feature.
    final identifyResults = await _mapViewController.identifyLayers(
      screenPoint: tappedLocation,
      tolerance: 5,
    );

    if (identifyResults.isNotEmpty) {
      final result = identifyResults.firstWhere((result) {
        return result.layerContent.name == deviceTableName ||
            result.layerContent.name == lineTableName;
      });
      if (result.geoElements.isEmpty) {
        setState(() {
          _statusTitle = 'No feature identified. Tap on a feature to edit.';
          _ready = true;
        });
      } else {
        final feature = result.geoElements.first as ArcGISFeature;
        final fieldName = feature.featureTable?.tableName == deviceTableName
            ? deviceStatusField
            : nominalVoltageField;
        final field = feature.featureTable?.getField(fieldName: fieldName);
        if (field == null || field.domain == null) {
          return;
        }
        final codedValues = (field.domain! as CodedValueDomain).codedValues;
        if (codedValues.isEmpty) {
          return;
        }

        // Set the coded values to the attribute picker.
        _codedValues = codedValues;

        if (feature.loadStatus != LoadStatus.loaded) {
          await feature.load();
        }

        // Select the feature.
        if (feature.featureTable?.layer is FeatureLayer) {
          final featureLayer = feature.featureTable!.layer! as FeatureLayer;
          featureLayer.selectFeature(feature);
        }
        setState(() {
          _fieldName = field.alias;
          _featureToEdit = feature;
        });

        final actualValue = feature.attributes[field.name] as int;
        print('actual: $actualValue');
        // setState(
        //   () => _selectedCodedValue = _codedValues.firstWhere(
        //     (value) => value == actualValue,
        //   ),
        // );

        //         var actualValue = Convert.ToInt32(_featureToEdit.Attributes[field.Name]);
        //         Choices.SelectedItem = codedValues.Single(
        //             c => Convert.ToInt32(c.Code).Equals(actualValue)
        //         );

        //         FieldName.Text = field.Name;
        //         Status.Text = $"Select a new '{field.Alias ?? field.Name}'";

        //         // Update the UI for the selection.
        //         AttributePicker.Visibility = Visibility.Visible;
        //         ClearBtn.IsEnabled = true;

        setState(() {
          _ready = true;
          _clearIsEnabled = true;
          _attributePickerVisible = true;
        });
      }
    } else {
      setState(() {
        _statusTitle = 'No feature identified. Tap on a feature to edit.';
        _ready = true;
      });
    }
  }

  Future<void> onGetState() async {
    if (_utilityNetwork!.definition!.capabilities.supportsNetworkState) {
      setState(() {
        _ready = false;
        _statusTitle = 'Getting utility network state...';
        _statusText = '';
      });

      final state = await _utilityNetwork!.getState();

      setState(() {
        _validateIsEnabled = state.hasDirtyAreas;
        _traceIsEnabled = state.isNetworkTopologyEnabled;
      });

      var status =
          '''
              Has Dirty Areas: ${state.hasDirtyAreas}
              Has Errors: ${state.hasErrors}
              Is Network Topology Enabled: ${state.isNetworkTopologyEnabled}
            ''';
      if (state.hasDirtyAreas || state.hasErrors) {
        status =
            "$status\nTap 'Validate' before trace or expect a trace error.";
      } else {
        status =
            "$status\nTap on a feature to edit or tap 'Trace' to run a trace.";
      }

      setState(() {
        _statusTitle = 'Utility Network State:';
        _statusText = status;
        _ready = true;
      });
    }
  }

  Future<void> onValidate() async {
    if (_utilityNetwork == null) return;
    setState(() {
      _ready = false;
      _statusTitle = 'Validating utility network topology...';
      _statusText = '';
    });
    // Get the current extent.
    final extent = _mapViewController
        .getCurrentViewpoint(ViewpointType.boundingGeometry)!
        .targetGeometry
        .extent;

    // Get the validation result.
    final job = _utilityNetwork!.validateNetworkTopology(extent: extent);
    final result = await job.run();

    setState(() {
      _statusTitle = 'Utility Validation Result:';
      _statusText =
          '''
          Has Dirty Areas: ${result.hasDirtyAreas}
          Has Errors: ${result.hasErrors}
          Tap 'Get State' to check the updated network state.
        ''';
      _validateIsEnabled = result.hasDirtyAreas;
      _ready = true;
    });
  }

  Future<void> onTrace() async {
    setState(() {
      _ready = false;
      _statusTitle = 'Running a downstream trace...';
      _statusText = '';
    });

    // Clear previous selection from the layers.
    clearSelectionsFromAllLayers();

    // Get the trace result from the utility network.
    final traceResult = await _utilityNetwork!.trace(_traceParameters!);
    final elementTraceResult = traceResult
        .whereType<UtilityElementTraceResult>()
        .first;
    // Check if there are any elements in the result.
    final elementCount = elementTraceResult.elements.length;
    for (final layer
        in _mapViewController.arcGISMap!.operationalLayers
            .whereType<FeatureLayer>()) {
      final elements = elementTraceResult.elements
          .where(
            (element) =>
                element.networkSource.featureTable == layer.featureTable,
          )
          .toList();
      if (elements.isNotEmpty) {
        final features = await _utilityNetwork!.getFeaturesForElements(
          elements,
        );
        layer.selectFeatures(features);
      }
    }
    setState(() {
      _statusTitle = 'Trace completed:';
      _statusText = '$elementCount elements found';
      _clearIsEnabled = true;
      _ready = true;
    });
  }

  void onClear() {
    // Clear the selection.
    clearSelectionsFromAllLayers();
    // Make relevant UI updates.
    setState(() {
      _attributePickerVisible = false;
      _featureToEdit = null;
      _statusTitle = 'Selection cleared';
      _statusText = '';
      _clearIsEnabled = false;
    });
  }

  void clearSelectionsFromAllLayers() {
    _mapViewController.arcGISMap!.operationalLayers
        .whereType<FeatureLayer>()
        .forEach((layer) => layer.clearSelection());
  }

  // The build method for the Settings bottom sheet.
  Widget buildAttributePicker() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        max(
          20,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Edit Feature',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.check), onPressed: applyEdits),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _attributePickerVisible = false);
                  onClear();
                },
              ),
            ],
          ),
          Text(_fieldName),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _codedValues.length,
              itemBuilder: (context, index) {
                final value = _codedValues[index];
                return ListTile(
                  title: Text(value.name),
                  trailing: value == _selectedCodedValue
                      ? Icon(Icons.check)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void applyEdits() {
    // final table =
    //     _featureToEdit!.featureTable! as ServiceFeatureTable;
    // final serviceGeodatabase = table.serviceGeodatabase;
    // setState(() => _fieldName = )
  }
}
