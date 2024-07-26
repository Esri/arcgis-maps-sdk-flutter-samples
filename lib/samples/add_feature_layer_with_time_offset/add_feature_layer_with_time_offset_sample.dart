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

import 'dart:math';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class AddFeatureLayerWithTimeOffsetSample extends StatefulWidget {
  const AddFeatureLayerWithTimeOffsetSample({super.key});

  @override
  State<AddFeatureLayerWithTimeOffsetSample> createState() =>
      _AddFeatureLayerWithTimeOffsetSampleState();
}

class _AddFeatureLayerWithTimeOffsetSampleState
    extends State<AddFeatureLayerWithTimeOffsetSample> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  //fixme comment
  late final TimeExtent _originalTimeExtent;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;
  //fixme comment
  var _intervalFraction = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: () => setState(() => _settingsVisible = true),
                      child: const Text('Settings'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? buildSettings(context) : null,
    );
  }

  // The build method for the Settings bottom sheet.
  Widget buildSettings(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Interval'),
              const Spacer(),
              Text(
                _intervalFraction.toString(), //fixme
                textAlign: TextAlign.right,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                // A slider to adjust the interval.
                child: Slider(
                  value: _intervalFraction,
                  onChanged: (value) =>
                      setState(() => _intervalFraction = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 20.0,
                height: 20.0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              const Text('Hurricanes offset 10 days'),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              SizedBox(
                width: 20.0,
                height: 20.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              const Text('Hurricanes no offset'),
            ],
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with the oceans basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);

    //fixme comments
    final featureLayerUri = Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Hurricanes/MapServer/0');

    final featureTable = ServiceFeatureTable.withUri(featureLayerUri);
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    featureLayer.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.blue.shade900,
        size: 10.0,
      ),
    );

    final offsetFeatureTable = ServiceFeatureTable.withUri(featureLayerUri);
    final offsetFeatureLayer =
        FeatureLayer.withFeatureTable(offsetFeatureTable);
    offsetFeatureLayer.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.red,
        size: 10.0,
      ),
    );
    offsetFeatureLayer.timeOffset =
        TimeValue(duration: 10, unit: TimeUnit.days);

    map.operationalLayers.addAll([featureLayer, offsetFeatureLayer]);

    await featureLayer.load();
    _originalTimeExtent = featureLayer.fullTimeExtent!;

//fixme updateTimeExtent
    _mapViewController.timeExtent = TimeExtent(
      startTime:
          _originalTimeExtent.endTime?.subtract(const Duration(days: 10)),
      endTime: _originalTimeExtent.endTime,
    );

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void performTask() async {
    setState(() => _ready = false);
    // Perform some task.
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
