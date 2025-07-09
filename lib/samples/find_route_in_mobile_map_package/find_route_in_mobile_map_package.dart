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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FindRouteInMobileMapPackage extends StatefulWidget {
  const FindRouteInMobileMapPackage({super.key});

  @override
  State<FindRouteInMobileMapPackage> createState() =>
      _FindRouteInMobileMapPackageState();
}

// A record type to hold data related to a specific map.
typedef SampleData = ({
  ArcGISMap map,
  Uint8List? thumbnail,
  LocatorTask? locatorTask,
});

class _FindRouteInMobileMapPackageState
    extends State<FindRouteInMobileMapPackage>
    with SampleStateSupport {
  // A Future that completes with the list of mobile map packages.
  final mobileMapPackages = loadMobileMapPackages();

  static Future<List<MobileMapPackage>> loadMobileMapPackages() async {
    await downloadSampleData([
      'e1f3a7254cb845b09450f54937c16061',
      '260eb6535c824209964cf281766ebe43',
    ]);
    final appDir = await getApplicationDocumentsDirectory();

    // Load the local mobile map packages.
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
        // Display a list of maps from the mobile map packages once loaded.
        child: FutureBuilder(
          future: mobileMapPackages,
          builder: (context, snapshot) {
            // Show a progress indicator until the mobile map packages finish loading.
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    CircularProgressIndicator(),
                    Text('Downloading data...'),
                  ],
                ),
              );
            }

            // Create a list of SampleData records for maps from the loaded mobile map packages.
            final sampleData = <SampleData>[];
            for (final mmpk in snapshot.data!) {
              for (final map in mmpk.maps) {
                // For each map create a SampleData record defining the map itself, a thumbnail and the locator task from the mobile map package.
                sampleData.add((
                  map: map,
                  thumbnail: map.item?.thumbnail?.image?.getEncodedBuffer(),
                  locatorTask: mmpk.locatorTask,
                ));
              }
            }

            // Display the maps in a list.
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sampleData.length,
              // For each map, create a card with its thumbnail and name.
              itemBuilder: (context, index) {
                final data = sampleData[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: data.thumbnail != null
                          ? Image.memory(data.thumbnail!)
                          : null,
                      title: Text(data.map.item?.name ?? ''),
                      // If the map has transportation networks, show an icon indicating it supports routing.
                      trailing: data.map.transportationNetworks.isNotEmpty
                          ? const Icon(Icons.directions_outlined)
                          : null,
                      // When the card is tapped, navigate to a FindRouteInMap page.
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
          },
        ),
      ),
    );
  }
}

// A page for a specific map loaded from a mobile map package.
class FindRouteInMap extends StatefulWidget {
  const FindRouteInMap({required this.sampleData, super.key});

  final SampleData sampleData;

  @override
  State<FindRouteInMap> createState() => _FindRouteInMapState();
}

class _FindRouteInMapState extends State<FindRouteInMap>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create an overlay for location markers.
  final _markerOverlay = GraphicsOverlay();
  // The currently selected marker graphic.
  Graphic? _selectedGraphic;
  // A message to display the address of the selected location marker.
  var _message = '';
  // An overlay, task, and parameter object when routing is supported.
  GraphicsOverlay? _routeOverlay;
  RouteTask? _routeTask;
  RouteParameters? _routeParameters;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add an AppBar with the map's name.
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
                    // Add an onTap handler when geocoding is supported.
                    onTap: widget.sampleData.locatorTask != null ? onTap : null,
                  ),
                ),
                // Add controls that are usable when geocoding is supported.
                Visibility(
                  visible: widget.sampleData.locatorTask != null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add a button to delete the selected location marker.
                      ElevatedButton(
                        onPressed: _selectedGraphic == null
                            ? null
                            : deleteMarker,
                        child: const Text('Delete Marker'),
                      ),
                      // Add a button to reset all location markers and routes.
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
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.customWhiteStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    final map = widget.sampleData.map;
    _mapViewController.arcGISMap = map;

    // Create a picture marker symbol using an image asset.
    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image)
      ..width = 35
      ..height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
    // Configure the marker overlay with the picture marker symbol and add it to the list of overlays.
    _markerOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _mapViewController.graphicsOverlays.add(_markerOverlay);

    // Set up routing, if available.
    if (map.transportationNetworks.isNotEmpty) {
      // Create a RouteTask and RouteParameters using the map's transportation network dataset.
      final dataset = map.transportationNetworks.first;
      _routeTask = RouteTask.withDataset(dataset);
      _routeParameters = await _routeTask!.createDefaultParameters();

      // Create a symbol to represent the route.
      final routeSymbol = SimpleLineSymbol(
        color: const Color.fromARGB(255, 0, 0, 255),
        width: 5,
      );
      // Create a graphics overlay to display the route and add it to the list of overlays.
      _routeOverlay = GraphicsOverlay()
        ..renderer = SimpleRenderer(symbol: routeSymbol);
      _mapViewController.graphicsOverlays.add(_routeOverlay!);
    }

    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    // Deselect any previously selected graphic.
    if (_selectedGraphic != null) {
      _selectedGraphic!.isSelected = false;
      setState(() => _selectedGraphic = null);
    }

    // Perform an identify operation to determine if a graphic was tapped.
    final result = await _mapViewController.identifyGraphicsOverlay(
      _markerOverlay,
      screenPoint: localPosition,
      tolerance: 12,
    );

    Graphic? graphicToSelect;
    if (result.graphics.isNotEmpty) {
      // If a graphic was tapped, it will be selected.
      graphicToSelect = result.graphics.first;
    } else {
      // If no graphic was identified, add a new marker at the tapped location.
      final location = _mapViewController.screenToLocation(
        screen: localPosition,
      );
      if (location != null) {
        graphicToSelect = Graphic(geometry: location);
        _markerOverlay.graphics.add(graphicToSelect);
      }
    }
    if (graphicToSelect != null) {
      // Select the graphic.
      graphicToSelect.isSelected = true;
      setState(() => _selectedGraphic = graphicToSelect);
      // Perform a reverse geocode operation to get the address of the selected location.
      await reverseGeocode(graphicToSelect);
    }

    // Update the route, if available.
    await updateRoute();
  }

  Future<void> reverseGeocode(Graphic graphic) async {
    // Create parameters to return at most one match with the desired attributes.
    final reverseGeocodeParameters = ReverseGeocodeParameters()
      ..resultAttributeNames.addAll(['StAddr', 'City', 'Region'])
      ..maxResults = 1;

    // Perform the reverse geocode operation.
    final results = await widget.sampleData.locatorTask!.reverseGeocode(
      location: graphic.geometry! as ArcGISPoint,
      parameters: reverseGeocodeParameters,
    );

    final String address;
    if (results.isEmpty) {
      // If no address was found, display a message.
      address = 'No address found';
    } else {
      // If an address was found, format it into a string.
      final attributes = results.first.attributes;
      final street = attributes['StAddr'] as String? ?? '';
      final city = attributes['City'] as String? ?? '';
      final region = attributes['Region'] as String? ?? '';
      address = '$street, $city, $region';
    }
    setState(() => _message = address);
  }

  Future<void> updateRoute() async {
    // If routing is not available or if there aren't enough stops, clear the route overlay.
    if (_routeTask == null ||
        _routeParameters == null ||
        _routeOverlay == null ||
        _markerOverlay.graphics.length < 2) {
      _routeOverlay?.graphics.clear();
      return;
    }

    // Create a list of stops from the location markers.
    final stops = _markerOverlay.graphics
        .map((g) => Stop(g.geometry! as ArcGISPoint))
        .toList();
    _routeParameters!.clearStops();
    _routeParameters!.setStops(stops);

    try {
      // Solve the route.
      final result = await _routeTask!.solveRoute(_routeParameters!);
      if (result.routes.isNotEmpty) {
        // If a route was found, display it on the map using the _routeOverlay.
        final routeGeometry = result.routes.first.routeGeometry;
        _routeOverlay!.graphics.clear();
        _routeOverlay!.graphics.add(Graphic(geometry: routeGeometry));
      }
    } on ArcGISException catch (e) {
      // If an error occurs, clear the route overlay and display the error.
      _routeOverlay!.graphics.clear();

      showMessageDialog(e.message, title: 'Error');
    }
  }

  Future<void> deleteMarker() async {
    // Remove the selected graphic from the location marker overlay.
    _markerOverlay.graphics.remove(_selectedGraphic);
    setState(() {
      _selectedGraphic = null;
      _message = '';
    });

    // Update the route to account for the deleted marker.
    await updateRoute();
  }

  void reset() {
    // Clear all location markers and the route overlay.
    _markerOverlay.graphics.clear();
    _routeOverlay?.graphics.clear();
    setState(() {
      _selectedGraphic = null;
      _message = '';
    });
  }
}
