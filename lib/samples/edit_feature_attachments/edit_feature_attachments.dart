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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class EditFeatureAttachments extends StatefulWidget {
  const EditFeatureAttachments({super.key});

  @override
  State<EditFeatureAttachments> createState() => _EditFeatureAttachmentsState();
}

class _EditFeatureAttachmentsState extends State<EditFeatureAttachments>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a feature layer with a feature table.
  final _featureLayer = FeatureLayer.withFeatureTable(
    ServiceFeatureTable.withUri(
      Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
        onTap: onTap,
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with an ArcGISStreet basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    // Set the initial viewpoint for the map.
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(x: -95, y: 40, spatialReference: SpatialReference.wgs84),
      scale: 100000000,
    );

    // Add the feature layer to the map.
    map.operationalLayers.add(_featureLayer);
    _mapViewController.arcGISMap = map;
  }

  Future<void> onTap(Offset localPosition) async {
    // Clear the selection on the feature layer.
    _featureLayer.clearSelection();

    // Do an identify on the feature layer and select a feature.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _featureLayer,
      screenPoint: localPosition,
      tolerance: 5,
    );

    // If there are features identified, show the bottom sheet to display the
    // attachment information for the selected feature.
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();
    if (features.isNotEmpty) {
      _featureLayer.selectFeatures(features);
      final selectedFeature = features.first as ArcGISFeature;
      if (mounted) _showBottomSheet(selectedFeature);
    }
  }

  // Show the bottom sheet to display the attachment information.
  void _showBottomSheet(ArcGISFeature selectedFeature) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => AttachmentsOptions(
            arcGISFeature: selectedFeature,
            applyEdits: _applyEdits,
          ),
    );
  }

  // Apply the changes to the feature table.
  Future<void> _applyEdits(ArcGISFeature selectedFeature) async {
    final serviceFeatureTable =
        _featureLayer.featureTable! as ServiceFeatureTable;
    try {
      // Update the selected feature locally.
      await serviceFeatureTable.updateFeature(selectedFeature);
      // Apply the edits to the service.
      await serviceFeatureTable.applyEdits();
    } on ArcGISException catch (e) {
      showMessageDialog(e.toString(), title: 'Error', showOK: true);
    }
    return Future.value();
  }
}

//
// A widget to display the attachment information for the selected feature.
//
class AttachmentsOptions extends StatefulWidget {
  const AttachmentsOptions({
    required this.arcGISFeature,
    required this.applyEdits,
    super.key,
  });
  final ArcGISFeature arcGISFeature;
  final Function(ArcGISFeature) applyEdits;

  @override
  State<AttachmentsOptions> createState() => _AttachmentsOptionsState();
}

// State class for the AttachmentsOptions.
class _AttachmentsOptionsState extends State<AttachmentsOptions>
    with SampleStateSupport {
  late final String _damageType;
  var _attachments = <Attachment>[];
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _damageType = widget.arcGISFeature.attributes['typdamage'];
    _loadAttachments();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Display the damage type and a close button.
            Container(
              color: Colors.purple,
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Damage Type: $_damageType',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    const SizedBox.shrink(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Display the number of attachments.
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Number of Attachments: ${_attachments.length}'),
                  ElevatedButton(
                    onPressed: addAttachment,
                    child: const Text('Add Attachment'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.purple),

            // Display each attachment with view and delete buttons.
            SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    itemCount: _attachments.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(2),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_attachments[index].name),
                        subtitle: Text(_attachments[index].contentType),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              onPressed:
                                  () => viewAttachment(_attachments[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => deleteAttachment(_attachments[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Delete an attachment from the selected feature.
  Future<void> deleteAttachment(Attachment attachment) async {
    setState(() => _isLoading = true);
    await widget.arcGISFeature.deleteAttachment(attachment);
    await widget.applyEdits(widget.arcGISFeature);

    await _loadAttachments();
  }

  // View an attachment from the selected feature in a dialog.
  Future<void> viewAttachment(Attachment attachment) async {
    setState(() => _isLoading = true);

    final data = await attachment.fetchData();
    setState(() => _isLoading = false);

    // Display the attachment image/pdf file in a dialog.
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(attachment.name),
            content: SizedBox(height: 300, child: Image.memory(data)),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  // Save the attachment to the device.
                  FilePicker.platform.saveFile(
                    dialogTitle: 'Save Attachment',
                    fileName: attachment.name,
                    bytes: data,
                    lockParentWindow: true,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Add an attachment to the selected feature by FilePicker.
  Future<void> addAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
    );

    if (result != null) {
      setState(() => _isLoading = true);

      final platformFile = result.files.single;
      final file = File(platformFile.path!);

      // Get the context type for the file.
      final fileExtension = platformFile.extension?.toLowerCase();
      final contentType = getContextType(fileExtension ?? 'default');
      final fileBytes = await file.readAsBytes();

      await widget.arcGISFeature.addAttachment(
        name: platformFile.name,
        contentType: contentType,
        data: fileBytes,
      );
      await widget.applyEdits(widget.arcGISFeature);
      await _loadAttachments();
    }
  }

  // Load and update the attachments for the selected feature.
  Future<void> _loadAttachments() async {
    try {
      final fetchedAttachments = await widget.arcGISFeature.fetchAttachments();
      setState(() {
        _attachments = fetchedAttachments;
        _isLoading = false;
      });
    } on ArcGISException catch (e) {
      showMessageDialog(e.toString(), title: 'Error', showOK: true);
      setState(() => _isLoading = false);
    }
  }

  String getContextType(String fileExtension) {
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
