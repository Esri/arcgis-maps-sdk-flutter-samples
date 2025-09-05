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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Create an enumeration to define the feature layer sources.
enum Source { url, portalItem, geodatabase, geopackage, shapefile }

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
  final _featureLayerSources = <DropdownMenuEntry<Source>>[];

  // Create a variable to store the selected feature layer source.
  Source? _selectedFeatureLayerSource;

  final _dataSources = Map<Source, String>();

  @override
  void initState() {
    super.initState();

    // Add feature layer sources to the list.
    _featureLayerSources.addAll(const [
      // Add a dropdown menu item to load a feature service from a uri.
      DropdownMenuEntry(value: Source.url, label: 'URL'),
      // Add a dropdown menu item to load a feature service from a portal item.
      DropdownMenuEntry(value: Source.portalItem, label: 'Portal Item'),
      // Add a dropdown menu item to load a feature service from a geodatabase.
      DropdownMenuEntry(value: Source.geodatabase, label: 'Geodatabase'),
      // Add a dropdown menu item to load a feature service from a geopackage.
      DropdownMenuEntry(value: Source.geopackage, label: 'Geopackage'),
      DropdownMenuEntry(value: Source.shapefile, label: 'Shapefile'),
    ]);
    _initDownloadResources();
  }

  void _initDownloadResources() {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _dataSources[Source.geodatabase] = '${listPaths[0]}/LA_Trails.geodatabase';
    _dataSources[Source.geopackage] = '${listPaths[1]}/AuroraCO.gpkg';
    _dataSources[Source.shapefile] = '${listPaths[2]}/ScottishWildlifeTrust_ReserveBoundaries_20201102.shp';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        // Create a column with a map view and a dropdown menu.
        child: Column(
          children: [
            // Add a map view to the widget tree and set a controller.
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: _onMapViewReady,
              ),
            ),
            // Create a dropdown menu to select a feature layer source.
            DropdownMenu(
              dropdownMenuEntries: _featureLayerSources,
              trailingIcon: const Icon(Icons.arrow_drop_down),
              textAlign: TextAlign.center,
              textStyle: Theme.of(context).textTheme.labelMedium,
              hintText: 'Select a feature layer source',
              width: calculateMenuWidth(
                context,
                'Select a feature layer source',
              ),
              onSelected: (featureLayerSource) {
                setState(() {
                  _selectedFeatureLayerSource = featureLayerSource;
                });
                handleSourceSelection(featureLayerSource!);
              },
              initialSelection: _selectedFeatureLayerSource,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    // Set the map on the map view controller.
    _mapViewController.arcGISMap = _map;
  }

  // Handles the selection of a feature layer source from the dropdown menu.
  void handleSourceSelection(Source source) {
    switch (source) {
      case Source.url:
        loadFeatureServiceFromUri();
      case Source.portalItem:
        loadPortalItem();
      case Source.geodatabase:
        loadGeodatabase();
      case Source.geopackage:
        loadGeopackage();
      case Source.shapefile:
        loadShapefile();
    }
  }

  double calculateMenuWidth(BuildContext context, String menuString) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: menuString,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.size.width;

    return textWidth * 1.5;
  }

  void loadFeatureServiceFromUri() {
    // Create a uri to a feature service.
    final uri = Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0',
    );
    // Create a service feature table with the uri.
    final serviceFeatureTables = ServiceFeatureTable.withUri(uri);
    // Create a feature layer with the service feature table.
    final serviceFeatureLayer = FeatureLayer.withFeatureTable(
      serviceFeatureTables,
    );
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

  Future<void> loadGeodatabase() async {
    // Create a file to the geodatabase.
    final geodatabaseFile = File('${_dataSources[Source.geodatabase]}');

    // Create a geodatabase with the file uri.
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    // Load the geodatabase.
    await geodatabase.load();
    // Get the feature table with the table name.
    final geodatabaseFeatureTables = geodatabase.getGeodatabaseFeatureTable(
      tableName: 'Trailheads',
    );
    // Check if the feature table is not null.
    if (geodatabaseFeatureTables != null) {
      // Create a feature layer with the feature table.
      final geodatabaseFeatureLayer = FeatureLayer.withFeatureTable(
        geodatabaseFeatureTables,
      );
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

  Future<void> loadPortalItem() async {
    // Set the portal.
    final portal = Portal.arcGISOnline();
    // Create the portal item with the item ID for the Portland tree service data.
    const itemId = '1759fd3e8a324358a0c58d9a687a8578';
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: itemId,
    );
    // Load the portal item.
    await portalItem.load();
    // Create a feature layer with the portal item and layer ID.
    final portalItemFeatureLayer = FeatureLayer.withItem(
      item: portalItem,
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

  Future<void> loadGeopackage() async {
    final geopackageFile = File('${_dataSources[Source.geopackage]}');
    // Create a geopackage with the file uri.
    final geopackage = GeoPackage.withFileUri(geopackageFile.uri);
    // Load the geopackage.
    await geopackage.load();
    // Get the feature table with the table name.
    final geopackageFeatureTables = geopackage.geoPackageFeatureTables;
    // Create a feature layer with the feature table.
    final geopackageFeatureLayer = FeatureLayer.withFeatureTable(
      geopackageFeatureTables.first,
    );
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

  /// Load a feature layer with a local shapefile.
  Future<void> loadShapefile() async {
    // Get the Shapefile from the download resource.
    final shapefile = File('${_dataSources[Source.shapefile]}');
    // Create a feature table from the Shapefile URI.
    final shapefileFeatureTable = ShapefileFeatureTable.withFileUri(
      shapefile.uri,
    );
    // Create a feature layer for the Shapefile feature table.
    final shapefileFeatureLayer = FeatureLayer.withFeatureTable(
      shapefileFeatureTable,
    );
    // Clear the operational layers and add the feature layer to the map.
    _map.operationalLayers.clear();
    _map.operationalLayers.add(shapefileFeatureLayer);
    // Set the viewpoint to the feature layer.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 56.641344,
        longitude: -3.889066,
        scale: 6000000,
      ),
    );
  }
}
