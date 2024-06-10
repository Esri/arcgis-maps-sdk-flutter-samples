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

class ServiceAreaSample extends StatefulWidget {
  const ServiceAreaSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ServiceAreaSampleState createState() => ServiceAreaSampleState();
}

class ServiceAreaSampleState extends State<ServiceAreaSample> {
  final _serviceAreaTask = ServiceAreaTask.withUrl(Uri.parse(
      'https://route-api.arcgis.com/arcgis/rest/services/World/ServiceAreas/NAServer/ServiceArea_World'));

  final _mapViewController = ArcGISMapView.createController();
  final _facilityPointGraphicsOverlay = GraphicsOverlay();
  final _serviceAreaGraphicsOverlay = GraphicsOverlay();
  bool _isInitialized = false;
  late final ServiceAreaParameters _serviceAreaParameters;

  final _facilityPointSymbol = SimpleMarkerSymbol(
    color: Colors.white,
    style: SimpleMarkerSymbolStyle.circle,
    size: 10,
  )..outline = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid,
      color: Colors.black,
      width: 2,
    );

  final _serviceAreaSymbol = SimpleFillSymbol(
    style: SimpleFillSymbolStyle.solid,
    color: const Color(0x40FF3232),
    outline: SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid,
      color: Colors.black,
      width: 1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
                onTap: _isInitialized ? onTap : null,
              ),
            ),
            const SizedBox(
              height: 60,
              child: Center(
                child: Text('Tap the map to calculate a Service Area'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    _mapViewController.arcGISMap = map;

    _mapViewController.graphicsOverlays.addAll([
      _serviceAreaGraphicsOverlay,
      _facilityPointGraphicsOverlay,
    ]);

    final centerPt = ArcGISPoint(
      x: -10040452.2301059,
      y: 4668882.823885492,
      spatialReference: SpatialReference(wkid: 102100),
    );
    _mapViewController.setViewpointCenter(
      centerPt,
      scale: 376373,
    );

    _serviceAreaParameters = await _serviceAreaTask.createDefaultParameters();

    setState(() => _isInitialized = true);
  }

  Future<void> onTap(Offset screenPoint) async {
    // Screen to map point
    final mapTapPoint =
        _mapViewController.screenToLocation(screen: screenPoint);
    if (mapTapPoint == null) return;

    resetServiceArea();

    displayFacility(mapTapPoint);

    // Calculate service area
    final facility = ServiceAreaFacility(point: mapTapPoint);
    final serviceAreaResult = await solveServiceArea([facility]);
    displayServiceArea(serviceAreaResult);
  }

  void displayFacility(ArcGISPoint mapPoint) {
    // Put the point graphic on the map
    final facilityGraphic = Graphic(
      geometry: mapPoint,
      symbol: _facilityPointSymbol,
    );
    _facilityPointGraphicsOverlay.graphics.add(facilityGraphic);
  }

  Future<ServiceAreaResult> solveServiceArea(
      List<ServiceAreaFacility> facilities) {
    _serviceAreaParameters.setFacilities(facilities);

    return _serviceAreaTask.solveServiceArea(
      serviceAreaParameters: _serviceAreaParameters,
    );
  }

  void displayServiceArea(ServiceAreaResult result) {
    // Get the polygons for the facility. In this sample, there will only be one.
    final serviceAreaPolygons = result.getResultPolygons(facilityIndex: 0);

    final serviceAreaGraphics = serviceAreaPolygons.map((serviceAreaPolygon) {
      return Graphic(
        geometry: serviceAreaPolygon.geometry,
        attributes: {
          'fromImpedanceCutoff': serviceAreaPolygon.fromImpedanceCutoff,
          'toImpedanceCutoff': serviceAreaPolygon.toImpedanceCutoff,
        },
        symbol: _serviceAreaSymbol,
      );
    });

    _serviceAreaGraphicsOverlay.graphics.addAll(serviceAreaGraphics);
  }

  void resetServiceArea() {
    _facilityPointGraphicsOverlay.graphics.clear();
    _serviceAreaGraphicsOverlay.graphics.clear();
    _serviceAreaParameters.clearFacilities();
  }
}
