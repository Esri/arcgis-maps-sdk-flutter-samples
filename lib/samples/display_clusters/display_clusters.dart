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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class DisplayClusters extends StatefulWidget {
  const DisplayClusters({super.key});

  @override
  State<DisplayClusters> createState() => _DisplayClustersState();
}

class _DisplayClustersState extends State<DisplayClusters>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  late ArcGISMap _map;
  late FeatureLayer _featureLayer;
  // A flag to track whether feature clustering is enabled to display in the UI.
  var _featureReductionEnabled = false;
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
                    onTap: onTap,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    // Add a button to toggle feature clustering.
                    ElevatedButton(
                      onPressed: toggleFeatureClustering,
                      child: const Text('Toggle feature clustering'),
                    ),
                    // Display the current feature reduction state.
                    Text(
                      _featureReductionEnabled
                          ? 'Feature Reduction: On'
                          : 'Feature Reduction: Off',
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Get the power plants web map from the default portal.
    final portal = Portal.arcGISOnline();
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: '8916d50c44c746c1aafae001552bad23',
    );
    // Load the portal item.
    await portalItem.load();
    // Create a map from the portal item.
    _map = ArcGISMap.withItem(portalItem);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = _map;
    // Load the map.
    await _map.load();
    // Get the power plant feature layer once the map has finished loading.
    if (_map.operationalLayers.isNotEmpty &&
        _map.operationalLayers.first is FeatureLayer) {
      // Get the first layer from the web map a feature layer.
      _featureLayer = _map.operationalLayers.first as FeatureLayer;
      if (_featureLayer.featureReduction != null) {
        // Set the ready state variable to true to enable the sample UI.
        // Set the feature reduction flag to the current state of the feature
        setState(() {
          _ready = true;
          _featureReductionEnabled = _featureLayer.featureReduction!.enabled;
        });
      } else {
        showMessageDialog(
          'Feature layer does not have feature reduction enabled.',
          title: 'Warning',
        );
      }
    } else {
      showMessageDialog(
        'Unable to access a feature layer on the web map.',
        title: 'Warning',
      );
    }
  }

  Future<void> onTap(Offset localPosition) async {
    // Clear any existing selected features.
    _featureLayer.clearSelection();
    // Perform an identify result on the map view controller, using the feature layer and tapped location.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _featureLayer,
      screenPoint: localPosition,
      tolerance: 12,
    );

    // Ensure that there are popups if there are no popups then
    if (identifyLayerResult.popups.isEmpty) return;

    final popup = identifyLayerResult.popups.first;
    // Get the aggregate geoelements from the identify result.
    final aggregateGeoElements = identifyLayerResult.geoElements
        .whereType<AggregateGeoElement>();
    if (aggregateGeoElements.isEmpty) return;
    // Select the first aggregate geoelement.
    final aggregateGeoElement = aggregateGeoElements.first;
    aggregateGeoElement.isSelected = true;

    // Get the list of geoelements associated with the aggregate geoelement.
    final geoElements = await aggregateGeoElement.getGeoElements();
    // Display a dialog with information about the geoelements.
    showOutputs(popup, geoElements);
  }

  // Display the results in a Popup view in a modal bottom sheet.
  void showOutputs(Popup popup, List<GeoElement> geoElements) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DefaultTabController(
        length: 2,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            children: [
              // Create a tab bar with headings for the different data types.
              Material(
                color: Colors.transparent,
                child: TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color,
                  tabs: const [
                    Tab(text: 'Popup'),
                    Tab(text: 'Geoelements'),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Configure the tab content.
              Expanded(
                child: TabBarView(
                  children: [
                    // Display a PoopupView in the popup tab.
                    PopupView(
                      popup: popup,
                      onClose: () => Navigator.of(context).maybePop(),
                    ),

                    // Display data about the identified geoelements in the geoelements tab.
                    GeoElementsTab(geoElements: geoElements),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void toggleFeatureClustering() {
    if (_featureLayer.featureReduction != null) {
      // Toggle the feature reduction.
      final featureReduction = _featureLayer.featureReduction!;
      featureReduction.enabled = !featureReduction.enabled;
      setState(() => _featureReductionEnabled = featureReduction.enabled);
    }
  }
}

/// A simple tab that lists the GeoElements contained in the selected
/// aggregate cluster. It shows a header with the total count, an empty
/// state when there are none, and a scrollable list when present.
class GeoElementsTab extends StatelessWidget {
  const GeoElementsTab({required this.geoElements, super.key});

  /// The individual GeoElements that belong to the tapped cluster.
  final List<GeoElement> geoElements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: display the total number of GeoElements in this cluster.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Total GeoElements: ${geoElements.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // If there are no GeoElements, show a friendly empty-state message.
        if (geoElements.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'No GeoElements found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          // When elements exist, fill the remaining space with a scrollable list.
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: geoElements.length,
              // Thin divider between rows.
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final element = geoElements[index];

                // Best-effort display name:
                // Try to read the 'name' attribute (if present and non-empty),
                // otherwise fall back to a generic label with the index.
                final name = () {
                  try {
                    final raw = element.attributes['name'];
                    if (raw is String && raw.trim().isNotEmpty) return raw;
                  } catch (_) {}
                  return 'GeoElement #$index';
                }();

                // Each row shows a place icon and the resolved name.
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(name),
                );
              },
            ),
          ),
      ],
    );
  }
}
