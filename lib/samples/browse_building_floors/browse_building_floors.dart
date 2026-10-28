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
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
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

  // Create a controller for the FloorFilter widget.
  late final _floorFilterController = FloorFilter.createController(
    _mapViewController,
  );

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          // Create a floor filter and display on top of the map in the bottom left.
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: .bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 40),
                  child: FloorFilter(
                    floorFilterController: _floorFilterController,
                  ),
                ),
              ),
            ),
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
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

      // Initialize the floor filter with the current map's floor information.
      await _floorFilterController.refresh();
      if (!mounted) return;

      // Ensure the map has a floor manager before proceeding.
      if (map.floorManager == null) {
        throw Exception('The map is not floor-aware.');
      }
      final floorManager = map.floorManager!;

      // Get the first facility from the first site, if available.
      final site = floorManager.sites.firstOrNull;
      final facility = site?.facilities.firstOrNull;
      if (site != null && facility != null) {
        // Set the selected site and facility, which will also select the first floor of that facility.
        _floorFilterController.selectedSiteId = site.siteId;
        _floorFilterController.selectedFacilityId = facility.facilityId;
      }

      // Enable the UI once the map and floor levels are ready.
      setState(() => _ready = true);
    } on Exception catch (exception) {
      if (!mounted) return;

      showExceptionDialog('Failed to load the floor-aware web map', exception);
    }
  }
}
