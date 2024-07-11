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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class EditFeatureAttachmentsSample extends StatefulWidget {
  const EditFeatureAttachmentsSample({super.key});

  @override
  State<EditFeatureAttachmentsSample> createState() =>
      _EditFeatureAttachmentsSampleState();
}

class _EditFeatureAttachmentsSampleState
    extends State<EditFeatureAttachmentsSample> with SampleStateSupport {
  final _mapViewController = ArcGISMapView.createController();
  final _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0')));
  var _selectedFeature;

  @override
  void initState() {
    super.initState();

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -95.0,
        y: 40.0,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 1e8,
    );
    map.operationalLayers.add(_featureLayer);
    _mapViewController.arcGISMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onTap: onTap,
      ),
    );
  }

  void onTap(Offset localPosition) async {
    _featureLayer.clearSelection();

    // do a identify on the feature layer and select a feature
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _featureLayer,
      screenPoint: localPosition,
      tolerance: 5.0,
      maximumResults: 1,
    );

    // if there are features identified, show the bottom sheet to display the
    // attachment information for the selected feature.
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();
    if (features.isNotEmpty) {
      _featureLayer.selectFeatures(features: features);
      _selectedFeature = features.first as ArcGISFeature;
      _showBottomSheet();
    }
  }

  // show the bottom sheet to display the attachment information.
  void _showBottomSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentsOptions(
        arcGISFeature: _selectedFeature,
        applyEdits: _applyEdits,
      ),
    ); // end of showModalBottomSheet
  }

  // apply the changes to the feature table.
  Future<void> _applyEdits() async {
    final serviceFeatureTable =
        _featureLayer.featureTable! as ServiceFeatureTable;
    try {
      await serviceFeatureTable.updateFeature(_selectedFeature);
      await serviceFeatureTable.applyEdits();
    } catch (e) {
      setState(() {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
    return Future.value();
  }
}

//
// A widget to display the attachment information for the selected feature.
//
class AttachmentsOptions extends StatefulWidget {
  final ArcGISFeature arcGISFeature;
  final Function() applyEdits;

  const AttachmentsOptions({
    super.key,
    required this.arcGISFeature,
    required this.applyEdits,
  });

  @override
  State<AttachmentsOptions> createState() => _AttachmentsOptionsState();
}

// State class for the AttachmentsOptions .
class _AttachmentsOptionsState extends State<AttachmentsOptions>
    with SampleStateSupport {
  late final String damageType;
  var attachments = <Attachment>[];
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    damageType = widget.arcGISFeature.attributes['typdamage'];
    _loadAttachments();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // display the damage type and a close button
            Container(
              color: Colors.purple,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('  Damage Type:  $damageType',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close BottomSheet',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Visibility(
                    visible: isLoading,
                    child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),

            // display the number of attachments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('  Number of Attachments: ${attachments.length}'),
                ElevatedButton(
                  onPressed: addAttachment,
                  child: const Text('Add Attachment'),
                )
              ],
            ),

            const Divider(
              color: Colors.purple,
            ),

            // display each attachment with view and delete buttons
            SingleChildScrollView(
              child: Column(children: [
                ListView.builder(
                  itemCount: attachments.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(2),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(attachments[index].name),
                      subtitle: Text(attachments[index].contentType),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye),
                            onPressed: () => viewAttachment(attachments[index]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                deleteAttachment(attachments[index]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // delete an attachment from the selected feature.
  void deleteAttachment(Attachment attachment) async {
    setState(() => isLoading = true);

    await widget.arcGISFeature.deleteAttachment(attachment).then((_) {
      widget.applyEdits();
    });

    _loadAttachments();

    setState(() => isLoading = false);
  }

  // view an attachment from the selected feature in a dialog.
  void viewAttachment(Attachment attachment) async {
    setState(() => isLoading = true);

    final data = await attachment.fetchData();
    setState(() => isLoading = false);

    // display the attachment image/pdf file in a dialog.
    setState(() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(attachment.name),
            content: SizedBox(
              height: 300,
              child: Image.memory(data),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: () {
                  // save the attachment to the device.
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
                tooltip: 'Close',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  // add an attachment to the selected feature
  void addAttachment() async {
    var status = false;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      onFileLoading: (filePickerStatus) {
        if (filePickerStatus == FilePickerStatus.done) {
          status = true;
        }
        print(filePickerStatus);
      },
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
    );

    if (result != null && status) {
      setState(() => isLoading = true);
      final platformFile = result.files.single;
      final file = File(platformFile.path!);

      // Get the context type for the file
      final fileExtension = platformFile.extension?.toLowerCase();
      final contentType = getContextType(fileExtension ?? 'default');
      final fileBytes = await file.readAsBytes();

      final attachment = await widget.arcGISFeature.addAttachment(
        name: platformFile.name,
        contentType: contentType,
        data: fileBytes,
      );
      if (attachment != null) {
        print(attachment.name);
        //A resource failed to call close. error is thrown when applyEdits is called
        await widget.applyEdits();
      }

      _loadAttachments();
      setState(() => isLoading = false);
    }
  }

  // load and update the attachments for the selected feature
  Future<void> _loadAttachments() async {
    try {
      var fetchedAttachments = await widget.arcGISFeature.fetchAttachments();
      setState(() {
        attachments = fetchedAttachments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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