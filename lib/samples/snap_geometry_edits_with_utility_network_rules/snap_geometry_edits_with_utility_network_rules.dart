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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SnapGeometryEditsWithUtilityNetworkRules extends StatefulWidget {
  const SnapGeometryEditsWithUtilityNetworkRules({super.key});

  @override
  State<SnapGeometryEditsWithUtilityNetworkRules> createState() =>
      _SnapGeometryEditsWithUtilityNetworkRulesState();
}

class _SnapGeometryEditsWithUtilityNetworkRulesState
    extends State<SnapGeometryEditsWithUtilityNetworkRules>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: performTask,
                      child: const Text('Perform Task'),
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

  //fixme comments
  Future<void> onMapViewReady() async {
    const downloadFileName = 'NapervilleGasUtilities';
    final appDir = await getApplicationDocumentsDirectory();
    final zipFile = File('${appDir.absolute.path}/$downloadFileName.zip');
    if (!zipFile.existsSync()) {
      await downloadSampleDataWithProgress(
        itemIds: ['0fd3a39660d54c12b05d5f81f207dffd'],
        destinationFiles: [zipFile],
      );
    }
    final geodatabaseFile = File(
      '${appDir.absolute.path}/$downloadFileName/$downloadFileName.geodatabase',
    );

    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -9811055.1560284,
        y: 5131792.195025,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 10000,
    );
    map.loadSettings.featureTilingMode =
        FeatureTilingMode.enabledWithFullResolutionWhenSupported;
    _mapViewController.arcGISMap = map;

    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await geodatabase.load();
    final pipelineLayer = SubtypeFeatureLayer.withFeatureTable(
      geodatabase.getGeodatabaseFeatureTable(tableName: 'PipelineLine')!
          as ArcGISFeatureTable,
    );
    map.operationalLayers.add(pipelineLayer);

    //fixme

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    // Do something with a tap.
    // ignore: avoid_print
    print('Tapped at $offset');
  }

  Future<void> performTask() async {
    setState(() => _ready = false);

    // Perform some task.
    // ignore: avoid_print
    print('Perform task');
    await Future<void>.delayed(const Duration(seconds: 5));

    setState(() => _ready = true);
  }
}
