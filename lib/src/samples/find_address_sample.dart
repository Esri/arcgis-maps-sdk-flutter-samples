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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class FindAddressSample extends StatefulWidget {
  const FindAddressSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  FindAddressSampleState createState() => FindAddressSampleState();
}

class FindAddressSampleState extends State<FindAddressSample> {
  final GlobalKey<ScaffoldState> _scaffoldStateKey = GlobalKey();
  final _graphicsOverlay = GraphicsOverlay();
  final _graphic = Graphic();
  final _worldLocatorTask = LocatorTask.withUri(Uri.parse(
      'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer'));
  final _sanDiegoLocatorTask = LocatorTask.withUri(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Locators/SanDiego/GeocodeServer'));
  late LocatorTask _locatorTask;
  final _geocodeParameters = GeocodeParameters();
  final _mapViewController = ArcGISMapView.createController();
  bool _ready = false;

  FindAddressSampleState() {
    _locatorTask = _worldLocatorTask;
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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: buildServiceControls(context),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
            onTap: onTap,
          ),
          Visibility(
            visible: _ready,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(10),
                child: buildSearchControls(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildServiceControls(BuildContext context) {
    return Column(children: [
      const Text('Geocode Service'),
      RadioListTile<LocatorTask>(
        title: const Text('World'),
        value: _worldLocatorTask,
        groupValue: _locatorTask,
        onChanged: onServiceChanged,
      ),
      RadioListTile<LocatorTask>(
        title: const Text('San Diego'),
        value: _sanDiegoLocatorTask,
        groupValue: _locatorTask,
        onChanged: onServiceChanged,
      ),
    ]);
  }

  Widget buildSearchControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
              ),
              onSubmitted: onSearchSubmitted,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.list,
            color: Colors.white,
          ),
          onPressed: () => _scaffoldStateKey.currentState!.openEndDrawer(),
        ),
      ],
    );
  }

  void onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);

    final image =
        await ArcGISImage.fromAsset('assets/samples/pin_circle_red.png');
    final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image);
    pictureMarkerSymbol.width = 35;
    pictureMarkerSymbol.height = 35;
    pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
    _graphicsOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
    _graphicsOverlay.graphics.add(_graphic);
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    _mapViewController.arcGISMap = map;

    _geocodeParameters.minScore = 75;
    _geocodeParameters.resultAttributeNames
        .addAll(['Place_addr', 'Match_addr']);

    await Future.wait([
      _worldLocatorTask.load(),
      _sanDiegoLocatorTask.load(),
    ]);

    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    final identifyGraphicsOverlayResult =
        await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 5,
    );

    if (identifyGraphicsOverlayResult.graphics.isEmpty) return;

    if (mounted) {
      final graphic = identifyGraphicsOverlayResult.graphics.first;
      final center = graphic.geometry!.extent.center;
      final x = center.x.toStringAsFixed(3);
      final y = center.y.toStringAsFixed(3);
      final matchAddr = graphic.attributes['Match_addr'];
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text('$matchAddr\n($x, $y)'));
        },
      );
    }
  }

  void onServiceChanged(LocatorTask? locatorTask) {
    if (locatorTask == null) return;

    setState(() => _locatorTask = locatorTask);
    Future.delayed(
      const Duration(milliseconds: 250),
      () => _scaffoldStateKey.currentState!.closeEndDrawer(),
    );
  }

  void onSearchSubmitted(String searchText) async {
    final geocodeResults = await _locatorTask.geocode(
      searchText: searchText,
      parameters: _geocodeParameters,
    );

    if (geocodeResults.isEmpty) return;

    final geocodeResult = geocodeResults.first;
    if (geocodeResult.displayLocation != null) {
      _graphic.geometry = geocodeResult.displayLocation!;
    }
    _graphic.attributes.addEntries(geocodeResult.attributes.entries);
    if (geocodeResult.extent != null) {
      _mapViewController.setViewpointAnimated(
        Viewpoint.fromTargetExtent(geocodeResult.extent!),
      );
    }
  }
}
