//
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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/sample_state_support.dart';

class CreateMobileGeodatabase extends StatefulWidget {
  const CreateMobileGeodatabase({super.key});

  @override
  State<CreateMobileGeodatabase> createState() =>
      _CreateMobileGeodatabaseState();
}

class _CreateMobileGeodatabaseState extends State<CreateMobileGeodatabase>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Declare a map to be loaded later.
  late final ArcGISMap _map;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A mobile Geodatabase to be created and shared.
  Geodatabase? _geodatabase;
  // A feature table to store the location history.
  GeodatabaseFeatureTable? _featureTable;
  // A counter to keep track of the number of features added.
  var _featureCount = 0;

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
                  child: Stack(
                    children: [
                      // Add a map view to the widget tree and set a controller.
                      ArcGISMapView(
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                        onTap: _ready ? onTap : null,
                      ),
                    ],
                  ),
                ),
                // Display the number of features added and a button to view the table.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    0,
                    10,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Number of features added: $_featureCount',
                      ),
                      ElevatedButton(
                        onPressed: _featureCount > 0 ? _displayTable : null,
                        child: const Text(
                          'View table',
                        ),
                      ),
                    ],
                  ),
                ),
                // Display a button to create and share the mobile geodatabase.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    10,
                    0,
                    10,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _featureCount > 0 ? _shareGeodatabaseUri : null,
                    icon: const Icon(
                      Icons.share,
                    ),
                    label: const Text(
                      'Share Mobile Geodatabase',
                    ),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction
            // until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _geodatabase?.close();
    _geodatabase = null;
    _featureTable = null;
    super.dispose();
  }

  // When the map view is ready, create a map and set the viewpoint.
  void onMapViewReady() async {
    _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = _map;
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 41.5,
        longitude: -100.0,
        scale: 100000000.0,
      ),
    );
    // Create the mobile geodatabase with a feature table to track
    // location history.
    await _setupGeodatabase();

    setState(() => _ready = true);
  }

  // When the map is tapped, add a feature to the feature table.
  void onTap(Offset localPosition) {
    final mapPoint = _mapViewController.screenToLocation(
      screen: localPosition,
    );
    if (mapPoint != null) _addFeature(mapPoint);
  }

  // Create a mobile geodatabase and a feature table to store location history.
  Future<void> _setupGeodatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final geodatabaseFile = File(
      '${directory.path}${Platform.pathSeparator}localHistory.geodatabase',
    );
    if (geodatabaseFile.existsSync()) geodatabaseFile.deleteSync();

    try {
      _geodatabase = await Geodatabase.create(fileUri: geodatabaseFile.uri);
      await _createGeodatabaseFeatureTable();
    } catch (e) {
      _showDialog(
        'Error',
        e.toString(),
      );
    }
    return Future.value();
  }

  // Create a feature table to store location history.
  Future<void> _createGeodatabaseFeatureTable() async {
    // Create and define a table description for the feature table.
    final tableDescription = TableDescription(
      name: 'LocationHistory',
    )
      ..geometryType = GeometryType.point
      ..spatialReference = SpatialReference.wgs84
      ..hasAttachments = false
      ..hasM = false
      ..hasZ = false;

    tableDescription.fieldDescriptions.addAll(
      [
        FieldDescription(
          name: 'oid',
          fieldType: FieldType.oid,
        ),
        FieldDescription(
          name: 'collection_timestamp',
          fieldType: FieldType.date,
        ),
      ],
    );

    // Create the feature table and add the associated feature layer to the map.
    try {
      _featureTable =
          await _geodatabase!.createTable(tableDescription: tableDescription);
      _map.operationalLayers.clear();
      _map.operationalLayers.add(
        FeatureLayer.withFeatureTable(_featureTable as GeodatabaseFeatureTable),
      );
      setState(() => _featureCount = _featureTable!.numberOfFeatures);
    } catch (e) {
      _showDialog(
        'Error',
        e.toString(),
      );
    }
    return Future.value();
  }

  // Add a feature to the feature table.
  void _addFeature(ArcGISPoint point) async {
    if (_featureTable == null) {
      return;
    }

    final attributes = {
      'collection_timestamp': DateTime.now(),
    };
    final newFeature = _featureTable!.createFeature(
      attributes: attributes,
      geometry: point,
    );
    await _featureTable!.addFeature(newFeature);
    setState(() => _featureCount = _featureTable!.numberOfFeatures);
  }

  // Display the attribute table in a dialog.
  void _displayTable() async {
    final queryResult =
        await _featureTable?.queryFeatures(parameters: QueryParameters());

    final dataRows = <DataRow>[];
    for (final feature in queryResult!.features()) {
      dataRows.add(
        DataRow(
          cells: [
            DataCell(
              Text(
                feature.attributes['oid'].toString(),
              ),
            ),
            DataCell(
              Text(
                feature.attributes['collection_timestamp'].toString(),
              ),
            ),
          ],
        ),
      );
    }
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return SimpleDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  5,
                  15,
                  10,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.all(),
                    columns: const [
                      DataColumn(
                        label: Text('OID'),
                      ),
                      DataColumn(
                        label: Text('Collection Timestamp'),
                      ),
                    ],
                    rows: dataRows,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  15,
                  0,
                  15,
                  10,
                ),
                child: Text(
                  'Attribute table loaded from the mobile geodatabase '
                  'file. File can be loaded on ArcGIS Pro or ArcGIS Maps SDK.',
                  style: TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // Call platform share sheet and share the mobile geodatabase file URI.
  void _shareGeodatabaseUri() async {
    _geodatabase?.close();

    // Open the platform share sheet and share the mobile geodatabase file URI.
    await Share.share(
      subject: 'Sharing the geodatabase',
      _geodatabase!.fileUri.path,
    );

    // Create a new mobile geodatabase and feature table to start again.
    _setupGeodatabase();
  }

  // Display a dialog with a title and message.
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
        );
      },
    );
  }
}
