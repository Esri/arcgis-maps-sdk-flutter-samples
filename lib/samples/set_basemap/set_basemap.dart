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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class SetBasemap extends StatefulWidget {
  const SetBasemap({super.key});

  @override
  State<SetBasemap> createState() => _SetBasemapState();
}

class _SetBasemapState extends State<SetBasemap> with SampleStateSupport {
  // Create a controller for the map view and a map with an imagery basemap.
  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
  // Create a controller for the basemap gallery component.
  late final BasemapGalleryController _basemapGalleryController;
  // Track whether the basemap gallery panel is visible.
  var _showBasemapGallery = false;

  @override
  void initState() {
    super.initState();
    // Configure the gallery to update the map's basemap automatically.
    _basemapGalleryController = BasemapGalleryController()
      ..geoModel = _arcGISMap
      ..viewStyle = BasemapGalleryViewStyle.automatic;
  }

  @override
  void dispose() {
    _basemapGalleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use half of the available width for the gallery panel.
          final galleryWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // Show the map in the background.
              ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
              // Show the basemap gallery as an overlay panel.
              if (_showBasemapGallery)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: galleryWidth,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.copyWith(
                            bodySmall: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ),
                        child: BasemapGallery(
                          controller: _basemapGalleryController,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // Toggle the basemap gallery panel.
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            setState(() => _showBasemapGallery = !_showBasemapGallery),
        shape: const RoundedRectangleBorder(),
        child: const Icon(Icons.map),
      ),
    );
  }

  void onMapViewReady() {
    // Set the map's initial viewpoint.
    _arcGISMap.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 33.7,
      longitude: -118.4,
      scale: 1000000,
    );

    // Assign the map to the map view controller.
    _mapViewController.arcGISMap = _arcGISMap;
  }
}
