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
import 'package:flutter/material.dart';

class AddWmsLayer extends StatefulWidget {
  const AddWmsLayer({super.key});

  @override
  State<AddWmsLayer> createState() => _AddWmsLayerState();
}

class _AddWmsLayerState extends State<AddWmsLayer> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // The URL to a WMS service showing U.S. weather radar.
    final uri = Uri.parse(
      'https://nowcoast.noaa.gov/geoserver/observations/weather_radar/wms?SERVICE=WMS&REQUEST=GetCapabilities',
    );
    // A list of uniquely-identifying WMS layer names to display.
    final layerNames = ['conus_base_reflectivity_mosaic'];
    // Create a WMS layer using the URL and list of names.
    final wmsLayer =
        WmsLayer.withUriAndLayerNames(uri: uri, layerNames: layerNames);
    // Load the layer and get the extent.
    await wmsLayer.load();
    final layerExtent = wmsLayer.fullExtent;
    // Set the viewpoint to the layer's extent.
    if (layerExtent != null) {
      _mapViewController.setViewpoint(Viewpoint.fromTargetExtent(layerExtent));
    }
    // Add the WMS layer to the map's operational layers.
    map.operationalLayers.add(wmsLayer);
  }
}
