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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class FindClosestFacilitySample extends StatefulWidget {
  const FindClosestFacilitySample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  FindClosestFacilitySampleState createState() =>
      FindClosestFacilitySampleState();
}

class FindClosestFacilitySampleState extends State<FindClosestFacilitySample> {
  static final _fireStationImageUri = Uri.parse(
      'https://static.arcgis.com/images/Symbols/SafetyHealth/FireStation.png');
  static final _fireImageUri = Uri.parse(
      'https://static.arcgis.com/images/Symbols/SafetyHealth/esriCrimeMarker_56_Gradient.png');
  static final _facilitiesLayerUri = Uri.parse(
      'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Facilities/FeatureServer/0');
  static final _incidentsLayerUri = Uri.parse(
      'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Incidents/FeatureServer/0');
  final _closestFacilityTask = ClosestFacilityTask.withUrl(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ClosestFacility'));

  final _mapViewController = ArcGISMapView.createController();
  final _routeGraphicsOverlay = GraphicsOverlay();
  bool _isRouteSolved = false;
  bool _isInitialized = false;
  late final ClosestFacilityParameters _closestFacilityParameters;
  final _routeLineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid, color: Colors.blue, width: 5.0);

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
              ),
            ),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: !_isRouteSolved && _isInitialized
                        ? () => solveRoutes()
                        : null,
                    child: const Text('Solve Routes'),
                  ),
                  ElevatedButton(
                    onPressed: _isRouteSolved ? () => resetRoutes() : null,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);

    final facilitiesLayer =
        buildFeatureLayer(_facilitiesLayerUri, _fireStationImageUri);
    final incidentsLayer = buildFeatureLayer(_incidentsLayerUri, _fireImageUri);
    map.operationalLayers.addAll([facilitiesLayer, incidentsLayer]);

    _mapViewController.arcGISMap = map;

    _routeGraphicsOverlay.opacity = 0.75;
    _mapViewController.graphicsOverlays.add(_routeGraphicsOverlay);

    // Load the layers
    await Future.wait([
      facilitiesLayer.load(),
      incidentsLayer.load(),
    ]);

    // Get the extent from the layers and use the combination as the viewpoint geometry
    final mapExtent = GeometryEngine.combineExtents(
      geometry1: facilitiesLayer.fullExtent!,
      geometry2: incidentsLayer.fullExtent!,
    );

    _mapViewController.setViewpointGeometry(mapExtent, paddingInDiPs: 30);

    _closestFacilityParameters = await generateClosestFacilityParameters(
        facilitiesLayer, incidentsLayer);

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  FeatureLayer buildFeatureLayer(Uri tableUri, Uri imageUri) {
    final featureTable = ServiceFeatureTable.fromUri(tableUri);
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    final markerSymbol = PictureMarkerSymbol.withUrl(imageUri);
    markerSymbol.width = 30;
    markerSymbol.height = 30;
    featureLayer.renderer = SimpleRenderer(symbol: markerSymbol);

    return featureLayer;
  }

  Future<ClosestFacilityParameters> generateClosestFacilityParameters(
      FeatureLayer facilitiesLayer, FeatureLayer incidentsLayer) async {
    final featureQueryParams = QueryParameters()..whereClause = '1=1';

    final parameters = await _closestFacilityTask.createDefaultParameters();
    parameters.setFacilitiesWithFeatureTable(
      featureTable: facilitiesLayer.featureTable! as ArcGISFeatureTable,
      queryParameters: featureQueryParams,
    );
    parameters.setIncidentsWithFeatureTable(
      featureTable: incidentsLayer.featureTable! as ArcGISFeatureTable,
      queryParameters: featureQueryParams,
    );

    return parameters;
  }

  Future<void> solveRoutes() async {
    final results = await _closestFacilityTask.solveClosestFacility(
      closestFacilityParameters: _closestFacilityParameters,
    );

    for (var incidentIdx = 0;
        incidentIdx < results.incidents.length;
        ++incidentIdx) {
      final rankedFacilities =
          results.getRankedFacilityIndexes(incidentIndex: incidentIdx);
      if (rankedFacilities.isEmpty) {
        continue;
      }

      final closestFacilityIdx = rankedFacilities.first;
      final routeToFacility = results.getRoute(
        facilityIndex: closestFacilityIdx,
        incidentIndex: incidentIdx,
      );
      if (routeToFacility != null) {
        final routeGraphic = Graphic(
          geometry: routeToFacility.routeGeometry,
          symbol: _routeLineSymbol,
        );
        _routeGraphicsOverlay.graphics.add(routeGraphic);
      }
    }
    if (mounted) {
      setState(() => _isRouteSolved = true);
    }
  }

  void resetRoutes() {
    _routeGraphicsOverlay.graphics.clear();
    setState(() => _isRouteSolved = false);
  }
}
