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

class AddFeatureLayerWithTimeOffset extends StatefulWidget {
  const AddFeatureLayerWithTimeOffset({super.key});

  @override
  State<AddFeatureLayerWithTimeOffset> createState() =>
      _AddFeatureLayerWithTimeOffsetState();
}

class _AddFeatureLayerWithTimeOffsetState
    extends State<AddFeatureLayerWithTimeOffset> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The start and end times of the feature layer.
  late DateTime _startTime;
  late DateTime _endTime;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the settings bottom sheet is visible.
  var _settingsVisible = false;
  // The current time interval, expressed as a fraction of the full time extent.
  var _intervalFraction = 0.5;
  // A message to display the current date range.
  var _dateRangeMessage = '';

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
          // Display the current date range.
          Text(_dateRangeMessage),
          Row(
            children: [
              Expanded(
                // A slider to adjust the interval.
                child: Slider(
                  value: _intervalFraction,
                  onChanged: (value) {
                    setState(() => _intervalFraction = value);
                    updateTimeExtent();
                  },
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
              const Text('Hurricane tracks, offset 10 days'),
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
              const Text('Hurricane tracks, no offset'),
            ],
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with the oceans basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -6000000,
        y: 2500000,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 1e8,
    );

    // The URL of the feature layer showing hurricanes.
    final featureLayerUri = Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Hurricanes/MapServer/0');

    // Create a feature layer for the hurricane tracks, represented by blue dots.
    final featureTable = ServiceFeatureTable.withUri(featureLayerUri);
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    featureLayer.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.blue.shade900,
        size: 10.0,
      ),
    );

    // Create another feature layer, offset by 10 days, represented by red dots.
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

    // Add the feature layers to the map.
    map.operationalLayers.addAll([featureLayer, offsetFeatureLayer]);

    // Load the feature layer and record the start and end times.
    await featureLayer.load();
    _startTime = featureLayer.fullTimeExtent?.startTime ?? DateTime.now();
    _endTime = featureLayer.fullTimeExtent?.endTime ?? DateTime.now();
    updateTimeExtent();

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Calculate the new time extent based on the interval fraction.
  void updateTimeExtent() {
    // Calculate how many days to offset from the original start time.
    final totalDays = _endTime.difference(_startTime).inDays;
    final desiredDays = (totalDays * _intervalFraction).round();

    // Calculate the new start and end times (10 days apart).
    final newStart = _startTime.add(Duration(days: desiredDays));
    var newEnd = newStart.add(const Duration(days: 10));
    if (newEnd.isAfter(_endTime)) newEnd = _endTime;

    // Set the new time extent on the map view controller.
    _mapViewController.timeExtent =
        TimeExtent(startTime: newStart, endTime: newEnd);

    // Update the date range message.
    _dateRangeMessage = '${newStart.month}/${newStart.day}/${newStart.year} - '
        '${newEnd.month}/${newEnd.day}/${newEnd.year}';
  }
}
