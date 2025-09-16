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

class ConfigureClusters extends StatefulWidget {
  const ConfigureClusters({super.key});

  @override
  State<ConfigureClusters> createState() => _ConfigureClustersState();
}

class _ConfigureClustersState extends State<ConfigureClusters>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  late ArcGISMap _map;

  // Create a feature layer and clustering feature reduction.
  late FeatureLayer _layer;
  ClusteringFeatureReduction? _featureReduction;

  // Create flags to manage the sample UI state.
  var _ready = false;
  var _showLabels = true;

  // Create options for configuring the radius and max display scale for clusters.
  final _clusterRadiusOptions = const [30, 45, 60, 75, 90];
  var _selectedRadius = 60; // default cluster radius.

  final _clusterMaxScaleOptions = const [
    0,
    1000,
    5000,
    10000,
    50000,
    100000,
    500000,
  ];
  var _selectedMaxScale = 0; // default max scale (0 = unlimited).

  // Define the options available for selecting a cluster radius and max display scale.
  late final _radiusEntries = _clusterRadiusOptions
      .map((v) => DropdownMenuEntry(value: v, label: '$v'))
      .toList();

  late final _maxScaleEntries = _clusterMaxScaleOptions
      .map((v) => DropdownMenuEntry(value: v, label: '$v'))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            Expanded(
              // Add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: _onMapViewReady,
                onTap: _onMapTap,
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _featureReduction == null
                      ? _applyClustering
                      : null,
                  child: const Text('Apply Clustering'),
                ),
                ElevatedButton(
                  onPressed: _featureReduction != null
                      ? _clearClustering
                      : null,
                  child: const Text('Clear'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Show labels'),
                    const SizedBox(width: 8),
                    // Add a switch to toggle the display of labels.
                    Switch(
                      value: _showLabels,
                      onChanged: _featureReduction == null
                          ? null
                          : (v) {
                              setState(() => _showLabels = v);
                              _featureReduction?.showLabels = v;
                            },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Radius'),
                            const SizedBox(width: 8),
                            // Configure a dropdown menu for selecting the radius of the clusters.
                            DropdownMenu<int>(
                              dropdownMenuEntries: _radiusEntries,
                              initialSelection: _selectedRadius,
                              onSelected: _featureReduction == null
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      setState(() => _selectedRadius = v);
                                      _featureReduction?.radius = v.toDouble();

                                      if (_featureReduction != null) {
                                        // Nudge Refresh. If statle visuals.
                                        _layer.featureReduction =
                                            _featureReduction;
                                      }
                                    },
                              width: _calculateMenuWidth(context, '000000'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Max scale'),
                          const SizedBox(width: 8),
                          // Configure a dropdown menu for selecting the maximum display scale of the clusters.
                          DropdownMenu<int>(
                            dropdownMenuEntries: _maxScaleEntries,
                            initialSelection: _selectedMaxScale,
                            onSelected: _featureReduction == null
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setState(() => _selectedMaxScale = v);
                                    _featureReduction?.maxScale = v.toDouble();
                                  },
                            width: _calculateMenuWidth(context, '0000000'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    // Create a map using the portal item of a Zurich buildings web map.
    _map = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'aa44e79a4836413c89908e1afdace2ea',
      ),
    );

    // Add the map to the map view controller.
    _mapViewController.arcGISMap = _map;
    // Explicitly load the web map so that we can access the operational layers.
    await _map.load();

    // Get the first layer from the operational layers.
    _layer = _map.operationalLayers.first as FeatureLayer;

    // Set initial viewpoint to Zurich.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 47.38,
        longitude: 8.53,
        scale: 80000,
      ),
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> _applyClustering() async {
    // If feature reduction already applied.
    if (_featureReduction != null) return;
    setState(() => _ready = false);

    // Create a class breaks renderer for "Average Building Height".
    final classBreaksRenderer = ClassBreaksRenderer()
      ..fieldName = 'Average Building Height';

    final colors = <Color>[
      const Color.fromARGB(255, 4, 251, 255),
      const Color.fromARGB(255, 44, 211, 255),
      const Color.fromARGB(255, 74, 181, 255),
      const Color.fromARGB(255, 120, 135, 255),
      const Color.fromARGB(255, 165, 90, 255),
      const Color.fromARGB(255, 194, 61, 255),
      const Color.fromARGB(255, 224, 31, 255),
      const Color.fromARGB(255, 254, 1, 255),
    ];

    for (var i = 0; i <= 7; i++) {
      classBreaksRenderer.classBreaks.add(
        ClassBreak(
          description: '$i',
          label: '$i',
          minValue: i.toDouble(),
          maxValue: (i + 1).toDouble(),
          symbol: SimpleMarkerSymbol(color: colors[i]),
        ),
      );
    }

    // Define a default symbol for anything outside the 0–8 ranges.
    classBreaksRenderer.defaultSymbol = SimpleMarkerSymbol(color: Colors.pink);

    // Create a clustering feature reduction with aggregates and labels.
    final fr = ClusteringFeatureReduction(classBreaksRenderer)
      ..enabled = true
      ..aggregateFields.add(
        AggregateField.withFieldName(
          name: 'Total Residential Buildings',
          statisticFieldName: 'Residential_Buildings',
          statisticType: AggregateStatisticType.sum,
        ),
      )
      ..aggregateFields.add(
        AggregateField.withFieldName(
          name: 'Average Building Height',
          statisticFieldName: 'Most_common_number_of_storeys',
          statisticType: AggregateStatisticType.mode,
        ),
      )
      ..minSymbolSize = 5
      ..maxSymbolSize = 90
      ..radius = _selectedRadius.toDouble()
      ..maxScale = _selectedMaxScale.toDouble()
      ..showLabels = _showLabels;

    // Define a label expression using the cluster count.
    final simpleLabelExpression = SimpleLabelExpression(
      simpleExpression: '[cluster_count]',
    );
    // Define a label definition using the label expression and a text symbol. Position the placement of the label at the center of the feature geometry.
    final textSymbol = TextSymbol(size: 12);
    final labelDefinition = LabelDefinition(
      labelExpression: simpleLabelExpression,
      textSymbol: textSymbol,
    )..placement = LabelingPlacement.pointCenterCenter;

    // Add the label definition to the feature reduction.
    fr.labelDefinitions.add(labelDefinition);

    // Popup for clusters.
    fr.popupDefinition = PopupDefinition.withPopupSource(fr);

    // Apply the feature reduction to the feature layer.
    _layer.featureReduction = fr;
    _featureReduction = fr;

    setState(() => _ready = true);
  }

  Future<void> _onMapTap(Offset offset) async {
    final result = await _mapViewController.identifyLayer(
      _layer,
      screenPoint: offset,
      tolerance: 22,
    );
    if (result.popups.isNotEmpty) {
      _showPopup(result.popups.first);
      return;
    }

    // Fallback: build a Popup from the top GeoElement using an available definition.
    final fallback = await _mapViewController.identifyLayer(
      _layer,
      screenPoint: offset,
      tolerance: 22,
    );
    if (fallback.geoElements.isNotEmpty) {
      final ge = fallback.geoElements.first;
      final pd = _featureReduction?.popupDefinition ?? _layer.popupDefinition;
      if (pd != null) {
        _showPopup(Popup(geoElement: ge, popupDefinition: pd));
      }
    }
  }

  void _showPopup(Popup popup) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: PopupView(
          popup: popup,
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  void _clearClustering() {
    _layer.featureReduction = null;
    _featureReduction = null;
    // Keep UI selections; user can re-apply any time.
    setState(() {});
  }

  double _calculateMenuWidth(BuildContext context, String sampleText) {
    final tp = TextPainter(
      text: TextSpan(
        text: sampleText,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.size.width * 2;
  }
}
