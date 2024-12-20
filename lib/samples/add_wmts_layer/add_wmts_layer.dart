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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class AddWmtsLayer extends StatefulWidget {
  const AddWmtsLayer({super.key});

  @override
  State<AddWmtsLayer> createState() => _AddWmtsLayerState();
}

class _AddWmtsLayerState extends State<AddWmtsLayer> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The URI to a WMTS service.
  final wmtsServiceUri = Uri.parse(
    'https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer/WMTS',
  );
  // A flag indicating which layer constructor is currently being used.
  var _fromUriActive = true;
  // A flag for when the map is ready and controls can be used.
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Configure buttons to select the layer to display.
                    ElevatedButton(
                      onPressed: _fromUriActive ? null : createWmtsLayerFromUri,
                      child: const Text('From URI'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _fromUriActive ? createWmtsLayerFromLayerInfo : null,
                      child: const Text('From LayerInfo'),
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

  Future<void> onMapViewReady() async {
    // Initially display the map with the URI constructor.
    createWmtsLayerFromUri();
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void createWmtsLayerFromUri() {
    // Create a WMTS Layer using a URI and layer ID.
    final wmtsLayerFromUri = WmtsLayer.withUri(
      wmtsServiceUri,
      layerId: 'WorldTimeZones',
    );
    // Create a map and add the layer to the map's operational layers.
    final map = ArcGISMap();
    map.operationalLayers.add(wmtsLayerFromUri);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Set flag indicating the constructor being used.
    setState(() => _fromUriActive = true);
  }

  Future<void> createWmtsLayerFromLayerInfo() async {
    // Set the ready state variable to false to disable the sample UI.
    setState(() => _ready = false);
    // Create a map.
    final map = ArcGISMap();
    // Create a WMTS Layer using a WMTSLayerInfo.
    // Create a WMTS service and load.
    final service = WmtsService.withUri(wmtsServiceUri);
    await service.load();
    // Once loaded get the layer infos from the service info and create a WMTS layer from the first layer.
    if (service.serviceInfo != null &&
        service.serviceInfo!.layerInfos.isNotEmpty) {
      final layerInfos = service.serviceInfo!.layerInfos;
      final wmtsFromLayerInfo = WmtsLayer.withLayerInfo(layerInfos.first);
      // Create a basemap using the WMTS layer and set to the map.
      final basemap = Basemap.withBaseLayer(wmtsFromLayerInfo);
      map.basemap = basemap;
    }
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;
    // Set the ready state variable to true to enable the sample UI.
    setState(() {
      _fromUriActive = false;
      _ready = true;
    });
  }
}
