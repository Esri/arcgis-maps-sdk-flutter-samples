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
import 'package:flutter/material.dart';

class ManageFeatures extends StatefulWidget {
  const ManageFeatures({super.key});

  @override
  State<ManageFeatures> createState() => _ManageFeaturesState();
}

class _ManageFeaturesState extends State<ManageFeatures> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  late final ServiceFeatureTable _damageServiceFeatureTable;
  late final FeatureLayer _damageFeatureLayer;

  // Create a list of feature management options.
  final _featureManagementOptions =
      <DropdownMenuItem<FeatureManagementOperation>>[];
  // Create a variable to store the selected feature layer source.
  FeatureManagementOperation? _selectedOperation;

  final _damageTypeAttributeOptions = <DropdownMenuItem<String>>[];
  String? _selectedDamageType;

  ArcGISFeature? _selectedFeature;

  final attributeName = 'typdamage';

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();

    // Add each feature management operation to the list of options.
    FeatureManagementOperation.values
        .map(
          (operation) => _featureManagementOptions.add(
            DropdownMenuItem(
              onTap: () => setState(
                () => _selectedOperation == operation,
              ),
              value: operation,
              child: Text(operation.name),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
                    // Create a dropdown button to select a feature management operation.
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Create a dropdown button to select the attribute value.
                        Visibility(
                          visible: _selectedOperation ==
                                  FeatureManagementOperation.attribute &&
                              _selectedFeature != null,
                          child: DropdownButton(
                            alignment: Alignment.center,
                            hint: const Text(
                              'Select attribute value',
                              style: TextStyle(
                                color: Colors.deepPurple,
                              ),
                            ),
                            // Set the selected operation.
                            value: _selectedDamageType,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.deepPurple,
                            ),
                            elevation: 16,
                            style: const TextStyle(color: Colors.deepPurple),
                            // Set the onChanged callback to update the selected operation.
                            onChanged: (damageType) {
                              if (damageType != null) {
                                updateAttribute(damageType);
                              }
                            },
                            items: _damageTypeAttributeOptions,
                          ),
                        ),
                        // Create a button to delete the selected feature.
                        Visibility(
                          visible: _selectedOperation ==
                                  FeatureManagementOperation.delete &&
                              _selectedFeature != null,
                          child: ElevatedButton(
                            onPressed: deleteSelectedFeature,
                            child: const Text('Delete Feature'),
                          ),
                        ),
                        DropdownButton(
                          alignment: Alignment.center,
                          hint: const Text(
                            'Select operation',
                            style: TextStyle(
                              color: Colors.deepPurple,
                            ),
                          ),
                          // Set the selected operation.
                          value: _selectedOperation,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.deepPurple,
                          ),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          // Set the onChanged callback to update the selected operation.
                          onChanged: (operation) =>
                              setState(() => _selectedOperation = operation),
                          items: _featureManagementOptions,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Display a prompt relating to the selected operation.
            Container(
              padding: const EdgeInsets.all(10.0),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Expanded(child: getCurrentText())],
              ),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    const featureServiceURL =
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0';
    // Create and load a service geodatabase from a service URL.
    final serviceGeodatabase =
        ServiceGeodatabase.withUri(Uri.parse(featureServiceURL));
    await serviceGeodatabase.load();

    // Get the feature table from the service geodatabase referencing the Damage Assessment feature service.
    // Creating the feature table from the feature service will cause the service geodatabase to be null.
    final table = serviceGeodatabase.getTable(layerId: 0);
    if (table != null) {
      _damageServiceFeatureTable = table;
      await _damageServiceFeatureTable.load();
      // Get the required field from the feature table - in this case, damage type.
      final typeDamageField =
          table.fields.firstWhere((field) => field.name == attributeName);
      // Get the domain for the field.
      final domain = typeDamageField.domain as CodedValueDomain;
      // Update the dropdown menu with the attribute values.
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
          scale: 3e7,
        ),
      );
      // Set the ready state variable to true to enable the sample UI.
      setState(() => _ready = true);
    } else {
      showMessageDialog(
        'Unable to access the required feature table.',
      );
    }
  }

  void onTap(Offset localPosition) async {
    if (_selectedOperation == FeatureManagementOperation.create) {
      createFeature(localPosition);
    } else {
      await identifyAndSelectFeature(localPosition);
    }
  }

  void createFeature(Offset localPosition) async {
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

      // Add the feature to the table.
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
  }

  void deleteSelectedFeature() async {
    if (_selectedFeature != null) {
      await _damageServiceFeatureTable.deleteFeature(_selectedFeature!);
      // Sync the change with the service on the service geodatabase.
      await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
      showMessageDialog(
        'Successfully deleted feature ${_selectedFeature!.attributes['objectid']}.',
      );
      // Reset selected elements.
      setState(() {
        _selectedFeature = null;
        _selectedDamageType = null;
      });
    }
  }

  void showMessageDialog(String message) {
    // Show a dialog with the provided message.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
        );
      },
    );
  }

  Widget getCurrentText() {
    var text = '';
    switch (_selectedOperation) {
      case FeatureManagementOperation.create:
        text = 'Tap on the map to create a feature.';
      case FeatureManagementOperation.delete:
        text = 'Tap on a feature to select and then tap delete.';
      case FeatureManagementOperation.attribute:
        text = 'Tap on a feature and select a new attribute value.';
      case FeatureManagementOperation.geometry:
        text =
            'Tap on a feature to select and then tap on the map to move the feature.';
      default:
        text = 'Select a feature management operation.';
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
    );
  }

  void configureAttributeDropdownMenuItems(CodedValueDomain domain) {
    domain.codedValues
        .map(
          (value) => _damageTypeAttributeOptions.add(
            DropdownMenuItem(
              onTap: () => setState(
                () => _selectedDamageType == value.name,
              ),
              value: value.name,
              child: Text(value.name),
            ),
          ),
        )
        .toList();
  }

  Future<void> identifyAndSelectFeature(Offset localPosition) async {
    setState(() => _ready = false);
    final identifyResult = await _mapViewController.identifyLayer(
      _damageFeatureLayer,
      screenPoint: localPosition,
      tolerance: 12.0,
      maximumResults: 1,
    );

    // Update or deselect existing selected features.
    if (_selectedFeature != null) {
      if (_selectedOperation == FeatureManagementOperation.geometry) {
        // If update geometry is selected, update the selected feature.
        await updateSelectedFeatureGeometry(localPosition);
        setState(() => _ready = true);
        return;
      } else {
        // Unselect any previously selected feature.
        _damageFeatureLayer.unselectFeature(_selectedFeature!);
        setState(() {
          _selectedFeature = null;
          _selectedDamageType = null;
        });
      }
    }

    if (identifyResult.geoElements.isNotEmpty) {
      // If a feature is identified, select it.
      final feature = identifyResult.geoElements.first as ArcGISFeature;
      _damageFeatureLayer.selectFeature(feature);
      setState(() {
        _selectedFeature = feature;
        _selectedDamageType = feature.attributes[attributeName];
      });
    }
    setState(() => _ready = true);
  }

  Future<void> updateSelectedFeatureGeometry(Offset localPosition) async {
    if (_selectedFeature != null) {
      final newGeometry =
          _mapViewController.screenToLocation(screen: localPosition);
      if (newGeometry != null) {
        final normalizedNewGeometry =
            GeometryEngine.normalizeCentralMeridian(newGeometry);
        await _selectedFeature!.load();
        _selectedFeature!.geometry = normalizedNewGeometry;
        await _damageServiceFeatureTable.updateFeature(_selectedFeature!);
        await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
        showMessageDialog(
          'Successfully updated feature ${_selectedFeature!.attributes['objectid']}',
        );
      }
    }
  }

  Future<void> updateAttribute(String damageType) async {
    if (_selectedFeature != null) {
      setState(() => _ready = false);
      await _selectedFeature!.load();
      _selectedFeature!.attributes[attributeName] = damageType;
      await _damageServiceFeatureTable.updateFeature(_selectedFeature!);
      await _damageServiceFeatureTable.serviceGeodatabase!.applyEdits();
      setState(() {
        _selectedDamageType = damageType;
        _ready = true;
      });
      showMessageDialog(
          'Updated feature ${_selectedFeature!.attributes['objectid']} to $damageType.');
    }
  }
}

// Create an enumeration to define the feature management options.
enum FeatureManagementOperation { create, delete, attribute, geometry }
