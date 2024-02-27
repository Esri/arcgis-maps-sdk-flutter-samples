//
// COPYRIGHT © 2024 Esri
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

    setState(() => _isInitialized = true);
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

    setState(() => _isRouteSolved = true);
  }

  void resetRoutes() {
    _routeGraphicsOverlay.graphics.clear();
    setState(() => _isRouteSolved = false);
  }
}
