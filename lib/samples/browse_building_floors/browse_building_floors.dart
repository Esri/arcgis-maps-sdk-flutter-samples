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
import 'package:material_ui/material_ui.dart';

class BrowseBuildingFloors extends StatefulWidget {
  const BrowseBuildingFloors({super.key});

  // Create the state that manages the map and selected floor.
  @override
  State<BrowseBuildingFloors> createState() => _BrowseBuildingFloorsState();
}

class _BrowseBuildingFloorsState extends State<BrowseBuildingFloors>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Store the levels exposed by the floor-aware web map.
  List<FloorLevel> _floorLevels = [];

  // Track the floor currently displayed on the map.
  FloorLevel? _selectedFloor;

  // Enable the floor selector after the map and floor manager finish loading.
  var _ready = false;

  // Build the map, floor selector, and loading indicator.
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
                  // Display the floor-aware web map in the map view.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  // Let users choose which building floor is visible.
                  child: DropdownButton<FloorLevel>(
                    value: _selectedFloor,
                    hint: const Text('Select a floor'),
                    items: _floorLevels
                        .map(
                          (floor) => DropdownMenuItem(
                            value: floor,
                            child: Text(floor.longName),
                          ),
                        )
                        .toList(),
                    onChanged: _ready
                        ? (floor) {
                            if (floor != null) _selectFloor(floor);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            // Prevent interaction while the map and floor levels are loading.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  // Load the web map and initialize its ground floor.
  Future<void> onMapViewReady() async {
    try {
      // Create a map from the public Building L web map.
      final portalItem = PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'f133a698536f44c8884ad81f80b6cfc7',
      );
      final map = ArcGISMap.withItem(portalItem);
      _mapViewController.arcGISMap = map;

      // Load the map before accessing its floor manager.
      await map.load();
      final floorManager = map.floorManager;
      if (floorManager == null) {
        throw Exception('The web map is not floor-aware.');
      }

      // Load the floor manager before reading its floor levels.
      await floorManager.load();
      final levels = floorManager.levels;
      if (levels.isEmpty) {
        throw Exception('The web map does not contain any floor levels.');
      }
      if (!mounted) return;

      // Select the ground floor, or the first available floor if none has order zero.
      _floorLevels = levels;
      final initialFloor = levels.firstWhere(
        (floor) => floor.verticalOrder == 0,
        orElse: () => levels.first,
      );
      _selectFloor(initialFloor);
      setState(() => _ready = true);
    } on Exception catch (exception) {
      // Show loading errors and leave the map visible when possible.
      if (!mounted) return;
      setState(() => _ready = true);
      showExceptionDialog('Failed to load the floor-aware web map', exception);
    }
  }

  // Display only the selected floor level.
  void _selectFloor(FloorLevel selectedFloor) {
    try {
      // Hide every level before showing the requested floor.
      for (final floor in _floorLevels) {
        floor.isVisible = identical(floor, selectedFloor);
      }

      // Update the dropdown to match the visible floor.
      setState(() => _selectedFloor = selectedFloor);
    } on Exception catch (exception) {
      // Report errors that occur while changing floor visibility.
      showExceptionDialog('Failed to display the selected floor', exception);
    }
  }
}
