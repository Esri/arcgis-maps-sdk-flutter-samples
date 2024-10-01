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
import 'package:flutter/services.dart';

void main() async {
  // Supply your apiKey using the --dart-define-from-file command line argument
  ArcGISEnvironment.apiKey = const String.fromEnvironment('API_KEY');

  runApp(
    const MaterialApp(
      home: ShowWfsLayerWithXmlQuery(),
    ),
  );
}

class ShowWfsLayerWithXmlQuery extends StatefulWidget {
  const ShowWfsLayerWithXmlQuery({super.key});

  @override
  State<ShowWfsLayerWithXmlQuery> createState() =>
      _ShowWfsLayerWithXmlQueryState();
}

class _ShowWfsLayerWithXmlQueryState extends State<ShowWfsLayerWithXmlQuery> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: AddWfsLayerWithQueriedFeatures,
                      child:
                          const Text('Add a WFS layer with queried features'),
                    ),
                  ],
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
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void AddWfsLayerWithQueriedFeatures() async {
    setState(() => _ready = false);
    // Clear the operational layers
    _mapViewController.arcGISMap?.operationalLayers.clear();

    const wfsFeatureTableUri =
        'https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer?service=wfs&amp;request=getcapabilities';

    // create the WFS feature table from URL and name
    final statesTable = WfsFeatureTable.withUriAndTableName(
      uri: Uri.parse(wfsFeatureTableUri),
      tableName: 'Seattle_Downtown_Features:Trees',
    )
      // set the feature request mode and axis order
      ..axisOrder = OgcAxisOrder.noSwap
      ..featureRequestMode = FeatureRequestMode.manualCache;

    // create the feature layer from the feature table
    final featureLayer = FeatureLayer.withFeatureTable(statesTable);
    await featureLayer.load();

    // add the feature layer to the map
    _mapViewController.arcGISMap?.operationalLayers.add(featureLayer);

    // load the query string from the assets folder
    final xmlQuery = await rootBundle.loadString('assets/wfs_query.xml');

    // populate the features with the query string
    await statesTable.populateFromServiceWithXml(
      xmlRequest: xmlQuery,
      clearCache: true,
    );

    // Zoom to the full extent of the feature layer
    _mapViewController.setViewpointGeometry(featureLayer.fullExtent!);

    setState(() => _ready = true);
  }
}
