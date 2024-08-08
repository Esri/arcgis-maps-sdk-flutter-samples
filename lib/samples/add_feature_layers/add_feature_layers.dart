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
import '../../utils/sample_state_support.dart';

// Create an enumeration to define the feature layer sources.
enum Source { url, portalItem, geodatabase, geopackage }

class AddFeatureLayers extends StatefulWidget {
  const AddFeatureLayers({super.key});

  @override
  State<AddFeatureLayers> createState() => _AddFeatureLayersState();
}

class _AddFeatureLayersState extends State<AddFeatureLayers>
    with SampleStateSupport {
  // Create a map with a topographic basemap style.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // Create a list of feature layer sources.
  final _featureLayerSources = <DropdownMenuItem<Source>>[];
  // Create a variable to store the selected feature layer source.
  Source? _selectedFeatureLayerSource;

  @override
  void initState() {
    super.initState();

    // Add feature layer sources to the list.
    _featureLayerSources.addAll([
      // Add a dropdown menu item to load a feature service from a uri.
      DropdownMenuItem(
        onTap: loadFeatureServiceFromUri,
        value: Source.url,
        child: const Text('URL'),
      ),
      // Add a dropdown menu item to load a feature service from a portal item.
      DropdownMenuItem(
        onTap: loadPortalItem,
        value: Source.portalItem,
        child: const Text('Portal Item'),
      ),
      // Add a dropdown menu item to load a feature service from a geodatabase.
      DropdownMenuItem(
        onTap: loadGeodatabase,
        value: Source.geodatabase,
        child: const Text('Geodatabase'),
      ),
      // Add a dropdown menu item to load a feature service from a geopackage.
      DropdownMenuItem(
        onTap: loadGeopackage,
        value: Source.geopackage,
        child: const Text('Geopackage'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        // Create a column with a map view and a dropdown button.
        child: Column(
          children: [
            // Add a map view to the widget tree and set a controller.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: _onMapViewReady,
              ),
            ),
            // Create a dropdown button to select a feature layer source.
            DropdownButton(
              alignment: Alignment.center,
              hint: const Text(
                'Select a feature layer source',
                style: TextStyle(
                  color: Colors.deepPurple,
                ),
              ),
              // Set the selected feature layer source.
              value: _selectedFeatureLayerSource,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.deepPurple,
              ),
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
              // Set the onChanged callback to update the selected feature layer source.
              onChanged: (featureLayerSource) {
                setState(() {
                  _selectedFeatureLayerSource = featureLayerSource;
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
    // Set the map on the map view controller.
    _mapViewController.arcGISMap = _map;
  }

  void loadFeatureServiceFromUri() {
    // Create a uri to a feature service.
    final uri = Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0',
    );
    // Create a service feature table with the uri.
    final serviceFeatureTables = ServiceFeatureTable.withUri(uri);
    // Create a feature layer with the service feature table.
    final serviceFeatureLayer =
        FeatureLayer.withFeatureTable(serviceFeatureTables);
    // Clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(serviceFeatureLayer);
    // Set the viewpoint to the feature layer.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 41.773519,
        longitude: -88.153104,
        scale: 6000,
      ),
    );
  }

  void loadGeodatabase() async {
    // Download the sample data.
    await downloadSampleData(['cb1b20748a9f4d128dad8a87244e3e37']);
    // Get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // Create a file to the geodatabase.
    final geodatabaseFile =
        File('${appDir.absolute.path}/LA_Trails/LA_Trails.geodatabase');
    // Create a geodatabase with the file uri.
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    // Load the geodatabase.
    await geodatabase.load();
    // Get the feature table with the table name.
    final geodatabaseFeatureTables =
        geodatabase.getGeodatabaseFeatureTable(tableName: 'Trailheads');
    // Check if the feature table is not null.
    if (geodatabaseFeatureTables != null) {
      // Create a feature layer with the feature table.
      final geodatabaseFeatureLayer =
          FeatureLayer.withFeatureTable(geodatabaseFeatureTables);
      // Clear the operational layers and add the feature layer to the map.
      _map.operationalLayers.clear();
      _map.operationalLayers.add(geodatabaseFeatureLayer);
      // Set the viewpoint to the feature layer.
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
    // Load the portal item.
    await portalItem.load();
    // Create a feature layer with the portal item and layer ID.
    final portalItemFeatureLayer = FeatureLayer.withItem(
      featureServiceItem: portalItem,
      layerId: 0,
    );
    // Clear the operational layers and add the feature layer to the map.
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
    // Download the sample data.
    await downloadSampleData(['68ec42517cdd439e81b036210483e8e7']);
    // Get the application documents directory.
    final appDir = await getApplicationDocumentsDirectory();
    // Create a file to the geopackage.
    final geopackageFile =
        File('${appDir.absolute.path}/AuroraCO/AuroraCO.gpkg');
    // Create a geopackage with the file uri.
    final geopackage = GeoPackage.withFileUri(geopackageFile.uri);
    // Load the geopackage.
    await geopackage.load();
    // Get the feature table with the table name.
    final geopackageFeatureTables = geopackage.geoPackageFeatureTables;
    // Create a feature layer with the feature table.
    final geopackageFeatureLayer =
        FeatureLayer.withFeatureTable(geopackageFeatureTables.first);
    // Clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(geopackageFeatureLayer);
    // Set the viewpoint to the feature layer.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 39.7294,
        longitude: -104.8319,
        scale: 577790.554289,
      ),
    );
  }
}
