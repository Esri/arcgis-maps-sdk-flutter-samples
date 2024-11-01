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
            final maps =
                snapshot.data?.expand((mmpk) => mmpk.maps).toList() ?? [];
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
                            builder: (context) => FindRouteInMap(map: map),
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
  });

  final ArcGISMap map;

  @override
  State<FindRouteInMap> createState() => _FindRouteInMapState();
}

class _FindRouteInMapState extends State<FindRouteInMap> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.map.item?.name ?? '')),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() {
    _mapViewController.arcGISMap = widget.map;
  }
}
