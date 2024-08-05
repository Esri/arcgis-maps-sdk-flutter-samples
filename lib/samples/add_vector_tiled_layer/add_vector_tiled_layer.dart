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

// An enumeration of vector tiled layers to choose from.
enum VectorTiledItem {
  midCentury('Mid-Century', '7675d44bb1e4428aa2c30a9b68f97822'),
  coloredPencil('Colored Pencil', '4cf7e1fb9f254dcda9c8fbadb15cf0f8'),
  newspaper('Newspaper', 'dfb04de5f3144a80bc3f9f336228d24a'),
  nova('Nova', '75f4dfdff19e445395653121a95a85db'),
  worldStreetMapNight(
    'World Street Map (Night)',
    '86f556a2d1fd468181855a35e344567f',
  );

  final String label;
  final String itemId;
  const VectorTiledItem(this.label, this.itemId);

  // A menu item for this selection.
  DropdownMenuItem<VectorTiledItem> get menuItem =>
      DropdownMenuItem(value: this, child: Text(label));

  // The service URL for this selection.
  Uri get uri => Uri.parse('https://www.arcgis.com/home/item.html?id=$itemId');
}

class AddVectorTiledLayer extends StatefulWidget {
  const AddVectorTiledLayer({super.key});

  @override
  State<AddVectorTiledLayer> createState() => _AddVectorTiledLayerState();
}

class _AddVectorTiledLayerState extends State<AddVectorTiledLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Prepare menu items for the selection of vector tiled layers.
  final _selectionMenuItems =
      VectorTiledItem.values.map((selection) => selection.menuItem).toList();
  VectorTiledItem? _selection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              // Add a map view to the widget tree and set a controller.
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
              ),
            ),
            Center(
              // Add a dropdown button to select a vector tiled layer.
              child: DropdownButton(
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.deepPurple,
                ),
                style: const TextStyle(color: Colors.deepPurple),
                alignment: Alignment.center,
                value: _selection,
                items: _selectionMenuItems,
                onChanged: loadSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() {
    // Initially load the Mid-Century vector tiled layer.
    loadSelection(VectorTiledItem.midCentury);
  }

  void loadSelection(VectorTiledItem? selection) {
    if (selection != null) {
      // Create a vector tiled layer with a URL to the vector tile service.
      final vectorTiledLayer = ArcGISVectorTiledLayer.withUri(selection.uri);
      // Create a basemap with the vector tiled layer.
      final basemap = Basemap.withBaseLayer(vectorTiledLayer);
      // Create a map with the basemap.
      final map = ArcGISMap.withBasemap(basemap);
      // Set the map to the map view.
      _mapViewController.arcGISMap = map;
    } else {
      _mapViewController.arcGISMap = null;
    }

    setState(() => _selection = selection);
  }
}
