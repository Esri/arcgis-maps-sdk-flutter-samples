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

class EditGeodatabaseWithTransactions extends StatefulWidget {
  const EditGeodatabaseWithTransactions({super.key});

  @override
  State<EditGeodatabaseWithTransactions> createState() =>
      _EditGeodatabaseWithTransactionsState();
}

class _EditGeodatabaseWithTransactionsState
    extends State<EditGeodatabaseWithTransactions>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();

  // The local geodatabase.
  Geodatabase? _geodatabase;

  // Variables to manage sample state.
  var _ready = false;
  var _statusText = 'Tap Start to begin a transaction.';
  var _isInTransaction = false;
  var _transactionIsRequired = true;

  // Stores the downloaded geodatabase path.
  var _saveTheBayPath = '';

  @override
  void initState() {
    super.initState();
    _initDownloadResources();
  }

  // Get the downloaded geodatabase path.
  void _initDownloadResources() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _saveTheBayPath = listPaths.first;
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
                MapBanner(text: _statusText),
                Expanded(
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: onTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requires Transaction'),
                        value: _transactionIsRequired,
                        onChanged: _isInTransaction
                            ? null
                            : (value) {
                                setState(() {
                                  _transactionIsRequired = value;

                                  _statusText = value
                                      ? 'Tap Start to begin a transaction.'
                                      : 'Transactions are disabled.';
                                });
                              },
                      ),
                      const SizedBox(height: 12),
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

    final geodatabaseFile = File(_saveTheBayPath);

    // Create and load the geodatabase.
    _geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await _geodatabase!.load();

    // Add feature tables as feature layers.
    for (final table in _geodatabase!.geodatabaseFeatureTables) {
      final layer = FeatureLayer.withFeatureTable(table);

      map.operationalLayers.add(layer);

      // Set display names.
      if (table.tableName == 'Save_The_Bay_Marine_Sync') {
        table.displayName = 'Marine';
      }

      if (table.tableName == 'Save_The_Bay_Birds_Sync') {
        table.displayName = 'Bird';
      }
    }

    setState(() {
      _ready = true;
    });
  }

  // Handle map taps.
  Future<void> onTap(Offset offset) async {
    if (!_isInTransaction) {
      return;
    }

    if (_geodatabase == null) {
      return;
    }

    final mapPoint = _mapViewController.screenToLocation(screen: offset);

    if (mapPoint == null) {
      return;
    }

    // Get the marine and bird feature tables.
    final marineTable = _geodatabase!.geodatabaseFeatureTables.firstWhere(
      (table) => table.tableName == 'Save_The_Bay_Marine_Sync',
    );

    final birdTable = _geodatabase!.geodatabaseFeatureTables.firstWhere(
      (table) => table.tableName == 'Save_The_Bay_Birds_Sync',
    );

    // Load the feature tables.
    await marineTable.load();
    await birdTable.load();

    if (!mounted) return;

    // Show a sheet to select a feature type.
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var selectedTable = marineTable;
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
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'New Feature',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: selectedType == null
                                ? null
                                : () {
                                    Navigator.pop(context, {
                                      'table': selectedTable,
                                      'type': selectedType,
                                    });
                                  },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Feature Type',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ToggleButtons(
                        isSelected: [
                          selectedTable.tableName == 'Save_The_Bay_Marine_Sync',
                          selectedTable.tableName == 'Save_The_Bay_Birds_Sync',
                        ],
                        onPressed: (index) {
                          setSheetState(() {
                            selectedType = null;

                            selectedTable = index == 0
                                ? marineTable
                                : birdTable;
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
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedTable.featureTypes.length,
                        itemBuilder: (context, index) {
                          final featureType = selectedTable.featureTypes
                              .elementAt(index);

                          return ListTile(
                            title: Text(featureType.name),
                            trailing: selectedType == featureType
                                ? const Icon(Icons.check)
                                : null,
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

    if (result == null) {
      return;
    }

    final selectedTable = result['table'] as GeodatabaseFeatureTable;

    final selectedType = result['type'] as FeatureType;

    // Create a feature with the selected type and add it to the table.
    final feature = selectedTable.createFeature(
      attributes: {'type': selectedType.id},
      geometry: mapPoint,
    );

    await selectedTable.addFeature(feature);

    setState(() {
      _statusText = 'Added feature.';
    });
  }

  // Starts or ends a transaction.
  Future<void> _startOrEndTransaction() async {
    if (_geodatabase == null) {
      showMessageDialog('Geodatabase is not loaded.');
      return;
    }

    if (_isInTransaction) {
      await _showEndTransactionDialog();
      return;
    }

    // Begin a transaction.
    _geodatabase!.beginTransaction();

    setState(() {
      _isInTransaction = true;
      _statusText = 'Transaction started.';
    });
  }

  // Show transaction options.
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

                _geodatabase!.commitTransaction();

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

                _geodatabase!.rollbackTransaction();

                setState(() {
                  _isInTransaction = false;
                  _statusText = 'Edits discarded.';
                });
              },
              child: const Text('Rollback'),
            ),
            TextButton(
              onPressed: () {
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
