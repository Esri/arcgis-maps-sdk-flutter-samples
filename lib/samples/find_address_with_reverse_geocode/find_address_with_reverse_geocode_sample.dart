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

class FindAddressWithReverseGeocodeSample extends StatefulWidget {
  const FindAddressWithReverseGeocodeSample({super.key});

  @override
  State<FindAddressWithReverseGeocodeSample> createState() =>
      _FindAddressWithReverseGeocodeSampleState();
}

class _FindAddressWithReverseGeocodeSampleState
    extends State<FindAddressWithReverseGeocodeSample> {
  final _graphicsOverlay = GraphicsOverlay();
  final _worldLocatorTask = LocatorTask.withUri(Uri.parse(
      'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer'));
  final _mapViewController = ArcGISMapView.createController();
  final _initialViewpoint = Viewpoint.fromCenter(
    ArcGISPoint(
      x: -117.195,
      y: 34.058,
      spatialReference: SpatialReference.wgs84,
    ),
    scale: 5e4,
  );
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // add a map view to the widget tree and set a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: _ready ? onTap : null,
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    // create a map with the topographic basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // zoom to a specific extent.
    _mapViewController.setViewpoint(_initialViewpoint);

    // create a picture marker symbol using an image asset.
    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image)
      ..width = 35
      ..height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;

    // create a renderer using the picture marker symbol and set to the graphics overlay.
    _graphicsOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    // add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // load the locator task and once loaded set the _ready flag to true to enable the UI.
    await _worldLocatorTask.load();
    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    // remove already existing graphics.
    if (_graphicsOverlay.graphics.isNotEmpty) _graphicsOverlay.graphics.clear();

    // convert the screen point to a map point.
    final mapTapPoint =
        _mapViewController.screenToLocation(screen: localPosition);
    if (mapTapPoint == null) return;

    // normalize the point incase the tapped location crosses the international date line.
    final normalizedTapPoint =
        GeometryEngine.normalizeCentralMeridian(geometry: mapTapPoint);
    if (normalizedTapPoint == null) return;

    // create a graphic object for the tapped point.
    _graphicsOverlay.graphics.add(Graphic(geometry: normalizedTapPoint));

    // initialize parameters.
    final reverseGeocodeParameters = ReverseGeocodeParameters()..maxResults = 1;

    // perform a reverse geocode using the tapped location and parameters.
    final reverseGeocodeResult = await _worldLocatorTask.reverseGeocode(
      location: normalizedTapPoint as ArcGISPoint,
      parameters: reverseGeocodeParameters,
    );
    if (reverseGeocodeResult.isEmpty) return;

    // get attributes from the first result and display a formatted address in a dialog.
    final firstResult = reverseGeocodeResult.first;
    final cityString = firstResult.attributes['City'] ?? '';
    final addressString = firstResult.attributes['Address'] ?? '';
    final stateString = firstResult.attributes['RegionAbbr'] ?? '';
    final resultStrings = [addressString, cityString, stateString];
    final combinedString =
        resultStrings.where((str) => str.isNotEmpty).join(', ');

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text(combinedString));
        },
      );
    }
  }
}
