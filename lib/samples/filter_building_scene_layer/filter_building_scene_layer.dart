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
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
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

  // BuildingSceneLayer that will be filtered. Set after the WebScene is loaded.
  late final BuildingSceneLayer _buildingSceneLayer;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  var _floorList = <String>[];
  var _selectedFloor = 'All';
  var _settingsVisible = false;
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
                    child: const Text('Scene Settings'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        buildFloorLevelSelector(context),
        const Divider(),
        const Text('Categories:'),
        buildSublayerSelector(context),
      ],
    );
  }

  Widget buildFloorLevelSelector(BuildContext context) {
    final options = ['All'];
    options.addAll(_floorList);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Text('Floor:'),
        DropdownButton<String>(
          value: _selectedFloor,
          items: options
              .map<DropdownMenuItem<String>>(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedFloor = value ?? 'All');
            updateFloorFilters();
          },
        ),
      ],
    );
  }

  Widget buildSublayerSelector(BuildContext context) {
    final fullModelSublayer =
        _buildingSceneLayer.sublayers.firstWhere(
              (sublayer) => sublayer.name == 'Full Model',
            )
            as BuildingGroupSublayer;

    final categorySublayers = fullModelSublayer.sublayers;

    return SizedBox(
      height: 200,
      child: ListView(
        children: categorySublayers.map((categorySublayer) {
          final items = (categorySublayer as BuildingGroupSublayer).sublayers;
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
            children: items.map((item) {
              return CheckboxListTile(
                title: Text(item.name),
                value: item.isVisible,
                onChanged: (val) {
                  setState(() {
                    item.isVisible = val ?? false;
                  });
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> onLocalSceneViewReady() async {
    // Create the local scene from a ArcGISOnline web scene.
    final sceneUri = Uri.parse(
      'https://arcgisruntime.maps.arcgis.com/home/item.html?id=b7c387d599a84a50aafaece5ca139d44',
    );
    final scene = ArcGISScene.withUri(sceneUri)!;
    await scene.load();

    // Get the BuildingSceneLayer from the webmap.
    _buildingSceneLayer =
        scene.operationalLayers.firstWhere(
              (layer) => layer is BuildingSceneLayer,
            )
            as BuildingSceneLayer;

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

    final identifyResult = await _localSceneViewController.identifyLayer(
      _buildingSceneLayer,
      screenPoint: offset,
      tolerance: 5,
    );

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

  void updateFloorFilters() {
    if (_selectedFloor == 'All') {
      _buildingSceneLayer.activeFilter = null;
      return;
    }

    final buildingFilter = BuildingFilter(
      name: 'Floor filter',
      description: 'Show selected floor and x-ray filter for lower floors.',
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

// Widget to display the details of a single Feature.
class FeaturePopupView extends StatelessWidget {
  const FeaturePopupView({required this.feature, this.onClose, super.key});

  // The feature to display.
  final Feature feature;

  // Optional function to call when the popup is closed.
  final void Function()? onClose;

  @override
  Widget build(BuildContext context) {
    // Create a PopupDefinition with a title based on the feature name.
    final popupDefinition = PopupDefinition.withGeoElement(feature);
    popupDefinition.title = feature.attributes['name'] as String? ?? '';

    return PopupView(
      popup: Popup(geoElement: feature, popupDefinition: popupDefinition),
      onClose: onClose,
    );
  }
}
