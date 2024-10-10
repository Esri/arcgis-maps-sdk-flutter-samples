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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class ShowWfsLayerFromUrl extends StatefulWidget {
  const ShowWfsLayerFromUrl({super.key});

  @override
  State<ShowWfsLayerFromUrl> createState() => _ShowWfsLayerFromUrlState();
}

class _ShowWfsLayerFromUrlState extends State<ShowWfsLayerFromUrl>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Reference to the WFS feature table.
  late WfsFeatureTable _featureTable;

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
                    onTap: onTap,
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: const SizedBox.expand(
                child: ColoredBox(
                  color: Colors.white30,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with the ArcGIS Navigation basemap style and set to the map view.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);

    _mapViewController.arcGISMap = map;

    // Load the WFS layer.
    await loadWfsLayerFromURL();

    // Set the initial viewpoint to Seattle Downtown using latitude, longitude and scale.
    final initialViewPoint = Viewpoint.withLatLongScale(
      latitude: 47.617207,
      longitude: -122.341581,
      scale: 5000,
    );

    _mapViewController.setViewpoint(initialViewPoint);

    // Add a listener for map navigation events
    _mapViewController.onNavigationChanged.listen((isNavigating) {
      if (!isNavigating) {
        onNavigationChanged();
      }
    });
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    print('Tapped at $offset');
  }

  Future<void> loadWfsLayerFromURL() async {
    const wfsFeatureTableUri =
        'https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer?service=wfs&request=getcapabilities';

    // Create a WFS feature table from URI and name.
    _featureTable = WfsFeatureTable.withUriAndTableName(
        uri: Uri.parse(wfsFeatureTableUri),
        tableName: 'Seattle_Downtown_Features:Buildings')

      // Set the axis order and feature request mode.
      ..axisOrder = OgcAxisOrder.noSwap
      ..featureRequestMode = FeatureRequestMode.manualCache;

    // Create the feature layer from the feature table.
    final featureLayer = FeatureLayer.withFeatureTable(_featureTable)

      // Apply a renderer.
      ..renderer = SimpleRenderer(
        symbol: SimpleLineSymbol(
          color: Colors.red,
          width: 3,
        ),
      );
    await featureLayer.load();

    // Add the feature layer to the map
    _mapViewController.arcGISMap?.operationalLayers.add(featureLayer);
  }

  void onNavigationChanged() async {
    // Show the loading indicator.
    setState(() => _ready = false);

    // Get the current extent.
    final currentExtent = _mapViewController.visibleArea;

    // Create a query based on the current visible extent.
    final visibleExtentQuery = QueryParameters()
      ..geometry = currentExtent
      ..spatialRelationship = SpatialRelationship.intersects;

    try {
      // Populate teh table with the query, leaving existing table entries intact
      await _featureTable.populateFromService(
        parameters: visibleExtentQuery,
        clearCache: false,
        outFields: [],
      );
    } catch (exception) {
      print('Error populating table: $exception');
    } finally {
      // Hide the loading indicator
      setState(() => _ready = true);
    }
  }
}
