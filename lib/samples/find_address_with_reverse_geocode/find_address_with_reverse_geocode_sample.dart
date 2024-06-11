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
  final GlobalKey<ScaffoldState> _scaffoldStateKey = GlobalKey();
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
      key: _scaffoldStateKey,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    final image = await ArcGISImage.fromAsset('assets/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image);
    pictureMarkerSymbol.width = 35;
    pictureMarkerSymbol.height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;

    _graphicsOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    _mapViewController.arcGISMap = map;
    _mapViewController.setViewpoint(_initialViewpoint);

    await _worldLocatorTask.load();

    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    if (_graphicsOverlay.graphics.isNotEmpty) _graphicsOverlay.graphics.clear();

    final mapTapPoint =
        _mapViewController.screenToLocation(screen: localPosition);
    if (mapTapPoint == null) return;

    final normalizedTapPoint =
        GeometryEngine.normalizeCentralMeridian(geometry: mapTapPoint);
    displayTappedPoint(normalizedTapPoint!);

    final reverseGeocodeParameters = ReverseGeocodeParameters();
    reverseGeocodeParameters.maxResults = 1;
    final reverseGeocodeResult = await _locatorTask.reverseGeocode(
      location: normalizedTapPoint as ArcGISPoint,
      parameters: reverseGeocodeParameters,
    );
    if (reverseGeocodeResult.isEmpty) return;

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

  void displayTappedPoint(Geometry mapPoint) {
    final pointGraphic = Graphic(
      geometry: mapPoint,
    );
    _graphicsOverlay.graphics.add(pointGraphic);
  }
}
