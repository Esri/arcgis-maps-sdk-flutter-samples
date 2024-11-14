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

typedef SampleData = ({
  ArcGISMap map,
  Uint8List? thumbnail,
  LocatorTask? locatorTask
});

class _FindRouteInMobileMapPackageState
    extends State<FindRouteInMobileMapPackage> with SampleStateSupport {
  //fixme comments throughout
  final mobileMapPackages = loadMobileMapPackages();

  static Future<List<MobileMapPackage>> loadMobileMapPackages() async {
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
      mobileMapPackages.add(mmpk);
    }
    await Future.wait(mobileMapPackages.map((mmpk) => mmpk.load()));
    return mobileMapPackages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: mobileMapPackages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final sampleData = <SampleData>[];
              for (final mmpk in snapshot.data!) {
                for (final map in mmpk.maps) {
                  sampleData.add(
                    (
                      map: map,
                      thumbnail: map.item?.thumbnail?.image?.getEncodedBuffer(),
                      locatorTask: mmpk.locatorTask,
                    ),
                  );
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: sampleData.length,
                itemBuilder: (context, index) {
                  final data = sampleData[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: data.thumbnail != null
                            ? Image.memory(data.thumbnail!)
                            : null,
                        title: Text(data.map.item?.name ?? ''),
                        trailing: data.map.transportationNetworks.isNotEmpty
                            ? const Icon(Icons.directions_outlined)
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FindRouteInMap(sampleData: data),
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
      ),
    );
  }
}

class FindRouteInMap extends StatefulWidget {
  const FindRouteInMap({
    super.key,
    required this.sampleData,
  });

  final SampleData sampleData;

  @override
  State<FindRouteInMap> createState() => _FindRouteInMapState();
}

class _FindRouteInMapState extends State<FindRouteInMap>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  final _markerOverlay = GraphicsOverlay();
  GraphicsOverlay? _routeOverlay;
  RouteTask? _routeTask;
  RouteParameters? _routeParameters;
  var _message = '';
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  Graphic? _selectedGraphic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sampleData.map.item?.name ?? '')),
      body: SafeArea(
        left: false,
        top: false,
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
                    onTap: widget.sampleData.locatorTask != null ? onTap : null,
                  ),
                ),
                Visibility(
                  visible: widget.sampleData.locatorTask != null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _selectedGraphic == null ? null : delete,
                        child: const Text('Delete'),
                      ),
                      ElevatedButton(
                        onPressed: reset,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Add a banner to show the results of the identify operation.
            SafeArea(
              child: IgnorePointer(
                child: Visibility(
                  visible: _message.isNotEmpty,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.black.withOpacity(0.7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      ),
    );
  }

  void onMapViewReady() async {
    final map = widget.sampleData.map;
    _mapViewController.arcGISMap = map;

    // Create a picture marker symbol using an image asset.
    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image)
      ..width = 35
      ..height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
    _markerOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _mapViewController.graphicsOverlays.add(_markerOverlay);

    if (map.transportationNetworks.isNotEmpty) {
      final dataset = map.transportationNetworks.first;
      _routeTask = RouteTask.withDataset(dataset);
      _routeParameters = await _routeTask!.createDefaultParameters();

      final routeSymbol = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid,
        color: const Color.fromARGB(255, 0, 0, 255),
        width: 5.0,
      );
      _routeOverlay = GraphicsOverlay()
        ..renderer = SimpleRenderer(symbol: routeSymbol);
      _mapViewController.graphicsOverlays.add(_routeOverlay!);
    }

    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    if (_selectedGraphic != null) {
      _selectedGraphic!.isSelected = false;
      setState(() => _selectedGraphic = null);
    }

    final result = await _mapViewController.identifyGraphicsOverlay(
      _markerOverlay,
      screenPoint: localPosition,
      tolerance: 12.0,
    );

    Graphic? graphicToSelect;
    if (result.graphics.isNotEmpty) {
      graphicToSelect = result.graphics.first;
    } else {
      final location =
          _mapViewController.screenToLocation(screen: localPosition);
      if (location != null) {
        graphicToSelect = Graphic(geometry: location);
        _markerOverlay.graphics.add(graphicToSelect);
      }
    }
    if (graphicToSelect != null) {
      graphicToSelect.isSelected = true;
      setState(() => _selectedGraphic = graphicToSelect);
      await reverseGeocode(graphicToSelect);
    }

    await updateRoute();
  }

  Future<void> reverseGeocode(Graphic graphic) async {
    final reverseGeocodeParameters = ReverseGeocodeParameters()
      ..resultAttributeNames.addAll(['StAddr', 'City', 'Region'])
      ..maxResults = 1;

    final results = await widget.sampleData.locatorTask!.reverseGeocode(
      location: graphic.geometry as ArcGISPoint,
      parameters: reverseGeocodeParameters,
    );

    final String address;
    if (results.isEmpty) {
      address = 'No address found';
    } else {
      final attributes = results.first.attributes;
      final street = attributes['StAddr'] as String? ?? '';
      final city = attributes['City'] as String? ?? '';
      final region = attributes['Region'] as String? ?? '';
      address = '$street, $city, $region';
    }
    setState(() => _message = address);
  }

  Future<void> updateRoute() async {
    if (_routeTask == null ||
        _routeParameters == null ||
        _routeOverlay == null ||
        _markerOverlay.graphics.length < 2) {
      _routeOverlay?.graphics.clear();
      return;
    }

    final stops = _markerOverlay.graphics
        .map((g) => Stop(g.geometry! as ArcGISPoint))
        .toList();
    _routeParameters!.clearStops();
    _routeParameters!.setStops(stops);

    try {
      final result = await _routeTask!.solveRoute(_routeParameters!);
      if (result.routes.isNotEmpty) {
        final routeGeometry = result.routes.first.routeGeometry;
        _routeOverlay!.graphics.clear();
        _routeOverlay!.graphics.add(Graphic(geometry: routeGeometry));
      }
    } on ArcGISException catch (e) {
      _routeOverlay!.graphics.clear();
      showError(e);
    }
  }

  void delete() async {
    _markerOverlay.graphics.remove(_selectedGraphic);
    setState(() {
      _selectedGraphic = null;
      _message = '';
    });
    await updateRoute();
  }

  void reset() {
    _selectedGraphic?.isSelected = false;
    setState(() => _selectedGraphic = null);
    _markerOverlay.graphics.clear();
    _routeOverlay?.graphics.clear();
    setState(() => _message = '');
  }

  void showError(ArcGISException e) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(content: Text(e.message)),
      );
    }
  }
}
