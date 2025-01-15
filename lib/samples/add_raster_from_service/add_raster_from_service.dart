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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

class AddRasterFromService extends StatefulWidget {
  const AddRasterFromService({super.key});

  @override
  State<AddRasterFromService> createState() => _AddRasterFromServiceState();
}

class _AddRasterFromServiceState extends State<AddRasterFromService> {
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
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with the ArcGIS DarkGrayBase basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISDarkGrayBase);

    // Set the map to _mapViewController.
    _mapViewController.arcGISMap = map;

    // Creates an initial viewpoint with a coordinate point centered on
    // San Francisco's Golden Gate Bridge.
    _mapViewController.setViewpoint(
      Viewpoint.fromCenter(
        ArcGISPoint(
          x: -13637000,
          y: 4550000,
          spatialReference: SpatialReference.webMercator,
        ),
        scale: 100000,
      ),
    );

    //Creates a raster from an image service.
    final imageServiceRaster = ImageServiceRaster(
      uri: Uri.parse(
        'https://gis.ngdc.noaa.gov/arcgis/rest/services/bag_hillshades_subsets/ImageServer',
      ),
    );

    // Create a raster layer from the raster.
    final rasterLayer = RasterLayer.withRaster(imageServiceRaster);

    // Add Raster layer to the map.
    map.operationalLayers.add(rasterLayer);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
