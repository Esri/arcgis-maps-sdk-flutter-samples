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

import '../../utils/sample_state_support.dart';

class FindClosestFacilityFromPoint extends StatefulWidget {
  const FindClosestFacilityFromPoint({super.key});

  @override
  State<FindClosestFacilityFromPoint> createState() =>
      _FindClosestFacilityFromPointState();
}

class _FindClosestFacilityFromPointState
    extends State<FindClosestFacilityFromPoint> with SampleStateSupport {
  // Create the URIs for the fire station and fire images, as well as the URIs for the facilities and incidents layers.
  static final _fireStationImageUri = Uri.parse(
      'https://static.arcgis.com/images/Symbols/SafetyHealth/FireStation.png');
  static final _fireImageUri = Uri.parse(
      'https://static.arcgis.com/images/Symbols/SafetyHealth/esriCrimeMarker_56_Gradient.png');
  static final _facilitiesLayerUri = Uri.parse(
      'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Facilities/FeatureServer/0');
  static final _incidentsLayerUri = Uri.parse(
      'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Incidents/FeatureServer/0');
  // Create a task for the closest facility service.
  final _closestFacilityTask = ClosestFacilityTask.withUrl(Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ClosestFacility'));
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a graphics overlay for the route.
  final _routeGraphicsOverlay = GraphicsOverlay();
  // Create a flag to track whether the route has been solved.
  var _routeSolved = false;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // Create parameters for the closest facility task.
  late final ClosestFacilityParameters _closestFacilityParameters;
  // Create a symbol for the route line.
  final _routeLineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid, color: Colors.blue, width: 5.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Create buttons to solve the routes and reset the graphics.
                    ElevatedButton(
                      onPressed: !_routeSolved ? solveRoutes : null,
                      child: const Text('Solve Routes'),
                    ),
                    ElevatedButton(
                      onPressed: _routeSolved ? resetRoutes : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
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
    // Create a map with the ArcGIS Streets basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);

    // Create feature table for the facilities layer.
    final facilitiesFeatureTable =
        ServiceFeatureTable.withUri(_facilitiesLayerUri);
    // Create a marker symbol for the facilities.
    final facilitiesMarkerSymbol =
        PictureMarkerSymbol.withUrl(_fireStationImageUri)
          ..width = 30
          ..height = 30;
    // Create a feature layer for the facilities.
    final facilitiesLayer =
        FeatureLayer.withFeatureTable(facilitiesFeatureTable)
          ..renderer = SimpleRenderer(symbol: facilitiesMarkerSymbol);

    // Create feature table for the incidents layer.
    final incidentsFeatureTable =
        ServiceFeatureTable.withUri(_incidentsLayerUri);
    // Create a marker symbol for the incidents.
    final incidentsMarkerSymbol = PictureMarkerSymbol.withUrl(_fireImageUri)
      ..width = 30
      ..height = 30;
    // Create a feature layer for the incidents.
    final incidentsLayer = FeatureLayer.withFeatureTable(incidentsFeatureTable)
      ..renderer = SimpleRenderer(symbol: incidentsMarkerSymbol);

    // Add the layers to the map.
    map.operationalLayers.addAll([facilitiesLayer, incidentsLayer]);

    // Set the map on the map view controller.
    _mapViewController.arcGISMap = map;

    // Add the route graphics overlay to the map view controller.
    _routeGraphicsOverlay.opacity = 0.75;
    _mapViewController.graphicsOverlays.add(_routeGraphicsOverlay);

    // Load the layers
    await Future.wait([
      facilitiesLayer.load(),
      incidentsLayer.load(),
    ]);

    // Get the extent from the layers and use the combination as the viewpoint geometry.
    final mapExtent = GeometryEngine.combineExtents(
      geometry1: facilitiesLayer.fullExtent!,
      geometry2: incidentsLayer.fullExtent!,
    );

    // Set the viewpoint geometry on the map view controller.
    _mapViewController.setViewpointGeometry(mapExtent, paddingInDiPs: 30);

    // Generate the closest facility parameters.
    _closestFacilityParameters = await generateClosestFacilityParameters(
        facilitiesFeatureTable, incidentsFeatureTable);

    // Set the initialized flag to true.
    setState(() => _ready = true);
  }

  FeatureLayer buildFeatureLayer(Uri tableUri, Uri imageUri) {
    // Create a feature table and feature layer for the facilities or incidents.
    final featureTable = ServiceFeatureTable.withUri(tableUri);
    final markerSymbol = PictureMarkerSymbol.withUrl(imageUri)
      ..width = 30
      ..height = 30;
    final featureLayer = FeatureLayer.withFeatureTable(featureTable)
      ..renderer = SimpleRenderer(symbol: markerSymbol);

    return featureLayer;
  }

  Future<ClosestFacilityParameters> generateClosestFacilityParameters(
      FeatureTable facilitiesFeatureTable,
      FeatureTable incidentsFeatureTable) async {
    // Create query parameters to get all features.
    final featureQueryParams = QueryParameters()..whereClause = '1=1';
    // Create default parameters for the closest facility task.
    final parameters = await _closestFacilityTask.createDefaultParameters()
      ..setFacilitiesWithFeatureTable(
        featureTable: facilitiesFeatureTable as ArcGISFeatureTable,
        queryParameters: featureQueryParams,
      )
      ..setIncidentsWithFeatureTable(
        featureTable: incidentsFeatureTable as ArcGISFeatureTable,
        queryParameters: featureQueryParams,
      );

    return parameters;
  }

  void solveRoutes() async {
    setState(() => _ready = false);
    // Solve the closest facility task with the parameters.
    final result = await _closestFacilityTask.solveClosestFacility(
        closestFacilityParameters: _closestFacilityParameters);
    for (var incidentIdx = 0;
        incidentIdx < result.incidents.length;
        ++incidentIdx) {
      final rankedFacilities =
          result.getRankedFacilityIndexes(incidentIndex: incidentIdx);
      if (rankedFacilities.isEmpty) {
        continue;
      }

      // Get the route to the closest facility.
      final closestFacilityIdx = rankedFacilities.first;
      final routeToFacility = result.getRoute(
        facilityIndex: closestFacilityIdx,
        incidentIndex: incidentIdx,
      );
      // Add the route to the graphics overlay.
      if (routeToFacility != null) {
        final routeGraphic = Graphic(
            geometry: routeToFacility.routeGeometry, symbol: _routeLineSymbol);
        _routeGraphicsOverlay.graphics.add(routeGraphic);
      }
    }

    // Set the route solved flag to true.
    setState(() {
      _ready = true;
      _routeSolved = true;
    });
  }

  void resetRoutes() {
    // Clear the graphics overlay and set the route solved flag to false.
    _routeGraphicsOverlay.graphics.clear();
    setState(() => _routeSolved = false);
  }
}
