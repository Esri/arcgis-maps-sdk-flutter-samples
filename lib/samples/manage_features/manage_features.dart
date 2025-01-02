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

class ManageFeatures extends StatefulWidget {
  const ManageFeatures({super.key});

  @override
  State<ManageFeatures> createState() => _ManageFeaturesState();
}

class _ManageFeaturesState extends State<ManageFeatures>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create a service feature table.
  late final ServiceFeatureTable _damageServiceFeatureTable;
  // Create a feature layer.
  late final FeatureLayer _damageFeatureLayer;

  // Create a list of feature management options.
  final _featureManagementOptions =
      <DropdownMenuItem<FeatureManagementOperation>>[];
  // Create a variable to store the selected operation.
  FeatureManagementOperation? _selectedOperation;

  // Create a list of damage type attribute options.
  final _damageTypeAttributeOptions = <DropdownMenuItem<String>>[];
  // Create a variable to store the attribute value of the selected damage type.
  String? _selectedDamageType;

  // Create a variable to store the selected feature.
  Feature? _selectedFeature;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();
    // Add each feature management operation to the list of dropdown menu options.
    _featureManagementOptions.addAll(
      FeatureManagementOperation.values.map(
        (operation) => DropdownMenuItem(
          onTap: () => setState(
            () => _selectedOperation == operation,
          ),
          value: operation,
          child: Text(getLabel(operation)),
        ),
      ),
    );
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
                    onTap: onTap,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        children: [
                          // Create a dropdown button to select a feature management operation.
                          DropdownButton(
                            alignment: Alignment.center,
                            hint: Text(
                              'Select operation',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            value: _selectedOperation,
                            icon: const Icon(Icons.arrow_drop_down),
                            elevation: 16,
                            style: Theme.of(context).textTheme.labelMedium,
                            // Set the onChanged callback to update the selected operation.
                            onChanged: (operation) =>
                                setState(() => _selectedOperation = operation),
                            items: _featureManagementOptions,
                          ),
                          // Display additional UI depending on the selected operation.
                          buildOperationSpecificWidget(),
                        ],
                      ),
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
    );
  }

  Future<void> onMapViewReady() async {
    try {
      // Create and load a service geodatabase from a service URL.
      const featureServiceUri =
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0';
      final serviceGeodatabase =
          ServiceGeodatabase.withUri(Uri.parse(featureServiceUri));
      await serviceGeodatabase.load();

      // Get the feature table from the service geodatabase referencing the Damage Assessment feature service.
      // Creating the feature table from the feature service will cause the service geodatabase to be null.
      _damageServiceFeatureTable = serviceGeodatabase.getTable(layerId: 0)!;
      // Load the table.
      await _damageServiceFeatureTable.load();
      // Get the required field from the table - in this case, damage type.
      final damageTypeField = _damageServiceFeatureTable.fields
          .firstWhere((field) => field.name == 'typdamage');
      // Get the domain for the field.
      final domain = damageTypeField.domain! as CodedValueDomain;
      // Update the dropdown menu with the attribute values from the domain.
      configureAttributeDropdownMenuItems(domain);

      // Create a feature layer to visualize the features in the table.
      _damageFeatureLayer =
          FeatureLayer.withFeatureTable(_damageServiceFeatureTable);
      // Create a map with the ArcGIS Streets basemap.
      final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
      // Add the feature layer to the map's operational layers.
      map.operationalLayers.add(_damageFeatureLayer);
      // Set the map to the map view controller.
      _mapViewController.arcGISMap = map;
      // Zoom to an initial viewpoint.
      _mapViewController.setViewpoint(
        Viewpoint.fromCenter(
          ArcGISPoint(
            x: -10800000,
            y: 4500000,
            spatialReference: SpatialReference.webMercator,
          ),
          scale: 30000000,
        ),
      );
      // Set the ready state variable to true to enable the sample UI.
      setState(() => _ready = true);
    } on ArcGISException catch (e) {
      showMessageDialog('${e.message}.');
    } on Exception {
      showMessageDialog(
        'There was an error loading the data required for the sample.',
      );
    }
  }

  Future<void> onTap(Offset localPosition) async {
    // Configure actions when a user taps on the map, depending on the selected operation.
    if (_selectedOperation == FeatureManagementOperation.create) {
      // Create a feature if create is selected.
      await createFeature(localPosition);
    } else if (_selectedOperation == FeatureManagementOperation.geometry &&
        _selectedFeature != null) {
      // If update geometry is selected, update the selected feature.
      await updateGeometry(_selectedFeature!, localPosition);
    } else {
      // Otherwise attempt to identify and select a feature.
      await identifyAndSelectFeature(localPosition);
    }
  }

  Future<void> identifyAndSelectFeature(Offset localPosition) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);

    // Unselect any previously selected feature.
    if (_selectedFeature != null) {
      _damageFeatureLayer.unselectFeature(_selectedFeature!);
      setState(() {
        _selectedFeature = null;
        _selectedDamageType = null;
      });
    }

    // Perform an identify operation on the feature layer at the tapped location.
    final identifyResult = await _mapViewController.identifyLayer(
      _damageFeatureLayer,
      screenPoint: localPosition,
      tolerance: 12,
    );

    if (identifyResult.geoElements.isNotEmpty) {
      // If a feature is identified, select it.
      final feature = identifyResult.geoElements.first as ArcGISFeature;
      _damageFeatureLayer.selectFeature(feature);
      setState(() {
        _selectedFeature = feature;
        _selectedDamageType = feature.attributes['typdamage'];
      });
    }
    // Re-enable the UI.
    setState(() => _ready = true);
  }

  Future<void> createFeature(Offset localPosition) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);

    // Create the feature.
    final feature = _damageServiceFeatureTable.createFeature();

    // Get the normalized geometry for the tapped location and use it as the feature's geometry.
    final geometry = _mapViewController.screenToLocation(screen: localPosition);
    if (geometry != null) {
      final normalizedGeometry =
          GeometryEngine.normalizeCentralMeridian(geometry);
      feature.geometry = normalizedGeometry;

      // Set feature attributes.
      feature.attributes['typdamage'] = 'Minor';
      feature.attributes['primcause'] = 'Earthquake';

      // Add the feature to the local table.
      await _damageFeatureLayer.featureTable!.addFeature(feature);

      // Apply the edits to the service on the service geodatabase.
      await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();

      // Update the feature to get the updated objectid - a temporary ID is used before the feature is added.
      feature.refresh();

      // Confirm feature addition.
      showMessageDialog('Created feature ${feature.attributes['objectid']}');
    } else {
      showMessageDialog('Error creating feature, geometry was null.');
    }
    setState(() => _ready = true);
  }

  Future<void> deleteFeature(Feature feature) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);
    // Delete the feature from the local table.
    await _damageFeatureLayer.featureTable!.deleteFeature(feature);
    // Sync the change with the service on the service geodatabase.
    await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
    showMessageDialog(
      'Deleted feature ${feature.attributes['objectid']}.',
    );
    // Reset selected elements and re-enable the UI.
    setState(() {
      _selectedFeature = null;
      _selectedDamageType = null;
      _ready = true;
    });
  }

  Future<void> updateGeometry(
    Feature feature,
    Offset localPosition,
  ) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);

    // Get the normalized geometry for the tapped location and use it as the feature's geometry.
    final newGeometry =
        _mapViewController.screenToLocation(screen: localPosition);
    if (newGeometry != null) {
      final normalizedNewGeometry =
          GeometryEngine.normalizeCentralMeridian(newGeometry);
      feature.geometry = normalizedNewGeometry;
      // Update the feature in the local table.
      await _damageFeatureLayer.featureTable!.updateFeature(feature);
      // Sync the change with the service on the service geodatabase.
      await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
      showMessageDialog(
        'Updated feature ${feature.attributes['objectid']}',
      );
      // Re-enable the UI and deselect the currently selected feature.
      _damageFeatureLayer.unselectFeature(_selectedFeature!);
      setState(() {
        _selectedFeature = null;
        _ready = true;
      });
    }
  }

  Future<void> updateAttribute(Feature feature, String damageType) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);
    // Update the damage type field to the selected value.
    feature.attributes['typdamage'] = damageType;
    // Update the feature in the local table.
    await _damageFeatureLayer.featureTable!.updateFeature(feature);
    // Sync the change with the service on the service geodatabase.
    await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
    showMessageDialog(
      'Updated feature ${feature.attributes['objectid']} to $damageType.',
    );
    // Re-enable the UI.
    setState(() => _ready = true);
  }

  void configureAttributeDropdownMenuItems(CodedValueDomain domain) {
    // Display a dropdown menu item for each coded value in the domain.
    _damageTypeAttributeOptions.addAll(
      domain.codedValues.map(
        (value) => DropdownMenuItem(
          onTap: () => setState(
            () => _selectedDamageType == value.name,
          ),
          value: value.name,
          child: Text(value.name),
        ),
      ),
    );
  }

  Widget buildOperationSpecificWidget() {
    switch (_selectedOperation) {
      case FeatureManagementOperation.create:
        // Display instructions for creating a new feature.
        return const Text('Tap on the map to create a feature.');
      case FeatureManagementOperation.delete:
        // Create a button to delete the selected feature.
        return ElevatedButton(
          onPressed: _selectedFeature != null
              ? () => deleteFeature(_selectedFeature!)
              : null,
          child: const Text('Delete Selected Feature'),
        );
      case FeatureManagementOperation.attribute:
        // Create a dropdown button for updating the attribute value of the selected feature.
        return DropdownButton(
          alignment: Alignment.center,
          hint: Text(
            'Select attribute value',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          disabledHint: const Text(
            'Select a feature',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          value: _selectedDamageType,
          icon: const Icon(Icons.arrow_drop_down),
          style: Theme.of(context).textTheme.labelMedium,
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          iconDisabledColor: Theme.of(context).disabledColor,
          onChanged: _selectedFeature != null
              ? (String? damageType) {
                  if (damageType != null) {
                    setState(() => _selectedDamageType = damageType);
                    updateAttribute(_selectedFeature!, damageType);
                  }
                }
              : null,
          items: _damageTypeAttributeOptions,
        );
      case FeatureManagementOperation.geometry:
        // Display instructions for updating feature geometry.
        return const Text('Tap on the map to move a selected feature.');
      case null:
        // Display default instructions.
        return const Text('Select a feature management operation.');
    }
  }

  String getLabel(FeatureManagementOperation? operation) {
    // Return a UI friendly string for each feature management operation.
    switch (operation) {
      case FeatureManagementOperation.create:
        return 'Create feature';
      case FeatureManagementOperation.delete:
        return 'Delete feature';
      case FeatureManagementOperation.attribute:
        return 'Update attribute';
      case FeatureManagementOperation.geometry:
        return 'Update geometry';
      case null:
        return 'Select a feature management operation.';
    }
  }
}

// Create an enumeration to define the feature management options.
enum FeatureManagementOperation { create, delete, attribute, geometry }
