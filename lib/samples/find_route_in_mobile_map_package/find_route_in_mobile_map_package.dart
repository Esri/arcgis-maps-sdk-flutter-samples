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

import 'dart:io';
import 'dart:typed_data';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_data.dart';
import '../../utils/sample_state_support.dart';

class FindRouteInMobileMapPackage extends StatefulWidget {
  const FindRouteInMobileMapPackage({super.key});

  @override
  State<FindRouteInMobileMapPackage> createState() =>
      _FindRouteInMobileMapPackageState();
}

class _FindRouteInMobileMapPackageState
    extends State<FindRouteInMobileMapPackage> with SampleStateSupport {
  //fixme comments throughout
  Future<List<MobileMapPackage>>? mobileMapPackagesFuture;

  @override
  void initState() {
    super.initState();
    mobileMapPackagesFuture = loadMobileMapPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: mobileMapPackagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final locatorTaskForMap = <ArcGISMap, LocatorTask?>{};
            final maps = <ArcGISMap>[];
            for (final mmpk in snapshot.data!) {
              for (final map in mmpk.maps) {
                maps.add(map);
                locatorTaskForMap[map] = mmpk.locatorTask;
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Image.memory(
                        map.item?.thumbnail?.image?.getEncodedBuffer() ??
                            Uint8List(0),
                      ),
                      title: Text(map.item?.name ?? ''),
                      trailing: map.transportationNetworks.isNotEmpty
                          ? const Icon(Icons.directions_outlined)
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FindRouteInMap(
                              map: map,
                              locatorTask: locatorTaskForMap[map],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<List<MobileMapPackage>> loadMobileMapPackages() async {
    await downloadSampleData(
      [
        'e1f3a7254cb845b09450f54937c16061',
        '260eb6535c824209964cf281766ebe43',
      ],
    );

    final appDir = await getApplicationDocumentsDirectory();

    final mobileMapPackages = <MobileMapPackage>[];

    for (final filename in ['SanFrancisco', 'Yellowstone']) {
      final mmpkFile = File('${appDir.absolute.path}/$filename.mmpk');
      final mmpk = MobileMapPackage.withFileUri(mmpkFile.uri);
      await mmpk.load();
      mobileMapPackages.add(mmpk);
    }

    return mobileMapPackages;
  }
}

class FindRouteInMap extends StatefulWidget {
  const FindRouteInMap({
    super.key,
    required this.map,
    required this.locatorTask,
  });

  final ArcGISMap map;
  final LocatorTask? locatorTask;

  @override
  State<FindRouteInMap> createState() => _FindRouteInMapState();
}

class _FindRouteInMapState extends State<FindRouteInMap> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  final _markerOverlay = GraphicsOverlay();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.map.item?.name ?? '')),
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: widget.locatorTask != null ? onTap : null,
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          Visibility(
            visible: !_ready,
            child: SizedBox.expand(
              child: Container(
                color: Colors.white30,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    _mapViewController.arcGISMap = widget.map;

    // Create a picture marker symbol using an image asset.
    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image)
      ..width = 35
      ..height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
    _markerOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _mapViewController.graphicsOverlays.add(_markerOverlay);

    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    final result = await _mapViewController.identifyGraphicsOverlay(
      _markerOverlay,
      screenPoint: localPosition,
      tolerance: 12.0,
    );
    if (result.graphics.isEmpty) {
      final location =
          _mapViewController.screenToLocation(screen: localPosition);
      if (location != null) {
        _markerOverlay.graphics.add(Graphic(geometry: location));
        reverseGeocode(location);
      }
    } else {
      final location = result.graphics.first.geometry as ArcGISPoint?;
      if (location != null) {
        reverseGeocode(location);
      }
    }
  }

  void reverseGeocode(ArcGISPoint point) {
    //fixme
  }
}
