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

class SetSpatialReference extends StatefulWidget {
  const SetSpatialReference({super.key});

  @override
  State<SetSpatialReference> createState() => _SetSpatialReferenceState();
}

class _SetSpatialReferenceState extends State<SetSpatialReference>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // The spatial reference currently selected in the dropdown.
  SpatialReference? _selectedSpatialReference;

  // Stores the spatial references available in the dropdown.
  final _spatialReferences = <DropdownMenuEntry<SpatialReference>>[];

  @override
  void initState() {
    super.initState();

    // Add spatial references to the dropdown menu.2
    _spatialReferences.addAll([
      DropdownMenuEntry(
        value: SpatialReference(wkid: 102299),
        label: 'Berghaus Star AAG',
      ),
      DropdownMenuEntry(value: SpatialReference(wkid: 54050), label: 'Fuller'),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 27200),
        label: 'New Zealand Map Grid',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 102018),
        label: 'North Pole Stereographic',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 54090),
        label: 'Peirce Quincuncial',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 32610),
        label: 'UTM Zone 10 N',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 54024),
        label: 'World Bonne',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 54052),
        label: 'World Goode Homolosine',
      ),
      DropdownMenuEntry(
        value: SpatialReference(wkid: 102038),
        label: 'World Orthographic',
      ),
      DropdownMenuEntry(
        value: SpatialReference.webMercator,
        label: 'Web Mercator',
      ),
      DropdownMenuEntry(value: SpatialReference.wgs84, label: 'WGS 84'),
    ]);
  }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // A dropdown button to select the spatial reference.
                    DropdownMenu(
                      dropdownMenuEntries: _spatialReferences,
                      textAlign: TextAlign.center,
                      onSelected: (spatialReference) {
                        // Return if no spatial reference was selected.
                        if (spatialReference == null) return;

                        // Update the selected spatial reference.
                        setState(() {
                          _selectedSpatialReference = spatialReference;
                        });

                        // Set the map's spatial reference to the selected value.
                        _mapViewController.arcGISMap?.setSpatialReference(
                          spatialReference,
                        );
                      },
                      initialSelection: _selectedSpatialReference,
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

  void onMapViewReady() {
    // Create a map using the World Bonne spatial reference.
    final map = ArcGISMap(spatialReference: SpatialReference(wkid: 54024));

    // Create a map image layer.
    final mapImageLayer = ArcGISMapImageLayer.withUri(
      Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer',
      ),
    );

    // Create a basemap from the map image layer.15
    map.basemap = Basemap.withBaseLayer(mapImageLayer);

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Set the initial selected spatial reference and enable the sample UI.
    setState(() {
      _selectedSpatialReference = map.spatialReference;
      _ready = true;
    });
  }
}
