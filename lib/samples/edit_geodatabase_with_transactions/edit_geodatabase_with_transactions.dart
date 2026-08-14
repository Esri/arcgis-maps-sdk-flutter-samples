// Copyright 2026 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

class EditGeodatabaseWithTransactions extends StatefulWidget {
  const EditGeodatabaseWithTransactions({super.key});

  @override
  State<EditGeodatabaseWithTransactions> createState() =>
      _EditGeodatabaseWithTransactionsState();
}

class _EditGeodatabaseWithTransactionsState
    extends State<EditGeodatabaseWithTransactions>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The local geodatabase used to store and edit feature data.
  late Geodatabase _geodatabase;

  // Indicates whether the sample is ready.
  var _ready = false;

  // The status message displayed in the UI.
  var _statusText = 'Tap Start to begin a transaction.';

  // Tracks whether a transaction is currently active.
  var _isInTransaction = false;

  // Indicates whether edits require a transaction.
  var _transactionIsRequired = true;

  // Stores the downloaded geodatabase path.
  var _saveTheBayPath = '';

  // The name of the marine observations feature table in the local geodatabase.
  static const _marineTableName = 'Save_The_Bay_Marine_Sync';

  // The name of the bird observations feature table in the local geodatabase.
  static const _birdsTableName = 'Save_The_Bay_Birds_Sync';

  // The feature table containing marine observation records.
  late GeodatabaseFeatureTable _marineTable;

  // The feature table containing bird observation records.
  late GeodatabaseFeatureTable _birdTable;

  @override
  void initState() {
    super.initState();
    // Download the required data and initialize the sample.
    _initDownloadResources();
  }

  // Get the downloaded geodatabase path.
  void _initDownloadResources() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _saveTheBayPath = path.join(listPaths.first, 'SaveTheBay.geodatabase');
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
                // Display the current status in the UI.
                MapBanner(text: _statusText),
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: onTap,
                  ),
                ),

                // Display controls for managing transactions.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Allow transactions to be enabled or disabled.
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requires Transaction'),
                        value: _transactionIsRequired,
                        onChanged: (value) {
                          // Update the transaction requirement and status message.
                          setState(() {
                            _transactionIsRequired = value;
                            _statusText = value
                                ? 'Tap Start to begin a transaction.'
                                : 'Transactions are disabled.';
                          });
                        },
                      ),
                      // Add spacing between the controls.
                      const SizedBox(height: 12),

                      // Start or end a transaction.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _transactionIsRequired
                              ? _startOrEndTransaction
                              : null,
                          child: Text(
                            _isInTransaction
                                ? 'End Transaction'
                                : 'Start Transaction',
                          ),
                        ),
                      ),
                    ],
                  ),
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
    // Create a map with an oceans basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);

    // Set the initial viewpoint.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 29.0699,
      longitude: -95.2043,
      scale: 80000,
    );

    // Set the map on the controller.
    _mapViewController.arcGISMap = map;

    // Create and load the geodatabase.
    final geodatabaseFile = File(_saveTheBayPath);
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);

    await geodatabase.load();

    // Store a reference to the opened local geodatabase.
    _geodatabase = geodatabase;

    // Add feature tables as feature layers.
    for (final table in geodatabase.geodatabaseFeatureTables) {
      // Set display names.
      if (table.tableName == _marineTableName) {
        table.displayName = 'Marine';
        _marineTable = table;
      }
      if (table.tableName == _birdsTableName) {
        table.displayName = 'Bird';
        _birdTable = table;
      }
      // Create a feature layer from the table and add it to the map.
      map.operationalLayers.add(FeatureLayer.withFeatureTable(table));
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Handle map taps.
  Future<void> onTap(Offset offset) async {
    // Return if edits are not currently allowed.
    if (_transactionIsRequired && !_isInTransaction) {
      return;
    }

    // Get the map location corresponding to the screen tap.
    final mapPoint = _mapViewController.screenToLocation(screen: offset);

    if (mapPoint == null) {
      return;
    }

    if (!mounted) return;

    // Show a sheet to select a feature type.
    final result = await _showCreateFutureSheet();

    if (result == null) {
      return;
    }

    // Create a feature with the selected type and add it to the table.
    final feature = result.table.createFeature(
      attributes: {'type': result.type.id},
      geometry: mapPoint,
    );

    await result.table.addFeature(feature);

    // Update the status message to indicate that the feature was added successfully.
    setState(() => _statusText = 'Feature Added.');
  }

  Future<({GeodatabaseFeatureTable table, FeatureType type})?>
  _showCreateFutureSheet() async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Default to the marine feature table.
        var selectedTable = _marineTable;

        // Stores the selected feature type.
        FeatureType? selectedType;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: 550,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Dismiss the sheet without creating a feature.
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),

                              // Display the sheet title.
                              const Text(
                                'New Feature',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Return the selected table and feature type.
                              TextButton(
                                onPressed: selectedType == null
                                    ? null
                                    : () {
                                        Navigator.pop(context, (
                                          table: selectedTable,
                                          type: selectedType,
                                        ));
                                      },
                                child: const Text('Done'),
                              ),
                            ],
                          ),

                          // Display a heading for the feature type selection.
                          const Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 8),
                            child: Text(
                              'Feature Type',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),

                          // Allow the user to choose which feature table to add features to.
                          ToggleButtons(
                            isSelected: [
                              selectedTable.tableName == _marineTableName,
                              selectedTable.tableName == _birdsTableName,
                            ],
                            onPressed: (index) {
                              setSheetState(() {
                                // Clear the selected feature type when switching tables.
                                selectedType = null;

                                // Update the selected feature table.
                                selectedTable = index == 0
                                    ? _marineTable
                                    : _birdTable;
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text('Marine'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text('Bird'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Display the available feature types.
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedTable.featureTypes.length,
                        itemBuilder: (context, index) {
                          final featureType = selectedTable.featureTypes
                              .elementAt(index);

                          return ListTile(
                            // Display the feature type name.
                            title: Text(featureType.name),

                            // Indicate the selected feature type.
                            trailing: selectedType == featureType
                                ? const Icon(Icons.check)
                                : null,

                            // Select the feature type.
                            onTap: () {
                              setSheetState(() {
                                selectedType = featureType;
                              });
                            },
                          );
                        },
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

  // Starts or ends a transaction.
  Future<void> _startOrEndTransaction() async {
    if (_isInTransaction) {
      await _showEndTransactionDialog();
      return;
    }

    _geodatabase.beginTransaction();

    // Mark the transaction as active and update the status message.
    setState(() {
      _isInTransaction = true;
      _statusText = 'Transaction started.';
    });
  }

  // Display a dialog for committing or rolling back the current transaction.
  Future<void> _showEndTransactionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Commit Edits'),
          content: const Text(
            'Commit the edits in the transaction to the geodatabase or rollback to discard them.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // Commit the transaction and save the edits to the geodatabase.
                _geodatabase.commitTransaction();

                // Update the UI to indicate that the transaction has ended.
                setState(() {
                  _isInTransaction = false;
                  _statusText = 'Edits committed to geodatabase.';
                });
              },
              child: const Text('Commit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // Roll back the transaction and discard any pending edits.
                _geodatabase.rollbackTransaction();

                // Update the UI to indicate that the transaction has ended.
                setState(() {
                  _isInTransaction = false;
                  _statusText = 'Edits discarded.';
                });
              },
              child: const Text('Rollback'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog without changing the transaction state.
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
