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
                    DropdownButton<SpatialReference>(
                      alignment: Alignment.center,
                      value: _selectedSpatialReference,
                      // Set the onChanged callback to update the selected spatial reference.
                      onChanged: (spatialReference) {
                        if (spatialReference == null) return;

                        setState(
                          () => _selectedSpatialReference = spatialReference,
                        );

                        // Set the map's spatial reference to the selected value.
                        _mapViewController.arcGISMap?.setSpatialReference(
                          spatialReference,
                        );
                      },
                      items: [
                        DropdownMenuItem(
                          value: SpatialReference(wkid: 102299),
                          child: const Text('Berghaus Star AAG'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 54050),
                          child: const Text('Fuller'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 27200),
                          child: const Text('New Zealand Map Grid'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 102018),
                          child: const Text('North Pole Stereographic'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 54090),
                          child: const Text('Peirce Quincuncial'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 32610),
                          child: const Text('UTM Zone 10 N'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 54024),
                          child: const Text('World Bonne'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 54052),
                          child: const Text('World Goode Homolosine'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference(wkid: 102038),
                          child: const Text('World Orthographic'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference.webMercator,
                          child: const Text('Web Mercator'),
                        ),

                        DropdownMenuItem(
                          value: SpatialReference.wgs84,
                          child: const Text('WGS 84'),
                        ),
                      ],
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
