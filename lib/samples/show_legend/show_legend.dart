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
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ShowLegend extends StatefulWidget {
  const ShowLegend({super.key});
  @override
  State<ShowLegend> createState() => _ShowLegendState();
}

class _ShowLegendState extends State<ShowLegend>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // Create a map with a basemap style.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
  // Create a list to store dropdown items.
  var _legendsDropDown = <DropdownMenuItem<LegendInfo>>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          // Add the map view and dropdown button to a column.
          children: [
            Expanded(
              // Add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            // Add a dropdown button to the widget tree.
            DropdownButtonHideUnderline(
              child: DropdownButton(
                menuMaxHeight: 200,
                alignment: Alignment.center,
                hint: const Text(
                  'Legend',
                  style: TextStyle(
                    color: Colors.deepPurple,
                  ),
                ),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                // No need to set up onChanged callback.
                onChanged: (_) {},
                items: _legendsDropDown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Get the screen scale.
    final screenScale = MediaQuery.of(context).devicePixelRatio;
    // Create an image layer.
    final imageLayer = ArcGISMapImageLayer.withUri(
      Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer'),
    );
    // Create a feature table.
    final featureTable = ServiceFeatureTable.withUri(
      Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0'),
    );
    // Create a feature layer.
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    // Add image and feature layers to the operational layers list of the map.
    _map.operationalLayers.addAll([imageLayer, featureLayer]);
    // Load the image and feature layers.
    await featureLayer.load();
    await imageLayer.load();
    // Create a list to store operational layers and populate it with image and feature layers.
    final operationalLayersList = <LayerContent>[
      ...imageLayer.subLayerContents,
      featureLayer
    ];

    // Create a list to store dropdown items.
    final legendsDropDown = <DropdownMenuItem<LegendInfo>>[];
    // Get the legend info for each layer and add it to the legends dropdown list.
    for (final layer in operationalLayersList) {
      // Get the legend info for the current layer.
      final layerLegends = await layer.fetchLegendInfos();
      // Add the name of the current layer.
      legendsDropDown.add(
        DropdownMenuItem(
          value: layerLegends.first,
          child: Text(
            layer.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Add current layer's legends to the dropdown list.
      for (final legend in layerLegends) {
        ArcGISImage? arcGISImage;
        // Create a swatch for the legend if the legend exists.
        if (legend.symbol != null) {
          arcGISImage = await legend.symbol!.createSwatch(
            screenScale: screenScale,
            backgroundColor: Colors.transparent,
            size: const Size.square(6),
          );
        }
        // Add the legend to the legends list.
        legendsDropDown.add(
          DropdownMenuItem(
            value: legend,
            child: Row(
              children: [
                // Add the legend image to the dropdown list if the image exists.
                arcGISImage != null
                    ? Image.memory(
                        arcGISImage.getEncodedBuffer(),
                      )
                    : Container(),
                const SizedBox(width: 8),
                // Add the legend name to the dropdown list.
                Text(
                  legend.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
    }
    // Reset the state once the dropdown list is updated.
    setState(() => _legendsDropDown = legendsDropDown);

    // Set the map to the map view controller.
    _mapViewController.arcGISMap = _map;
    // Set the initial viewpoint of the map.
    _map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -11e6,
        y: 6e6,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 9e7,
    );
  }
}
