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

  // A list holding the template items available for editing.
  final _templateItems = <_TemplateItem>[];

  // The selected template being used to edit.
  _TemplateItem? _selectedTemplate;

  // Status text to display in a banner.
  var _statusText = 'Loading map and shared templates';

  // A flag to control the visibility of the settings bottom sheet.
  var _settingsVisible = false;

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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                // A button to open the template picker.
                // Only visible if editing with a template is not already in progress.
                Visibility(
                  visible: _selectedTemplate == null,
                  child: ElevatedButton(
                    onPressed: _ready
                        ? () => setState(() => _settingsVisible = true)
                        : null,
                    child: const Text('Select Template'),
                  ),
                ),
                // Buttons for editing.
                // Only visible if there is a selected template to use in editing.
                Visibility(
                  visible: _selectedTemplate != null,
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // A button to save edits to the local geodatabase.
                      ElevatedButton(
                        onPressed: _saveEdits,
                        child: const Text('Save'),
                      ),
                      // A button to cancel and discard edits.
                      ElevatedButton(
                        onPressed: _discardEdits,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display the current status in a banner.
            MapBanner(text: _statusText),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // A bottom sheet containing the template picker.
      // Visibility is toggled by the settings button.
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

    // Get the first shared template source from the map.
    final sharedTemplateSource = map.operationalLayers
        .whereType<FeatureLayer>()
        .map((layer) => layer.featureTable)
        .whereType<ServiceFeatureTable>()
        .map((table) => table.serviceGeodatabase)
        .whereType<SharedTemplateSource>()
        .firstOrNull;

    if (sharedTemplateSource != null) {
      // Get the shared templates from the shared template source.
      final sharedTemplates = await sharedTemplateSource.querySharedTemplates(
        null,
      );
      // Create items to use in the UI based on the available templates.
      await createTemplateItems(sharedTemplates);

      // Set the geometry editor to the map view ready for editing.
      _mapViewController.geometryEditor = _geometryEditor;

      // Set the map to the map view controller.
      _mapViewController.arcGISMap = map;

      // Set the ready state variable to true to enable the UI and update the status text.
      setState(() {
        _ready = true;
        _statusText = 'Open the template picker and select a template to create features.';
      });
    } else {
      setState(
        () => _statusText = 'Unable to load sample. The map does not contain a shared template source.',
      );
    }
  }

  // A helper method to build out the bottom sheet settings for selecting a template.
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
                // Loop through the template items and create a button that starts editing using the template.
                for (final templateItem in _templateItems) ...[
                  ElevatedButton(
                    onPressed: () => _startEditingUsingTemplate(templateItem),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        spacing: 20,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // If a swatch is available for the template display it.
                          // Otherwise use a default image/icon.
                          if (templateItem.swatch != null)
                            Image.memory(
                              templateItem.swatch!.getEncodedBuffer(),
                            )
                          else
                            const Icon(Icons.add),
                          Column(
                            spacing: 10,
                            children: [
                              // Display the name and type of the template.
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

  // Query the shared templates to get the first preset and first group template.
  // Create items for these templates to use in the template picker.
  Future<void> createTemplateItems(
    Map<int, List<SharedTemplate>> sharedTemplates,
  ) async {
    // Sort the shared templates.
    final includedTypes = <SharedTemplateType>{};
    final sortedEntries = sharedTemplates.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    // Loop through the sorted templates and get the first preset and first group templates.
    // This sample is only using 2 templates as an example.
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
          // Create a template item with the swatch to display in the UI.
          // Add to the list of template items.
          _templateItems.add(
            _TemplateItem(template: template, layerId: layerId, swatch: swatch),
          );
        } on ArcGISException catch (_) {
          // Create a template without a swatch if there isn't one.
          // Add to the list of template items.
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
      _statusText = 'Draw a geometry, then tap Save or Cancel.';
      _selectedTemplate = templateItem;
      _settingsVisible = false;
    });

    // Use the vertex tool.
    _geometryEditor.tool = VertexTool();

    // Get the default construction tool from the template to define the geometry.
    final geometryConstructionTool = templateItem.template
        .getDefaultConstructionTool(layerId: templateItem.layerId)!;

    // Start editing with an appropriate geometry type based on the construction tool.
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
      _selectedTemplate = null;
      _statusText = 'Edit canceled. Open Shared Templates and select a template to create features.';
    });
  }

  // Save the edits locally.
  Future<void> _saveEdits() async {
    setState(() => _statusText = 'Creating feature...');

    // Stop the geometry editor and hold onto the returned geometry so it can be saved.
    final geometry = _geometryEditor.stop();

    try {
      // Create features locally using the template attributes and geometry created with the geometry editor.
      final sharedTemplateSource = _selectedTemplate!.template.templateSource;
      final featureCreationSet = await sharedTemplateSource.createFeatures(
        sharedTemplate: _selectedTemplate!.template,
        geometry: geometry,
      );

      // Save the created features to the local geodatabase.
      // Note that this does not apply the changes to the service. Call applyEdits to apply to the server, if required.
      await sharedTemplateSource.addFeatures(
        featureCreationSet: featureCreationSet,
      );
      // Reset the UI if the edit succeeds.
      setState(() {
        _selectedTemplate = null;
        _statusText = 'Features saved. Open Shared Templates and select a template to create features.';
      });
    } on ArcGISException catch (e) {
      // If the edits fail to meet the requirements of the template, update the UI.
      setState(() {
        _selectedTemplate = null;
        _statusText =
            'Unable to create feature. Error details: ${e.additionalMessage}. \n Open Shared Templates and select a template to create features.';
      });
    }
  }
}

// A helper class to define a template item used in the UI.
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
