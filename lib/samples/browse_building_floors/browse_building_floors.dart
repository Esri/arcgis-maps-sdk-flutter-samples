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

  @override
  State<BrowseBuildingFloors> createState() => _BrowseBuildingFloorsState();
}

class _BrowseBuildingFloorsState extends State<BrowseBuildingFloors>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Store the levels defined in the floor-aware web map.
  var _floorLevels = <FloorLevel>[];

  // Track the floor currently displayed on the map.
  FloorLevel? _selectedFloor;

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
                  ),
                ),
                // A dropdown menu to select the visible building floor.
                DropdownButton(
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
                  onChanged: (floor) {
                    if (floor != null) _selectFloor(floor);
                  },
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
    try {
      // Create a map from the public Building L web map.
      final portalItem = PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(),
        itemId: 'f133a698536f44c8884ad81f80b6cfc7',
      );
      final map = ArcGISMap.withItem(portalItem);
      _mapViewController.arcGISMap = map;

      // Load the map before accessing the floor manager.
      await map.load();
      if (map.floorManager == null) {
        throw Exception('The map is not floor-aware.');
      }
      final floorManager = map.floorManager!;

      // Load the floor manager.
      await floorManager.load();

      if (!mounted) return;

      // Store the floor levels to populate the dropdown menu.
      setState(() => _floorLevels = floorManager.levels);

      // Select the ground floor (verticalOrder of 0).
      final initialFloor = _floorLevels
          .where((floor) => floor.verticalOrder == 0)
          .firstOrNull;
      if (initialFloor != null) {
        _selectFloor(initialFloor);
      }

      // Enable the UI once the map and floor levels are ready.
      setState(() => _ready = true);
    } on Exception catch (exception) {
      if (!mounted) return;

      showExceptionDialog('Failed to load the floor-aware web map', exception);
    }
  }

  void _selectFloor(FloorLevel selectedFloor) {
    // Update floor visibility to show only the selected floor.
    for (final floor in _floorLevels) {
      floor.isVisible = floor.verticalOrder == selectedFloor.verticalOrder;
    }

    // Update the dropdown to match the visible floor.
    setState(() => _selectedFloor = selectedFloor);
  }
}
