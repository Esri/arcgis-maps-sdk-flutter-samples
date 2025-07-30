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

import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class DisplayOGCAPICollection extends StatefulWidget {
  const DisplayOGCAPICollection({super.key});

  @override
  State<DisplayOGCAPICollection> createState() =>
      _DisplayOGCAPICollectionState();
}

class _DisplayOGCAPICollectionState extends State<DisplayOGCAPICollection>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
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
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a basemap style and add to the map view controller.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Create an OGC feature collection table by passing in a service URL and a collection id.
    const serviceUri = 'https://demo.ldproxy.net/daraa';
    const collectionId = 'TransportationGroundCrv';
    final ogcFeatureCollectionTable =
        OgcFeatureCollectionTable.withUriAndCollectionId(
          uri: Uri.parse(serviceUri),
          collectionId: collectionId,
        );
    // Set the feature request mode to manual cache.
    // In this mode, you must manually populate the table - panning and zooming won't request features automatically.
    ogcFeatureCollectionTable.featureRequestMode =
        FeatureRequestMode.manualCache;
    // Load the table.
    await ogcFeatureCollectionTable.load();

    // Create a feature layer to visualize the OGC features.
    final featureLayer = FeatureLayer.withFeatureTable(
      ogcFeatureCollectionTable,
    );
    // Apply a renderer.
    featureLayer.renderer = SimpleRenderer(
      symbol: SimpleLineSymbol(color: Colors.blue, width: 3),
    );
    // Add the feature layer to the map's operational layers.
    map.operationalLayers.add(featureLayer);

    // Re-populate the table when navigation completes e.g. after zooming or panning to a new area.
    _mapViewController.onNavigationChanged.listen((isNavigating) async {
      if (!isNavigating) {
        // Set the ready state variable to false to prevent interaction while the features re-populate.
        setState(() => _ready = false);
        if (_mapViewController.visibleArea != null) {
          // Create a query based on the current visible extent.
          // Set a limit of 5000 on the number of returned features per request,
          // because the default on some services could be as low as 10.
          final queryParameters = QueryParameters()
            ..geometry = _mapViewController.visibleArea!.extent
            ..spatialRelationship = SpatialRelationship.intersects
            ..maxFeatures = 5000;
          // Populate the table with the query, leaving existing table entries intact.
          // Setting outFields to empty requests all fields.
          await ogcFeatureCollectionTable.populateFromService(
            clearCache: false,
            outFields: [],
            parameters: queryParameters,
          );
        }
        // Set the ready state variable to true to enable the sample UI.
        setState(() => _ready = true);
      }
    });

    // Zoom to a small area within the dataset by default.
    final datasetExtent = ogcFeatureCollectionTable.extent;
    if (datasetExtent != null) {
      unawaited(
        _mapViewController.setViewpointAnimated(
          Viewpoint.fromTargetExtent(
            Envelope.fromCenter(
              datasetExtent.center,
              width: datasetExtent.width / 3,
              height: datasetExtent.height / 3,
            ),
          ),
        ),
      );
    }
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
