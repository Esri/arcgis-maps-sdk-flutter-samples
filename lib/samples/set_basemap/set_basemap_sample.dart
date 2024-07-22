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
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_data.dart';
import '../../utils/sample_state_support.dart';

class SetBasemapSample extends StatefulWidget {
  const SetBasemapSample({super.key});

  @override
  State<SetBasemapSample> createState() => _SetBasemapSampleState();
}

class _SetBasemapSampleState extends State<SetBasemapSample>
    with SampleStateSupport {
  // Create a key to access the scaffold state.
  final GlobalKey<ScaffoldState> _scaffoldStateKey = GlobalKey();
  // Create a controller for the map view and a map with a navigation basemap.
  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
  // Create a dictionary to store basemaps.
  final _basemaps = <Basemap, Image>{};
  // Create a default image.
  final _defaultImage = Image.asset('assets/basemap_default.png');
  // Set the initial viewpoint to San Francisco.
  final _sanFranciscoViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(x: -13630206, y: 4546929),
    scale: 100000,
  );
  late Future _loadBasemapsFuture;

  @override
  void initState() {
    super.initState();
    // Set the initial viewpoint and basemap for the map.
    _arcGISMap.initialViewpoint = _sanFranciscoViewpoint;
    _mapViewController.arcGISMap = _arcGISMap;
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
          top: false,
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
                                _basemaps[basemap] ?? _defaultImage,
                                Text(
                                  basemap.name,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            // Update the map with the selected basemap.
                            onTap: () {
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

  void updateMap(Basemap basemap) {
    // Update the map view with the selected basemap.
    _arcGISMap.basemap = basemap;
    // Set the viewpoint to San Francisco.
    _mapViewController.setViewpointAnimated(_sanFranciscoViewpoint);
    // Set the rotation angle to 0.
    _mapViewController.setViewpointRotation(angleDegrees: 0.0);
  }

  Future loadBasemaps() async {
    // Create a portal to access online items.
    final portal = Portal.arcGISOnline();
    // Load basemaps from portal.
    List<Basemap> basemaps = await portal.developerBasemaps();

    // Load each basemap to access and display attribute data in the UI.
    for (var basemap in basemaps) {
      await basemap.load();
      if (basemap.item != null) {
        var thumbnail = basemap.item!.thumbnail;
        if (thumbnail != null) {
          await thumbnail.load();
          _basemaps[basemap] = Image.network(thumbnail.uri.toString());
        }
      } else {
        // If the basemap does not have a thumbnail, use the default image.
        _basemaps[basemap] = _defaultImage;
      }
    }

    // Load basemaps from local packages.
    await loadTileCache();
  }

  Future loadTileCache() async {
    // Download the sample data.
    await downloadSampleData(['e4a398afe9a945f3b0f4dca1e4faccb5']);
    const tilePackageName = 'SanFrancisco.tpkx';
    // Get the path to the sample data.
    final appDir = await getApplicationDocumentsDirectory();
    final tpkxPath = '${appDir.absolute.path}/$tilePackageName';

    // Load the tile cache from the sample data.
    final tileCache = TileCache.withFileUri(Uri.parse(tpkxPath));
    // Wait for the tile cache to load to access and display thumbnail.
    await tileCache.load();
    // Create a tiled layer with the tile cache.
    final tiledLayer = ArcGISTiledLayer.withTileCache(tileCache);
    // Create a basemap with the tiled layer.
    final tiledLayerBasemap = Basemap.withBaseLayer(tiledLayer);
    // If the tile cache has a thumbnail, use it; otherwise, use the default image.
    if (tileCache.thumbnail != null) {
      _basemaps[tiledLayerBasemap] =
          Image.memory(tileCache.thumbnail!.getEncodedBuffer());
    } else {
      _basemaps[tiledLayerBasemap] = _defaultImage;
    }
  }
}
