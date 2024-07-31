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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class SetBasemap extends StatefulWidget {
  const SetBasemap({super.key});

  @override
  State<SetBasemap> createState() => _SetBasemapState();
}

class _SetBasemapState extends State<SetBasemap>
    with SampleStateSupport {
  // Create a key to access the scaffold state.
  final _scaffoldStateKey = GlobalKey<ScaffoldState>();
  // Create a controller for the map view and a map with a navigation basemap.
  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
  // Create a dictionary to store basemaps.
  final _basemaps = <Basemap, Image>{};
  // Create a default image.
  final _defaultImage = Image.asset('assets/basemap_default.png');
  // Create a future to load basemaps.
  late Future _loadBasemapsFuture;
  // Create a variable to store the selected basemap.
  Basemap? _selectedBasemap;

  @override
  void initState() {
    super.initState();
    // Load basemaps when the app starts.
    _loadBasemapsFuture = loadBasemaps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Create a scaffold with a key to access the scaffold state.
      key: _scaffoldStateKey,
      // Create an end drawer to display basemaps.
      endDrawer: Drawer(
        child: SafeArea(
          // Create a future builder to load basemaps.
          child: FutureBuilder(
            future: _loadBasemapsFuture,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  // Create a grid view to display basemaps.
                  return GridView.count(
                    crossAxisCount: 2,
                    children: _basemaps.keys
                        .map(
                          // Create a list tile for each basemap.
                          (basemap) => ListTile(
                            title: Column(
                              children: [
                                Container(
                                  // Add a border to the selected basemap.
                                  decoration: _selectedBasemap == basemap
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 4,
                                          ),
                                        )
                                      : null,
                                  // Display the basemap image.
                                  child: _basemaps[basemap] ?? _defaultImage,
                                ),
                                Text(
                                  basemap.name,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            // Update the map with the selected basemap.
                            onTap: () {
                              _selectedBasemap = basemap;
                              updateMap(basemap);
                              _scaffoldStateKey.currentState!.closeEndDrawer();
                            },
                          ),
                        )
                        .toList(),
                  );
                default:
                  // Display a loading message while loading basemaps.
                  return const Center(
                    child: Text('Loading basemaps...'),
                  );
              }
            },
          ),
        ),
      ),
      // Create a stack with the map view and a floating action button to open the end drawer.
      body: Stack(
        children: [
          // Create an ArcGIS map view with a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          Positioned(
            bottom: 70,
            right: 30,
            child: FloatingActionButton(
              onPressed: () => _scaffoldStateKey.currentState!.openEndDrawer(),
              shape: const RoundedRectangleBorder(),
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }

  void onMapViewReady() {
    // Set the map view controller's map to the ArcGIS map.
    _mapViewController.arcGISMap = _arcGISMap;
  }

  void updateMap(Basemap basemap) {
    // Update the map view with the selected basemap.
    _arcGISMap.basemap = basemap;
  }

  Future loadBasemaps() async {
    // Create a portal to access online items.
    final portal = Portal.arcGISOnline();
    // Load basemaps from portal.
    final basemaps = await portal.developerBasemaps();

    // Load each basemap to access and display attribute data in the UI.
    for (final basemap in basemaps) {
      await basemap.load();
      if (basemap.item != null) {
        final thumbnail = basemap.item!.thumbnail;
        if (thumbnail != null) {
          await thumbnail.load();
          _basemaps[basemap] = Image.network(thumbnail.uri.toString());
        }
      } else {
        // If the basemap does not have a thumbnail, use the default image.
        _basemaps[basemap] = _defaultImage;
      }
    }
  }
}
