//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
//

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../sample_data.dart';

class SetBasemapSample extends StatefulWidget {
  const SetBasemapSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SetBasemapSampleState createState() => SetBasemapSampleState();
}

class SetBasemapSampleState extends State<SetBasemapSample> {
  final GlobalKey<ScaffoldState> _scaffoldStateKey = GlobalKey();

  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
  final _basemaps = <Basemap, Image>{};
  final _defaultImage = Image.asset('assets/samples/basemap_default.png');
  final _sanFranciscoViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(x: -13630206, y: 4546929),
    scale: 100000,
  );
  late Future _loadBasemapsFuture;

  @override
  void initState() {
    super.initState();

    _arcGISMap.initialViewpoint = _sanFranciscoViewpoint;
    _mapViewController.arcGISMap = _arcGISMap;
    _loadBasemapsFuture = loadBasemaps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      key: _scaffoldStateKey,
      endDrawer: Drawer(
        child: SafeArea(
          child: FutureBuilder(
            future: _loadBasemapsFuture,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  return GridView.count(
                    crossAxisCount: 2,
                    children: _basemaps.keys
                        .map(
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
                            onTap: () {
                              updateMap(basemap);
                              _scaffoldStateKey.currentState!.closeEndDrawer();
                            },
                          ),
                        )
                        .toList(),
                  );
                default:
                  return const Center(
                    child: Text("Loading basemaps..."),
                  );
              }
            },
          ),
        ),
      ),
      body: Stack(
        children: [
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
    _arcGISMap.basemap = basemap;
    _mapViewController.setViewpointAnimated(_sanFranciscoViewpoint);
    _mapViewController.setViewpointRotation(angleDegrees: 0.0);
  }

  Future loadBasemaps() async {
    // load basemaps from online items
    List<Basemap> basemaps = List.from([
      Basemap.withUri(Uri.parse(
          'https://runtime.maps.arcgis.com/home/item.html?id=9b39104916614f0899993934d2f1d375')), // newspaper - from different org
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=358ec1e175ea41c3bf5c68f0da11ae2b')), // dark gray canvas
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=979c6cc89af9449cbeb5342a439c6a76')), // light gray canvas
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=fae788aa91e54244b161b59725dcbb2a')), // OSM
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=28f49811a6974659988fd279de5ce39f')), // Imagery
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=2e8a3ccdfd6d42a995b79812b3b0ebc6')), // Outdoor
      Basemap.withUri(Uri.parse(
          'https://www.arcgis.com/home/item.html?id=7e2b9be8a9c94e45b7f87857d8d168d6')), // Streets night
      Basemap.withStyle(BasemapStyle.arcGISNavigation), // No thumbnail
    ]);

    // load each basemap to access and display attribute data in the UI
    for (var basemap in basemaps) {
      await basemap.load();
      if (basemap.item != null) {
        var thumbnail = basemap.item!.thumbnail;
        if (thumbnail != null) {
          await thumbnail.load();
          _basemaps[basemap] = Image.network(thumbnail.uri.toString());
        }
      } else {
        _basemaps[basemap] = _defaultImage;
      }
    }

    // load basemaps from local packages
    await loadTileCache();
  }

  Future loadTileCache() async {
    await downloadSampleData(['e4a398afe9a945f3b0f4dca1e4faccb5']);
    const tilePackageName = 'SanFrancisco.tpkx';
    final appDir = await getApplicationDocumentsDirectory();
    final tpkxPath = '${appDir.absolute.path}/$tilePackageName';

    final tileCache = TileCache.withFileUri(Uri.parse(tpkxPath));
    // wait for the tile cache to load to access and display thumbnail
    await tileCache.load();
    final tiledLayer = ArcGISTiledLayer.withTileCache(tileCache);
    final tiledLayerBasemap = Basemap.withBaseLayer(tiledLayer);
    if (tileCache.thumbnail != null) {
      _basemaps[tiledLayerBasemap] =
          Image.memory(tileCache.thumbnail!.getEncodedBuffer());
    } else {
      _basemaps[tiledLayerBasemap] = _defaultImage;
    }
  }
}
