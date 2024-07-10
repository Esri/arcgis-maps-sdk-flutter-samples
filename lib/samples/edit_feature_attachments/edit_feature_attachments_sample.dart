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
      final feature = features.first as ArcGISFeature;

      _showBottomSheet(feature);
    }
  }

  // show the bottom sheet to display the attachment information.
  void _showBottomSheet(ArcGISFeature? feature) async {
    if (feature == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentsOptions(
        arcGISFeature: feature,
        commitChanges: _commitChanges,
      ),
    ); // end of showModalBottomSheet
  }

  // apply the changes to the feature table.
  void _commitChanges() {
    final serviceFeatureTable =
        _featureLayer.featureTable! as ServiceFeatureTable;
    try {
      serviceFeatureTable.applyEdits();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Error'),
            ),
          ],
        ),
      );
    }
  }
}

//
// A widget to display the attachment information for the selected feature.
//
class AttachmentsOptions extends StatefulWidget {
  final ArcGISFeature arcGISFeature;
  final Function() commitChanges;

  const AttachmentsOptions({
    super.key,
    required this.arcGISFeature,
    required this.commitChanges,
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
                  )
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

        // display a progress indicator.
        Visibility(
          visible: isLoading,
          child: SizedBox.expand(
            child: Container(
              color: Colors.transparent.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }

  // delete an attachment from the selected feature.
  void deleteAttachment(Attachment attachment) async {
    setState(() => isLoading = true);

    await widget.arcGISFeature.deleteAttachment(attachment).then((_) {
      widget.commitChanges();
    });

    _loadAttachments();

    setState(() => isLoading = false);
  }

  // view an attachment from the selected feature in a dialog.
  void viewAttachment(Attachment attachment) async {
    if (!attachment.hasFetchedData) {
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
  }

  // add an attachment to the selected feature
  void addAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() => isLoading = true);

      // Get the file extension
      String fileExtension = file.path.split('.').last.toLowerCase();

      // Use the file extension for determining the content type
      String contentType = 'application/octet-stream'; // Default content type
      switch (fileExtension.toLowerCase()) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.pdf':
          contentType = 'application/pdf';
          break;
        case '.txt':
          contentType = 'text/plain';
          break;
      }

      await widget.arcGISFeature
          .addAttachment(
        contentType: contentType,
        data: file.readAsBytesSync(),
        name: file.path.split('/').last,
      )
          .then((_) {
        widget.commitChanges();
      });

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
}
