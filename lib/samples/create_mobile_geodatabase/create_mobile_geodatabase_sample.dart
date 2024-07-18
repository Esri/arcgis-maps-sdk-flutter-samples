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

class CreateMobileGeodatabaseSample extends StatefulWidget {
  const CreateMobileGeodatabaseSample({super.key});

  @override
  State<CreateMobileGeodatabaseSample> createState() =>
      _CreateMobileGeodatabaseSampleState();
}

class _CreateMobileGeodatabaseSampleState
    extends State<CreateMobileGeodatabaseSample> with SampleStateSupport {
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
  int _featureCount = 0;

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
                        onTap: onTap,
                      ),
                      // Display a progress indicator and prevent interaction
                      // until state is ready.
                      Visibility(
                        visible: !(_ready),
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
                // Display the number of features added and a button to view the table.
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Number of features added: $_featureCount',
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          side: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        onPressed: _displayTable,
                        child: const Text(
                          'View table',
                        ),
                      ),
                    ],
                  ),
                ),
                // Display a button to create and share the mobile geodatabase.
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: ElevatedButton.icon(
                    onPressed: _shareGeodatabaseUri,
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Create and share mobile geodatabase',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    //_mapViewController.dispose();
    _geodatabase?.close();
    _geodatabase = null;
    _featureTable = null;
    super.dispose();
  }

  // When the map view is ready, create a map and set the viewpoint.
  void onMapViewReady() {
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
    _createGeodatabase();

    setState(() => _ready = true);
  }

  // When the map is tapped, add a feature to the feature table.
  void onTap(Offset localPosition) {
    _addFeature(
      _mapViewController.screenToLocation(
        screen: localPosition,
      )!,
    );
  }

  // Create a mobile geodatabase and a feature table to store location history.
  void _createGeodatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final geodatabaseFile = File(
        '${directory.path}${Platform.pathSeparator}localHistory.geodatabase');
    if (geodatabaseFile.existsSync()) {
      geodatabaseFile.deleteSync();
    }
    _geodatabase?.close();

    Geodatabase.create(fileUri: geodatabaseFile.uri).then(
      (newGeodatabase) {
        _geodatabase = newGeodatabase;
        _createGeodatabaseFeatureTable();
      },
    ).onError(
      (error, stackTrace) {
        _showDialog(
          'Error',
          error.toString(),
        );
      },
    );
  }

  // Create a feature table to store location history.
  void _createGeodatabaseFeatureTable() {
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

    _geodatabase!.createTable(tableDescription: tableDescription).then(
      (featureTable) {
        _map.operationalLayers.clear();
        _map.operationalLayers.add(
          FeatureLayer.withFeatureTable(featureTable),
        );
        _featureTable = featureTable;

        setState(() => _featureCount = _featureTable!.numberOfFeatures);
      },
    ).onError(
      (error, stack) {
        _showDialog(
          'Error',
          error.toString(),
        );
      },
    );
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

    List<DataRow> dataRow = [];
    for (final f in queryResult!.features()) {
      dataRow.add(
        DataRow(
          cells: [
            DataCell(
              Text(
                f.attributes['oid'].toString(),
              ),
            ),
            DataCell(
              Text(
                f.attributes['collection_timestamp'].toString(),
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
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
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
                    rows: dataRow,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                child: Text(
                  'Attribute table loaded from the mobile geodatabase '
                  'file. File can be loaded on ArcGIS Pro or ArcGIS Runtime.',
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

    final shareResult = await Share.share(
      subject: 'Sharing the geodatabase',
      _geodatabase!.fileUri.path,
    );

    if (shareResult.status == ShareResultStatus.success) {
      _showDialog('Success', 'The geodatabase was shared successfully.');
    } else {
      _showDialog('Error', 'The geodatabase could not be shared.');
    }
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
