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

class FilterBuildingSceneLayer extends StatefulWidget {
  const FilterBuildingSceneLayer({super.key});

  @override
  State<FilterBuildingSceneLayer> createState() =>
      _FilterBuildingSceneLayerState();
}

class _FilterBuildingSceneLayerState extends State<FilterBuildingSceneLayer>
    with SampleStateSupport {
  // Create a controller for the local scene view.
  final _localSceneViewController = ArcGISLocalSceneView.createController();

  // Building scene layer that will be filtered. Set after the WebScene is loaded.
  late final BuildingSceneLayer _buildingSceneLayer;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A listing of all floors in the building scene layer
  var _floorList = <String>[];

  // The currently selected floor.
  var _selectedFloor = 'All';

  // Flag to show or hide the settings pane.
  var _settingsVisible = false;

  // Building scene layer sublayer that contains the currently selected feature.
  BuildingComponentSublayer? _selectedSublayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a local scene view to the widget tree and set a controller.
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ArcGISLocalSceneView(
                    controllerProvider: () => _localSceneViewController,
                    onLocalSceneViewReady: onLocalSceneViewReady,
                    onTap: onTap,
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _settingsVisible = true),
                    child: const Text('Building Filter Settings'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _settingsVisible
          ? FilterSettingsSheet(
              floorList: _floorList,
              selectedFloor: _selectedFloor,
              onFloorChanged: (floor) {
                setState(() => _selectedFloor = floor);
                updateFloorFilters();
              },
              onClose: () => setState(() => _settingsVisible = false),
              buildingSceneLayer: _buildingSceneLayer,
            )
          : null,
    );
  }

  Future<void> onLocalSceneViewReady() async {
    // Create the local scene from a ArcGISOnline web scene.
    final sceneUri = Uri.parse(
      'https://arcgisruntime.maps.arcgis.com/home/item.html?id=b7c387d599a84a50aafaece5ca139d44',
    );
    final scene = ArcGISScene.withUri(sceneUri)!;

    // Load the scene so the underlying layers can be accessed.
    await scene.load();

    // Get the BuildingSceneLayer from the webmap.
    _buildingSceneLayer =
        scene.operationalLayers.firstWhere(
              (layer) => layer is BuildingSceneLayer,
            )
            as BuildingSceneLayer;

    // Get the floor listing from the statistics.
    final statistics = await _buildingSceneLayer.fetchStatistics();
    if (statistics['BldgLevel'] != null) {
      final floorList = <String>[];
      floorList.addAll(statistics['BldgLevel']!.mostFrequentValues);
      floorList.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
      setState(() {
        _floorList = floorList;
      });
    }

    // Apply the scene to the local scene view controller.
    _localSceneViewController.arcGISScene = scene;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset offset) async {
    // Clear the current selection
    if (_selectedSublayer != null) {
      _selectedSublayer!.clearSelection();
      _selectedSublayer = null;
    }

    // Identify on the building scene layer.
    final identifyResult = await _localSceneViewController.identifyLayer(
      _buildingSceneLayer,
      screenPoint: offset,
      tolerance: 5,
    );

    // Select the first identified feature and show the feature details in a popup.
    if (identifyResult.sublayerResults.isNotEmpty) {
      final sublayerResult = identifyResult.sublayerResults.first;
      if (sublayerResult.geoElements.isNotEmpty) {
        final identifiedFeature = sublayerResult.geoElements.first as Feature;
        final sublayer =
            sublayerResult.layerContent as BuildingComponentSublayer;
        sublayer.selectFeature(identifiedFeature);
        _selectedSublayer = sublayer;

        if (mounted) {
          showFeatureDetail(context: context, feature: identifiedFeature);
        }
      }
    }
  }

  // Utility function to update the building filters based on the selected floor.
  void updateFloorFilters() {
    if (_selectedFloor == 'All') {
      // No filtering applied if 'All' floors are selected.
      _buildingSceneLayer.activeFilter = null;
      return;
    }

    // Build a building filter to show the selected floor and an xray view of the floors below.
    // Floors above the selected floor are not shown at all.
    final buildingFilter = BuildingFilter(
      name: 'Floor filter',
      description: 'Show selected floor and xray filter for lower floors.',
      blocks: [
        BuildingFilterBlock(
          title: 'solid block',
          whereClause: 'BldgLevel = $_selectedFloor',
          mode: BuildingSolidFilterMode(),
        ),
        BuildingFilterBlock(
          title: 'xray block',
          whereClause: 'BldgLevel < $_selectedFloor',
          mode: BuildingXrayFilterMode(),
        ),
      ],
    );

    // Apply the filter to the building scene layer.
    _buildingSceneLayer.activeFilter = buildingFilter;
  }

  // Display the feature details in a Popup view in a modal bottom sheet.
  void showFeatureDetail({
    required BuildContext context,
    required Feature feature,
  }) {
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: FeaturePopupView(
          feature: feature,
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

// The filter setting bottom sheet that allows the user to select the building
// floor feature sublayers.
class FilterSettingsSheet extends StatelessWidget {
  const FilterSettingsSheet({
    required this.floorList,
    required this.selectedFloor,
    required this.onFloorChanged,
    required this.onClose,
    required this.buildingSceneLayer,
    super.key,
  });

  final List<String> floorList;
  final String selectedFloor;
  final ValueChanged<String> onFloorChanged;
  final VoidCallback onClose;
  final BuildingSceneLayer buildingSceneLayer;

  @override
  Widget build(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: onClose,
      settingsWidgets: (context) => [
        _FloorLevelSelector(
          floorList: floorList,
          selectedFloor: selectedFloor,
          onChanged: onFloorChanged,
        ),
        const Divider(),
        const Text('Categories:'),
        _SublayerSelector(buildingSceneLayer: buildingSceneLayer),
      ],
    );
  }
}

// Widget to list and select building floor.
class _FloorLevelSelector extends StatelessWidget {
  const _FloorLevelSelector({
    required this.floorList,
    required this.selectedFloor,
    required this.onChanged,
  });

  final List<String> floorList;
  final String selectedFloor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['All', ...floorList];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Text('Floor:'),
        DropdownButton<String>(
          value: selectedFloor,
          items: options
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

// Widget to show and select building sublayers.
class _SublayerSelector extends StatefulWidget {
  const _SublayerSelector({required this.buildingSceneLayer});
  final BuildingSceneLayer buildingSceneLayer;

  @override
  State<_SublayerSelector> createState() => _SublayerSelectorState();
}

class _SublayerSelectorState extends State<_SublayerSelector> {
  @override
  Widget build(BuildContext context) {
    final fullModelSublayer =
        widget.buildingSceneLayer.sublayers.firstWhere(
              (sublayer) => sublayer.name == 'Full Model',
            )
            as BuildingGroupSublayer;
    final categorySublayers = fullModelSublayer.sublayers;
    return SizedBox(
      height: 200,
      child: ListView(
        children: categorySublayers.map((categorySublayer) {
          final componentSublayers =
              (categorySublayer as BuildingGroupSublayer).sublayers;
          return ExpansionTile(
            title: Row(
              children: [
                Text(categorySublayer.name),
                const Spacer(),
                Checkbox(
                  value: categorySublayer.isVisible,
                  onChanged: (val) {
                    setState(() {
                      categorySublayer.isVisible = val ?? false;
                    });
                  },
                ),
              ],
            ),
            children: componentSublayers.map((componentSublayer) {
              return CheckboxListTile(
                title: Text(componentSublayer.name),
                value: componentSublayer.isVisible,
                onChanged: (val) {
                  setState(() {
                    componentSublayer.isVisible = val ?? false;
                  });
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
