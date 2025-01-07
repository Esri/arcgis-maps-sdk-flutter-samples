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

// ViewModel Class
class EditWithBranchVersioningModel extends ChangeNotifier {
  EditWithBranchVersioningModel() {
    // Initialize the current version name.
    currentVersionNameNotifier.value = serviceGeodatabase.defaultVersionName;
  }

  // The names of the versions added by the user.
  //
  // - Note: To get a full list of versions, use `ServiceGeodatabase.versions`.
  // In this sample, only the default version and versions created in current session are shown.
  final existingVersionNames = <String>[];

  // Initially centers the map's viewpoint on Naperville, IL, USA.
  final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets)
    ..initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -9811970,
        y: 5127180,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 4000,
    );

// A geodatabase connected to the damage assessment feature service.
  final serviceGeodatabase = ServiceGeodatabase.withUri(
    Uri.parse(
      'https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer',
    ),
  );

  // Use a ValueNotifier to track the current version name.
  final currentVersionNameNotifier = ValueNotifier<String>('');

  // Update the current version name and notify listeners
  void updateCurrentVersionName() {
    currentVersionNameNotifier.value = serviceGeodatabase.versionName;
    notifyListeners();
  }

  late FeatureLayer featureLayer;
  Feature? selectedFeature;

// A Boolean value indicating whether the geodatabase's current version it's default version.
  bool get onDefaultVersion =>
      serviceGeodatabase.versionName == serviceGeodatabase.defaultVersionName;

  // A Boolean value indicating whether a version has been created.
  bool isVersionCreated = false;

// Sets up the service geodatabase and feature layer.
  Future<void> setUp() async {
    // Adds the credential to access the feature service for the service geodatabase.
    final credential = await getPublicSampleCredential();
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore
        .add(credential: credential);
    await serviceGeodatabase.load();
    existingVersionNames.add(serviceGeodatabase.defaultVersionName);

    // Update the current version name after loading the service geodatabase
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
    if (selectedFeature == null || selectedFeature!.featureTable == null) {
      return;
    }
    try {
      await selectedFeature!.featureTable!.updateFeature(selectedFeature!);
      clearSelection();
    } catch (e) {
      print('Error updating feature: $e');
    }
  }

  Future<ArcGISCredential> getPublicSampleCredential() async {
    // The public credentials for the data in this sample.
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

class EditWithBranchVersioning extends StatefulWidget {
  const EditWithBranchVersioning({super.key});

  @override
  State<EditWithBranchVersioning> createState() =>
      _EditWithBranchVersioningState();
}

class _EditWithBranchVersioningState extends State<EditWithBranchVersioning> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  final model = EditWithBranchVersioningModel();

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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: () async {
                        await showCreateVersionModalBottomSheet(context, model);
                      },
                      child: const Text('Create'),
                    ),
                    ElevatedButton(
                      onPressed: model.isVersionCreated
                          ? () => showSwitchVersionDialog(context, model)
                          : null,
                      child: const Text('Switch'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a banner with version at the top.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withOpacity(0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: model.currentVersionNameNotifier,
                        builder: (context, currentVersionName, child) {
                          return Text(
                            currentVersionName,
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
    );
  }

  Future<void> onMapViewReady() async {
    await model.setUp();
    final map = model.map;
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    if (model.selectedFeature != null && !model.onDefaultVersion) {
      final mapPoint =
          _mapViewController.screenToLocation(screen: localPosition);

      // Show the move confirmation dialog if a feature is already selected.
      _showMoveConfirmationDialog(model.selectedFeature!, mapPoint!);
    } else {
      // Clear the selection of the feature layer.
      model.clearSelection();
    }

    // Do an identify on the feature layer and select a feature.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      model.featureLayer,
      screenPoint: localPosition,
      tolerance: 5,
    );

    // If there are features identified select the first feature.
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();

    if (features.isNotEmpty) {
      final selectedFeature = features.first;
      model.selectFeature(selectedFeature);

      // Show the bottom modal sheet with the feature's attributes.
      if (mounted) {
        setState(() {
          _showBottomSheet(selectedFeature);
        });
      }
    }
  }

  void _showBottomSheet(Feature feature) {
    final placeName = feature.attributes['placename'] as String?;
    final damageType = feature.attributes['typdamage'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              placeName ?? 'Feature Details',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            alignment: Alignment.centerRight,
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Damage Type: ${damageType ?? 'Unknown'}'),
                      const Divider(),
                      TextButton(
                        onPressed: model.onDefaultVersion
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                _editDamageType(feature);
                              },
                        child: const Text('Edit Damage Type'),
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
  }

  void _showMoveConfirmationDialog(Feature feature, ArcGISPoint mapPoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Move'),
        content: const Text('Do you want to move the selected feature ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              model.clearSelection();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                feature.geometry = mapPoint;
                model.updateFeature();
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
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Damage Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: DamageType.values.map((damageType) {
                return ListTile(
                  title: Text(damageType.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      feature.attributes['typdamage'] = damageType.name;
                      model.updateFeature();
                    });
                  },
                );
              }).toList(),
            ),
          );
        });
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                          DropdownButton<VersionAccess>(
                            value: selectedAccess,
                            onChanged: (VersionAccess? newValue) {
                              if (newValue != null) {
                                setModalState(() {
                                  selectedAccess = newValue;
                                });
                              }
                            },
                            items: VersionAccess.values
                                .map<DropdownMenuItem<VersionAccess>>(
                                    (VersionAccess value) {
                              return DropdownMenuItem<VersionAccess>(
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
                                      });
                                      Navigator.of(context).pop();
                                    } catch (e) {
                                      Navigator.of(context).pop();
                                      // Show an error message if an exception occurs.
                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Error'),
                                            content: Text('Error: $e'),
                                            actions: <Widget>[
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
                                  } else {
                                    // Show an error message if the fields are empty.
                                    await showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Error'),
                                          content: const Text(
                                            'Name cannot be empty',
                                          ),
                                          actions: <Widget>[
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
      builder: (BuildContext context) {
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
                  } catch (e) {
                    // Show an error message if an exception occurs.
                    await showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Error'),
                          content: Text('Error: $e'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
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
