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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/sample_data.dart';

class AddFeatureLayersSample extends StatefulWidget {
  const AddFeatureLayersSample({super.key});

  @override
  State<AddFeatureLayersSample> createState() => _AddFeatureLayersSampleState();
}

class _AddFeatureLayersSampleState extends State<AddFeatureLayersSample> {
  // create a map with a topographic basemap style.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
  // create a map view conroller.
  final _mapViewController = ArcGISMapView.createController();
  // create a list of feature layer sources.
  final _featureLayerSources =
      List<DropdownMenuItem<String>>.empty(growable: true);
  // create a variable to store the selected feature layer source.
  String? _selectedFeatureLayerSource;

  @override
  void initState() {
    super.initState();
    // add feature layer sources to the list.
    _featureLayerSources.addAll([
      // add a dropdown menu item to load a feature service from a uri.
      DropdownMenuItem(
        onTap: loadFeatureServiceFromUri,
        value: 'URL',
        child: const Text('URL'),
      ),
      // add a dropdown menu item to load a feature service from a portal item.
      DropdownMenuItem(
        onTap: loadPortalItem,
        value: 'PortalItem',
        child: const Text('Portal Item'),
      ),
      // add a dropdown menu item to load a feature service from a geodatabase.
      DropdownMenuItem(
        onTap: loadGeodatabase,
        value: 'Geodatabase',
        child: const Text('Geodatabase'),
      ),
      // add a dropdown menu item to load a feature service from a geopackage.
      DropdownMenuItem(
        onTap: loadGeopackage,
        value: 'Geopackage',
        child: const Text('Geopackage'),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        // create a column with a map view and a dropdown button.
        child: Column(
          children: [
            // add a map view to the widget tree and set a controller.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: _onMapViewReady,
              ),
            ),
            // create a dropdown button to select a feature layer source.
            DropdownButton<String>(
              alignment: Alignment.center,
              hint: const Text(
                'Select a feature layer source',
                style: TextStyle(
                  color: Colors.deepPurple,
                ),
              ),
              // set the selected feature layer source.
              value: _selectedFeatureLayerSource,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.deepPurple,
              ),
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
              // set the onChanged callback to update the selected feature layer source.
              onChanged: (String? featureLayerSource) {
                setState(() {
                  _selectedFeatureLayerSource = featureLayerSource!;
                });
              },
              items: _featureLayerSources,
            ),
          ],
        ),
      ),
    );
  }

  void _onMapViewReady() async {
    // set the map on the map view controller.
    _mapViewController.arcGISMap = _map;
  }

  void loadFeatureServiceFromUri() {
    // create a uri to a feature service.
    final uri = Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0');
    // create a service feature table with the uri.
    final serviceFeatureTable = ServiceFeatureTable.withUri(uri);
    // create a feature layer with the service feature table.
    final serviceFeatureLayer =
        FeatureLayer.withFeatureTable(serviceFeatureTable);
    // clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(serviceFeatureLayer);
    // set the viewpoint to the feature layer.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 41.773519,
        longitude: -88.153104,
        scale: 6000,
      ),
    );
  }

  void loadGeodatabase() async {
    // download the sample data.
    await downloadSampleData(['cb1b20748a9f4d128dad8a87244e3e37']);
    // get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // create a file to the geodatabase.
    final geodatabaseFile =
        File('${appDir.absolute.path}/LA_Trails/LA_Trails.geodatabase');
    // create a geodatabase with the file uri.
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    // load the geodatabase.
    await geodatabase.load();
    // get the feature table with the table name.
    final geodatabaseFeatureTable =
        geodatabase.getGeodatabaseFeatureTable(tableName: 'Trailheads');
    // check if the feature table is not null.
    if (geodatabaseFeatureTable != null) {
      // create a feature layer with the feature table.
      final geodatabaseFeatureLayer =
          FeatureLayer.withFeatureTable(geodatabaseFeatureTable);
      // clear the operational layers and add the feature layer to the map.
      _map.operationalLayers.clear();
      _map.operationalLayers.add(geodatabaseFeatureLayer);
      // set the viewpoint to the feature layer.
      _mapViewController.setViewpoint(
        Viewpoint.fromCenter(
          ArcGISPoint(
            x: -13214155,
            y: 4040194,
            spatialReference: SpatialReference.webMercator,
          ),
          scale: 125000,
        ),
      );
    }
  }

  void loadPortalItem() async {
    // Set the portal.
    final portal = Portal.arcGISOnline();
    // Create the portal item with the item ID for the Portland tree service data.
    const itemId = '1759fd3e8a324358a0c58d9a687a8578';
    final portalItem =
        PortalItem.withPortalAndItemId(portal: portal, itemId: itemId);
    // load the portal item.
    await portalItem.load();
    // create a feature layer with the portal item and layer ID
    final portalItemFeatureLayer = FeatureLayer.withItem(
      featureServiceItem: portalItem,
      layerId: 0,
    );
    // clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(portalItemFeatureLayer);
    // Set the viewpoint to Portland, Oregon.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 45.5266,
        longitude: -122.6219,
        scale: 6000,
      ),
    );
  }

  void loadGeopackage() async {
    // download the sample data.
    await downloadSampleData(['68ec42517cdd439e81b036210483e8e7']);
    // get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // create a file to the geopackage.
    final geopackageFile =
        File('${appDir.absolute.path}/AuroraCO/AuroraCO.gpkg');
    // create a geopackage with the file uri.
    final geopackage = GeoPackage.withFileUri(geopackageFile.uri);
    // load the geopackage.
    await geopackage.load();
    // get the feature table with the table name.
    final geopackageFeatureTable = geopackage.geoPackageFeatureTables;
    // create a feature layer with the feature table.
    final geopackageFeatureLayer =
        FeatureLayer.withFeatureTable(geopackageFeatureTable.first);
    // clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(geopackageFeatureLayer);
    // set the viewpoint to the feature layer.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 39.7294,
        longitude: -104.8319,
        scale: 577790.554289,
      ),
    );
  }
}
