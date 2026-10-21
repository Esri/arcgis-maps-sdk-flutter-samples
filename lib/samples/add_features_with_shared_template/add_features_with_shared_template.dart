//
// Copyright 2026 Esri
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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class AddFeaturesWithSharedTemplate extends StatefulWidget {
  const AddFeaturesWithSharedTemplate({super.key});

  @override
  State<AddFeaturesWithSharedTemplate> createState() =>
      _AddFeaturesWithSharedTemplateState();
}

class _AddFeaturesWithSharedTemplateState
    extends State<AddFeaturesWithSharedTemplate>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create a geometry editor to draw geometries.
  final _geometryEditor = GeometryEditor();

  // The template items available in the UI to select templates for editing.
  final _templateItems = <_TemplateItem>[];

  // The active template item being used to edit.
  _TemplateItem? _activeTemplateItem;

  // Status text to display in a banner.
  var _statusText = 'Loading map and shared templates';

  // A flag to control the visibility of the settings.
  var _settingsVisible = false;

  // A flag to control visibility of editing UI.
  var _isEditing = false;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                // A button to open the template picker. Only visible if editing is not in progress.
                Visibility(
                  visible: !_isEditing,
                  child: ElevatedButton(
                    onPressed: _ready
                        ? () => setState(() => _settingsVisible = true)
                        : null,
                    child: const Text('Select Template'),
                  ),
                ),
                // Buttons for editing. Only visible if editing is in progress.
                Visibility(
                  visible: _isEditing,
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _saveEdits,
                        child: const Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: _discardEdits,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display the current status in a banner.
            MapBanner(text: _statusText),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? _buildBottomSheet(context) : null,
    );
  }

  Future<void> onMapViewReady() async {
    // Create a web map that contains shared templates.
    final map = ArcGISMap.withUri(
      Uri.parse(
        'https://www.maps.arcgis.com/home/item.html?id=b635be46dfb545b888077389ac7f0962',
      ),
    )!;
    // Load the map to access the shared templates.
    await map.load();

    // Get the first service geodatabase from the feature layers.
    final featureLayer = map.operationalLayers.whereType<FeatureLayer>().first;
    final serviceGeodatabase =
        (featureLayer.featureTable! as ServiceFeatureTable).serviceGeodatabase!;
    // Get the shared templates from the service geodatabase.
    final sharedTemplates = await serviceGeodatabase.querySharedTemplates();
    // Create items to use in the UI based on the templates.
    await createTemplateItems(sharedTemplates);

    // Set the geometry editor to the map view.
    _mapViewController.geometryEditor = _geometryEditor;

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the UI.
    setState(() {
      _ready = true;
      _statusText =
          'Open the template picker and select a template to create features.';
    });
  }

  Widget _buildBottomSheet(BuildContext context) {
    return BottomSheetSettings(
      title: 'Select a shared template',
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) {
        return [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 10,
              children: [
                for (final templateItem in _templateItems) ...[
                  ElevatedButton(
                    onPressed: () => _startEditingUsingTemplate(templateItem),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        spacing: 20,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (templateItem.swatch != null)
                            Image.memory(
                              templateItem.swatch!.getEncodedBuffer(),
                            )
                          else
                            const Icon(Icons.add),
                          Column(
                            spacing: 10,
                            children: [
                              Text(templateItem.template.name),
                              Text(
                                'Template type: ${templateItem.template.type.name}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ];
      },
    );
  }

  // Query the shared templates to get the first Preset and first Group template to create items to use in the template picker.
  Future<void> createTemplateItems(
    Map<int, List<SharedTemplate>> sharedTemplates,
  ) async {
    // Sort the shared templates.
    final includedTypes = <SharedTemplateType>{};
    final sortedEntries = sharedTemplates.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    // Loop through the shared templates and get the first preset and first group templates.
    for (final entry in sortedEntries) {
      final layerId = entry.key;
      final templates = entry.value;

      for (final template in templates) {
        final isSupportedType =
            template.type == SharedTemplateType.preset ||
            template.type == SharedTemplateType.group;

        if (!isSupportedType || includedTypes.contains(template.type)) {
          continue;
        }

        // Get a swatch, if there is one.
        try {
          final swatch = await template.createSwatch(layerId: layerId);
          // Create a template item with the swatch to display in the UI and add to the list of template items.
          _templateItems.add(
            _TemplateItem(template: template, layerId: layerId, swatch: swatch),
          );
        } on ArcGISException catch (_) {
          // Create a template without a swatch if it doesn't exost to display in the UI and add to the list of template items.
          _templateItems.add(
            _TemplateItem(template: template, layerId: layerId),
          );
        }

        includedTypes.add(template.type);
      }

      // Only 2 templates are required for the sample.
      if (includedTypes.length == 2) break;
    }
  }

  // Start a point or line sketch using the selected template's default geometry.
  void _startEditingUsingTemplate(_TemplateItem templateItem) {
    setState(() {
      _statusText = 'Place a point, then tap Save or Cancel.';
      _activeTemplateItem = templateItem;
      _isEditing = true;
      _settingsVisible = false;
    });

    // Use the vertex tool.
    _geometryEditor.tool = VertexTool();

    // Get the default construction tool from the template to define the geometry
    final geometryConstructionTool = templateItem.template
        .getDefaultConstructionTool(layerId: templateItem.layerId)!;

    // Start editing with an appropriate geometry type.
    if (geometryConstructionTool.toolType ==
        GeometryConstructionToolType.point) {
      _geometryEditor.startWithGeometryType(GeometryType.point);
    } else if (geometryConstructionTool.toolType ==
        GeometryConstructionToolType.line) {
      _geometryEditor.startWithGeometryType(GeometryType.polyline);
    }
  }

  // Stop the current sketch and reset the UI.
  void _discardEdits() {
    _geometryEditor.stop();

    setState(() {
      _activeTemplateItem = null;
      _isEditing = false;
      _statusText = 'Edit canceled. Open Shared Templates and select a template to create features.';
    });
  }

  // Save the edits locally.
  Future<void> _saveEdits() async {
    setState(() => _statusText = 'Creating feature...');

    // Stop the geometry editor and hold onto the returned geometry.
    final geometry = _geometryEditor.stop();

    try {
      // Create features locally using the template attributes and geometry created with the geometry editor.
      final sharedTemplateSource = _activeTemplateItem!.template.templateSource;
      final featureCreationSet = await sharedTemplateSource.createFeatures(
        sharedTemplate: _activeTemplateItem!.template,
        geometry: geometry,
      );

      // Save the created features to the local geodatabase.
      // Note that this does not apply the changes to the service. Call applyEdits to apply to the server.
      await sharedTemplateSource.addFeatures(
        featureCreationSet: featureCreationSet,
      );
      // Reset the UI if the edit succeeds.
      setState(() {
        _activeTemplateItem = null;
        _isEditing = false;
        _statusText = 'Features saved. Open Shared Templates and select a template to create features.';
      });
    } on ArcGISException catch (e) {
      // If the edits fail to meet the requirements of the template, update the UI.
      setState(() {
        _activeTemplateItem = null;
        _isEditing = false;
        _statusText =
            'Unable to create feature. Error details: ${e.additionalMessage}. \n Open Shared Templates and select a template to create features.';
      });
    }
  }
}

// A class to define a template item used in the UI.
class _TemplateItem {
  const _TemplateItem({
    required this.template,
    required this.layerId,
    this.swatch,
  });

  final SharedTemplate template;
  final int layerId;
  final ArcGISImage? swatch;
}
