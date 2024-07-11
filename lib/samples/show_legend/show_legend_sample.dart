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

class ShowLegendSample extends StatefulWidget {
  const ShowLegendSample({super.key});
  @override
  State<ShowLegendSample> createState() => _ShowLegendSampleState();
}

class _ShowLegendSampleState extends State<ShowLegendSample>
    with SampleStateSupport {
  // create a map view controller
  final _mapViewController = ArcGISMapView.createController();
  // create a map with a basemap style
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
  // create a variable to store the selected legend
  LegendInfo? _selectedLegend;
  // create a variable to store the legend image
  ArcGISImage? _arcGISImage; 
  // create a list to store dropdown items
  final _legendsDropDown = <DropdownMenuItem<LegendInfo>>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          // add the map view and dropdown button to a column.
          children: [
            Expanded(
              // add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            // add a dropdown button to the widget tree.
            DropdownButtonHideUnderline(
              child: DropdownButton(
                value: _selectedLegend,
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
                // no need to set up onChanged callback
                onChanged: (n) {},
                items: _legendsDropDown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // get the screen scale
    final screenScale = MediaQuery.of(context).devicePixelRatio;
    // create an image layer
    final imageLayer = ArcGISMapImageLayer.withUri(
      Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer'),
    );
    // create a feature table
    final featureTable = ServiceFeatureTable.withUri(
      Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/FeatureServer/0'),
    );
    // create a feature layer
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    // add image and feature layers to the opertaional layers list of the map
    _map
      ..operationalLayers.add(imageLayer)
      ..operationalLayers.add(featureLayer);
    // load the image and feature layers
    await featureLayer.load();
    await imageLayer.load();
    // create a list to store operational layers and populate it with image and feature layers
    final operationalLayersList = <LayerContent>[
      ...imageLayer.subLayerContents,
      featureLayer
    ];

    // get the legend info for each layer and add it to the legends dropdown list
    for (var layer in operationalLayersList) {
      // get the legend info for the current layer
      final layerLegends = await layer.fetchLegendInfos();
      // add the name of the current layer
      _legendsDropDown.add(
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

      // add current layer's legends to the dropdown list
      for (var legend in layerLegends) {
        try {
          // create a swatch for the legend
          _arcGISImage = await legend.symbol!.createSwatch(
            screenScale: screenScale,
            backgroundColor: Colors.transparent,
            size: const Size.square(6),
          );
        } catch (e) {}
        // add the legend to the legends list
        _legendsDropDown.add(
          DropdownMenuItem(
            value: legend,
            child: Row(
              children: [
                // add the legend image to the dropdown list
                Image.memory(
                  _arcGISImage!.getEncodedBuffer(),
                ),
                const SizedBox(width: 8),
                // add the legend name to the dropdown list
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

    // set the map to the map view controller
    _mapViewController.arcGISMap = _map;
    // set the initial viewpoint of the map
    _map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -11e6,
        y: 6e6,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 9e7,
    );
    // reset the state once the dropdown list is updated
    setState(() {});
  }
}
