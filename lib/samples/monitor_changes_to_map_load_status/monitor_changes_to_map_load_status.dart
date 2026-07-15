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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class MonitorChangesToMapLoadStatus extends StatefulWidget {
  const MonitorChangesToMapLoadStatus({super.key});

  @override
  State<MonitorChangesToMapLoadStatus> createState() =>
      _MonitorChangesToMapLoadStatusState();
}

class _MonitorChangesToMapLoadStatusState
    extends State<MonitorChangesToMapLoadStatus>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A string indicating the load status of the map.
  String mapLoadStatus = 'Unknown';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Add a map view to the widget tree and set a controller.
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
            ),
            // Display the status of the current map.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.black.withValues(alpha: 0.7),
              child: Text(
                'Load Status: $mapLoadStatus',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.customWhiteStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with an imagery basemap style and set a controller.
    final map = ArcGISMap.withBasemapStyle(.arcGISImagery);
    _mapViewController.arcGISMap = map;

    // Updates the map load status string based on the current LoadStatus and refreshes the UI.
    updateMapStatus(LoadStatus.notLoaded);
    try {
      updateMapStatus(LoadStatus.loading);
      await map.load();
      updateMapStatus(LoadStatus.loaded);
    } on Exception catch (_) {
      updateMapStatus(LoadStatus.failedToLoad);
    }
  }

  // Updates the displayed map load status based on the current load state.
  void updateMapStatus(LoadStatus status) {
    setState(() {
      switch (status) {
        case LoadStatus.notLoaded:
          mapLoadStatus = 'Not Loaded';

        case LoadStatus.loading:
          mapLoadStatus = 'Loading';

        case LoadStatus.loaded:
          mapLoadStatus = 'Loaded';

        default:
          mapLoadStatus = 'Failed';
      }
    });
  }
}
