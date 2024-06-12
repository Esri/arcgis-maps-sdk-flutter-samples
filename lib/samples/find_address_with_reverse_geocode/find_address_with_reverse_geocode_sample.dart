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
  late LocatorTask _locatorTask;
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

  _FindAddressWithReverseGeocodeSampleState() {
    _locatorTask = _worldLocatorTask;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // add a map view.
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
    // create an instance of a map with ESRI topographic basemap.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // zoom to a specific extent.
    _mapViewController.setViewpoint(_initialViewpoint);

    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image)
      ..width = 35
      ..height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;

    // add the graphics overlay.
    _graphicsOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

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

    // normalize point.
    final normalizedTapPoint =
        GeometryEngine.normalizeCentralMeridian(geometry: mapTapPoint);
    if (normalizedTapPoint == null) return;

    // create a graphic object for the specified point.
    _graphicsOverlay.graphics.add(Graphic(geometry: normalizedTapPoint));

    // initialize parameters.
    final reverseGeocodeParameters = ReverseGeocodeParameters()..maxResults = 1;

    // reverse geocode.
    final reverseGeocodeResult = await _locatorTask.reverseGeocode(
      location: normalizedTapPoint as ArcGISPoint,
      parameters: reverseGeocodeParameters,
    );
    if (reverseGeocodeResult.isEmpty) return;

    // get and show the address.
    final firstResult = reverseGeocodeResult.first;
    final address = firstResult.attributes['LongLabel'] as String;
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text(address));
        },
      );
    }
  }
}
