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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class EditWithBranchVersioning extends StatefulWidget {
  const EditWithBranchVersioning({super.key});

  @override
  State<EditWithBranchVersioning> createState() =>
      _EditWithBranchVersioningState();
}

class _EditWithBranchVersioningState extends State<EditWithBranchVersioning>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create an instance of the model class for this sample.
  final _model = EditWithBranchVersioningModel();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A boolean value indicating whether bottom feature sheet is available.
  bool _featureBottomSheetVisible = false;

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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to open a bottom sheet for creating a new branch version.
                    ElevatedButton(
                      onPressed: () async {
                        await showCreateVersionModalBottomSheet(
                          context,
                          _model,
                        );
                      },
                      child: const Text('Create'),
                    ),
                    // A button to select a version to switch to.
                    ElevatedButton(
                      onPressed: _model.isVersionCreated
                          ? () => showSwitchVersionDialog(context, _model)
                          : null,
                      child: const Text('Switch'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a banner with the current version at the top.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _model.currentVersionNameNotifier,
                        builder: (context, currentVersionName, child) {
                          return Text(
                            'Version: $currentVersionName',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // The Feature Details bottom sheet.
      bottomSheet: _featureBottomSheetVisible
          ? buildFeatureDetails(context, _model.selectedFeature!)
          : null,
    );
  }

  Future<void> onMapViewReady() async {
    // Call the setUp method in the model class to configure the service geodatabase and feature layer.
    await _model.setUp();

    // Set the configured map to the map view controller.
    _mapViewController.arcGISMap = _model.map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    if (_model.selectedFeature != null && !_model.onDefaultVersion) {
      final mapPoint =
          _mapViewController.screenToLocation(screen: localPosition);

      // Show the move confirmation dialog if a feature is already selected.
      _showMoveConfirmationDialog(_model.selectedFeature!, mapPoint!);
      return;
    } else {
      // Clear the selection of the feature layer.
      _model.clearSelection();
    }

    // Do an identify on the feature layer and select a feature.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _model.featureLayer,
      screenPoint: localPosition,
      tolerance: 5,
    );

    // If there are features identified select the first feature.
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();

    if (features.isNotEmpty) {
      _model.selectFeature(features.first);

      // Show the bottom modal sheet with the feature's attributes.
      if (mounted) {
        setState(() {
          _featureBottomSheetVisible = true;
        });
      }
    }
  }

  Widget buildFeatureDetails(BuildContext context, Feature feature) {
    // Get the required feature attributes.
    final placeName = feature.attributes['placename'] as String?;
    final damageType = feature.attributes['typdamage'] as String?;

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
                placeName ?? 'Feature Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _featureBottomSheetVisible = false;
                  _model.clearSelection();
                }),
              ),
            ],
          ),
          const Divider(),
          Text('Damage Type: ${damageType ?? 'Unknown'}'),
          const Divider(),
          TextButton(
            onPressed: _model.onDefaultVersion
                ? null
                : () {
                    setState(() {
                      _editDamageType(feature);
                    });
                  },
            child: const Text('Edit Damage Type'),
          ),
        ],
      ),
    );
  }

  void _showMoveConfirmationDialog(Feature feature, ArcGISPoint mapPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Move'),
        content: const Text('Do you want to move the selected feature?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _model.clearSelection();
              setState(() => _featureBottomSheetVisible = false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                feature.geometry = mapPoint;
                _model.updateFeature();
                setState(() => _featureBottomSheetVisible = false);
              });
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _editDamageType(Feature feature) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Damage Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: DamageType.values.map((damageType) {
              return ListTile(
                title: Text(damageType.label),
                onTap: () {
                  Navigator.of(context).pop();

                  // Update the feature's attribute with the selected value.
                  feature.attributes['typdamage'] = damageType.name;
                  _model.updateFeature();

                  setState(() {
                    _featureBottomSheetVisible = false;
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> showCreateVersionModalBottomSheet(
    BuildContext context,
    EditWithBranchVersioningModel model,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedAccess = VersionAccess.public;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          ),
                          TextField(
                            controller: descriptionController,
                            decoration:
                                const InputDecoration(labelText: 'Description'),
                          ),
                          DropdownButton(
                            value: selectedAccess,
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setModalState(() {
                                  // Update the selected access value when a new value is selected from the dropdown menu.
                                  selectedAccess = newValue;
                                });
                              }
                            },
                            // Display the version access values in a dropdown.
                            items: VersionAccess.values.map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value.name),
                              );
                            }).toList(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  // Create a new version by defining service version parameters from the user input.
                                  if (nameController.text.isNotEmpty) {
                                    final parameters =
                                        ServiceVersionParameters()
                                          ..name = nameController.text
                                          ..description =
                                              descriptionController.text
                                          ..access = selectedAccess;

                                    try {
                                      await model.createVersion(parameters);
                                      setState(() {
                                        model.isVersionCreated = true;
                                        Navigator.of(context).pop();
                                      });
                                    } on ArcGISException catch (e) {
                                      setState(() async {
                                        Navigator.of(context).pop();

                                        // Show an error message if an exception occurs.
                                        await showDialog<void>(
                                          context: context,
                                          builder: (context) {
                                            var errorMessageStrings = e
                                                .additionalMessage
                                                .split(RegExp(r'\s+'));

                                            if (errorMessageStrings
                                                .contains('Extended')) {
                                              errorMessageStrings =
                                                  errorMessageStrings.sublist(
                                                0,
                                                errorMessageStrings.length - 4,
                                              );
                                            }
                                            final cleanedMessage =
                                                errorMessageStrings.join(' ');
                                            return AlertDialog(
                                              title: const Text('Error'),
                                              content: Text(
                                                'Error: $cleanedMessage',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      });
                                    }
                                  } else {
                                    // Show an error message if the fields are empty.
                                    await showDialog<void>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Error'),
                                          content: const Text(
                                            'Name cannot be empty',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                child: const Text('Create'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showSwitchVersionDialog(
    BuildContext context,
    EditWithBranchVersioningModel model,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Switch Version'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: model.existingVersionNames.map((versionName) {
              return ListTile(
                title: Text(versionName),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await model.switchToVersion(versionName);
                    // catch ArcGISException when switching to a version fails.
                    // ignore: avoid_catches_without_on_clauses
                  } catch (e) {
                    setState(() async {
                      // Show an error message if an exception occurs.
                      await showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: Text('Error: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    });
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// A model class to manage the service data, branch versions, and features that are used in this sample.
class EditWithBranchVersioningModel extends ChangeNotifier {
  EditWithBranchVersioningModel() {
    // Initialize the current version name with the default version name from the service geodatabase.
    currentVersionNameNotifier.value = serviceGeodatabase.defaultVersionName;
  }

  // The names of the versions added by the user.
  //
  // - Note: To get a full list of existing versions in the service geodatabase, use `ServiceGeodatabase.versions`.
  // In this sample, only the default version and versions created in current session are shown.
  final existingVersionNames = <String>[];

  // Initially center the map's viewpoint on Naperville, IL, USA.
  final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets)
    ..initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -9811970,
        y: 5127180,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 4000,
    );

  // Create a service geodatabase from a feature service URL.
  final serviceGeodatabase = ServiceGeodatabase.withUri(
    Uri.parse(
      'https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer',
    ),
  );

  // Use a ValueNotifier to track the current version name.
  final currentVersionNameNotifier = ValueNotifier<String>('');

  // Update the current version name and notify listeners.
  void updateCurrentVersionName() {
    currentVersionNameNotifier.value = serviceGeodatabase.versionName;
  }

  late FeatureLayer featureLayer;
  Feature? selectedFeature;

  // A boolean value indicating whether the geodatabase's current version is its default version.
  bool get onDefaultVersion =>
      serviceGeodatabase.versionName == serviceGeodatabase.defaultVersionName;

  // A boolean value indicating whether a version has been created.
  bool isVersionCreated = false;

  // Sets up the service geodatabase and feature layer.
  Future<void> setUp() async {
    // Adds the credential to access the feature service for the service geodatabase.
    final credential = await getPublicSampleCredential();
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore
        .add(credential: credential);
    await serviceGeodatabase.load();
    existingVersionNames.add(serviceGeodatabase.defaultVersionName);

    // Update the current version name after loading the service geodatabase.
    updateCurrentVersionName();

    // Creates a feature layer from the geodatabase and adds it to the map.
    final serviceFeatureTable = serviceGeodatabase.getTable(layerId: 0)!;
    featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);
    map.operationalLayers.add(featureLayer);
  }

  // Creates a new version in the service using given parameters.
  // - ServiceVersionParameters parameters: The properties of the new version.
  // - Returns: The name of the created version.
  Future<String> createVersion(ServiceVersionParameters parameters) async {
    final versionInfo =
        await serviceGeodatabase.createVersion(newVersion: parameters);
    existingVersionNames.add(versionInfo.name);
    // Set the flag to true when a version is created.
    isVersionCreated = true;
    // Switch to the newly created version.
    await switchToVersion(versionInfo.name);

    return versionInfo.name;
  }

  // Switches the geodatabase version to a version with a given name.
  // - Parameter versionName: The name of the version to connect to.
  Future<void> switchToVersion(String versionName) async {
    if (onDefaultVersion) {
      // Discards the local edits when on the default branch.
      // Making edits on default branch is disabled, but this is left here for parity.
      await serviceGeodatabase.undoLocalEdits();
    } else {
      // Applies the local edits when on a user created branch.
      await serviceGeodatabase.applyEdits();
    }
    clearSelection();
    await serviceGeodatabase.switchVersion(versionName: versionName);
    // Update the current version name.
    updateCurrentVersionName();
  }

  // Selects a feature on the feature layer.
  void selectFeature(Feature feature) {
    featureLayer.selectFeature(feature);
    selectedFeature = feature;
  }

  // Clears the selected feature.
  void clearSelection() {
    featureLayer.clearSelection();
    selectedFeature = null;
  }

  // Updates the selected feature in it's feature table.
  Future<void> updateFeature() async {
    if (selectedFeature?.featureTable == null) return;
    await selectedFeature!.featureTable!.updateFeature(selectedFeature!);
    clearSelection();
  }

  Future<ArcGISCredential> getPublicSampleCredential() async {
    // The public credentials for the data in this sample.
    // Note: Never hardcode login information in a production application. This is done solely for the sake of the sample.
    final credential = await TokenCredential.create(
      uri: Uri.parse(
        'https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer',
      ),
      username: 'editor01',
      password: 'S7#i2LWmYH75',
    );
    return credential;
  }
}

// The damage type of a feature.
enum DamageType {
  destroyed,
  major,
  minor,
  affected,
  inaccessible,
  defaultType;

  String get label {
    switch (this) {
      case DamageType.destroyed:
        return 'Destroyed';
      case DamageType.major:
        return 'Major';
      case DamageType.minor:
        return 'Minor';
      case DamageType.affected:
        return 'Affected';
      case DamageType.inaccessible:
        return 'Inaccessible';
      case DamageType.defaultType:
        return 'Default';
    }
  }
}
