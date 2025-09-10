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

class ConfigureClusters extends StatefulWidget {
  const ConfigureClusters({super.key});

  @override
  State<ConfigureClusters> createState() => _ConfigureClustersState();
}

class _ConfigureClustersState extends State<ConfigureClusters>
    with SampleStateSupport {
  // MapView controller.
  final _mapViewController = ArcGISMapView.createController();

  late ArcGISMap _map;

  // Feature layer and clustering FR.
  late FeatureLayer _layer;
  ClusteringFeatureReduction? _featureReduction;

  // Simple UI state.
  var _ready = false;
  var _showLabels = true;

  // Controls .
  final _clusterRadiusOptions = const [30, 45, 60, 75, 90];
  final _clusterMaxScaleOptions = const [
    0,
    1000,
    5000,
    10000,
    50000,
    100000,
    500000,
  ];

  // Current selections.
  var _selectedRadius = 60; // default cluster radius.
  var _selectedMaxScale = 0; // default max scale (0 = unlimited).

  // Pre-built dropdown entries .
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
            // MapView.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: _onMapViewReady,
              ),
            ),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _ready ? _applyClustering : null,
                  child: const Text('Apply Clustering'),
                ),
                ElevatedButton(
                  onPressed: (_ready && _featureReduction != null)
                      ? _clearClustering
                      : null,
                  child: const Text('Clear'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Show labels'),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showLabels,
                      onChanged: !_ready
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
                            DropdownMenu<int>(
                              dropdownMenuEntries: _radiusEntries,
                              initialSelection: _selectedRadius,
                              onSelected: !_ready
                                  ? null
                                  : (v) {
                                      if (v == null) return;
                                      setState(() => _selectedRadius = v);
                                      _featureReduction?.radius = v.toDouble();
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
                          DropdownMenu<int>(
                            dropdownMenuEntries: _maxScaleEntries,
                            initialSelection: _selectedMaxScale,
                            onSelected: !_ready
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
    // Zurich buildings web map from PortalItem.
    _map = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'aa44e79a4836413c89908e1afdace2ea',
      ),
    );

    // Attach map and load.
    _mapViewController.arcGISMap = _map;
    await _map.load();

    // Grab the Zurich buildings layer (first operational layer).
    _layer = _map.operationalLayers.first as FeatureLayer;

    // Set initial viewpoint to Zurich.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 47.38,
        longitude: 8.53,
        scale: 80000,
      ),
    );

    // Ready for interaction.
    setState(() => _ready = true);
  }

  Future<void> _applyClustering() async {
    setState(() => _ready = false);

    // Class breaks renderer for "Average Building Height" 0..8.
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

    // Default symbol for anything outside the 0–8 ranges.
    classBreaksRenderer.defaultSymbol = SimpleMarkerSymbol(color: Colors.pink);

    // ClusteringFeatureReduction with aggregates & labels.
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

    // Label the cluster with its count, placed at center.
    final simpleLabelExpression = SimpleLabelExpression(
      simpleExpression: '[cluster_count]',
    );
    final textSymbol = TextSymbol(size: 12);
    final labelDefinition = LabelDefinition(
      labelExpression: simpleLabelExpression,
      textSymbol: textSymbol,
    )..placement = LabelingPlacement.pointCenterCenter;

    fr.labelDefinitions.add(labelDefinition);

    // Popup for clusters.
    fr.popupDefinition = PopupDefinition.withPopupSource(fr);

    // Apply to layer.
    _layer.featureReduction = fr;
    _featureReduction = fr;

    setState(() => _ready = true);
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

  void _clearClustering() {
    _layer.featureReduction = null;
    _featureReduction = null;
    // Keep UI selections; user can re-apply any time.
    setState(() {});
  }
}
