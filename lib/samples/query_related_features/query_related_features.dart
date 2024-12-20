import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class QueryRelatedFeatures extends StatefulWidget {
  const QueryRelatedFeatures({super.key});

  @override
  State<QueryRelatedFeatures> createState() => _QueryRelatedFeaturesState();
}

class _QueryRelatedFeaturesState extends State<QueryRelatedFeatures>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the settings bottom sheet is visible.
  var _layerDataVisible = false;
  // A flag for when the features are loading.
  var _loadingFeatures = false;
  // Feature layer for the Alaska National Parks.
  late final FeatureLayer _alaskaNationalParksLayer;
  // The name of the selected park.
  var _selectedParkName = '';
  // Lists to store the names of the related features.
  var _featurePreserves = <String>[];
  var _featureSpecies = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            // Add a map view to the widget tree and set a controller.
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onMapViewReady: onMapViewReady,
              onTap: onTap,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // Display the bottom sheet when the selected layer data is available.
      bottomSheet: _layerDataVisible ? buildLayerData(context) : null,
    );
  }

  Widget buildLayerData(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
      ),
      padding: EdgeInsets.fromLTRB(
        20.0,
        5.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _loadingFeatures
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _selectedParkName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
              ),
              IconButton(
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _layerDataVisible = false),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Alaska National Parks Preserves',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  // Display the list of feature preserves for the selected park.
                  for (final preserve in _featurePreserves)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        preserve,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  const Divider(),
                  Text(
                    'Alaska National Parks Species',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  // Display the list of feature species for the selected park.
                  for (final species in _featureSpecies)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        species,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // Feature table for the Alaska National Parks layer.
    final alaskaNationalParksFeaturesTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/1',
      ),
    );

    // Create parks feature layer, the origin layer in the relationship.
    _alaskaNationalParksLayer =
        FeatureLayer.withFeatureTable(alaskaNationalParksFeaturesTable);

    // Add parks feature layer to the map.
    map.operationalLayers.add(_alaskaNationalParksLayer);
    await _alaskaNationalParksLayer.load();

    // Create a feature table for related preserves layer.
    final alaskaNationalParksPreservesTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/0',
      ),
    );
    // Create a feature table for related species layer.
    final alaskaNationalParksSpeciesTable = ServiceFeatureTable.withUri(
      Uri.parse(
        'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/2',
      ),
    );
    // Add these to the tables on the map.
    map.tables.addAll(
      [alaskaNationalParksSpeciesTable, alaskaNationalParksPreservesTable],
    );

    // Assign map to the map view.
    _mapViewController.arcGISMap = map
      ..initialViewpoint = Viewpoint.fromCenter(
        ArcGISPoint(
          x: -16507762.575543,
          y: 9058828.127243,
          spatialReference: SpatialReference.webMercator,
        ),
        scale: 36764077,
      );

    // Set selection color.
    _mapViewController.selectionProperties =
        SelectionProperties(color: Colors.yellow);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) async {
    // Clear the selection on the feature layer.
    _alaskaNationalParksLayer.clearSelection();

    // Do an identify on the feature layer and select a feature.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _alaskaNationalParksLayer,
      screenPoint: offset,
      tolerance: 12.0,
      maximumResults: 1,
    );

    // If there are features identified, show the bottom sheet to display the
    // attachment information for the selected feature.
    setState(() {
      _selectedParkName = '';
      _featurePreserves = [];
      _featureSpecies = [];
    });
    final features =
        identifyLayerResult.geoElements.whereType<Feature>().toList();
    if (features.isNotEmpty) {
      _alaskaNationalParksLayer.selectFeatures(features);
      final selectedFeature = features.first as ArcGISFeature;
      setState(() {
        _layerDataVisible = true;
        _loadingFeatures = true;
      });
      // Query for related features.
      queryRelatedFeatures(selectedFeature);
    } else {
      setState(() {
        _layerDataVisible = false;
        _loadingFeatures = false;
      });
    }
  }

  // Query for related features given the origin feature.
  void queryRelatedFeatures(ArcGISFeature selectedPark) async {
    // Query for related features.
    final selectedParkTable = selectedPark.featureTable as ServiceFeatureTable;
    final relatedFeatureQueryResult =
        await selectedParkTable.queryRelatedFeatures(feature: selectedPark);

    // Get the related species and preserves features.
    final relatedFeaturesLists = <List<String>>[];
    for (final result in relatedFeatureQueryResult) {
      final relatedFeatures = <String>[];
      for (final feature in result.features()) {
        final relatedFeature = feature as ArcGISFeature;
        // Get a reference to the feature's table.
        final relatedTable = feature.featureTable as ArcGISFeatureTable;

        // Get the display field name - this is the name of the field that is intended for display.
        final displayFieldName = relatedTable.layerInfo!.displayFieldName;

        // Get the display name for the feature.
        final featureDisplayname = relatedFeature.attributes[displayFieldName];

        // Add the display name to the list.
        relatedFeatures.add(featureDisplayname);
      }
      relatedFeaturesLists.add(relatedFeatures);
    }

    // Update the UI with the related features.
    setState(() {
      _loadingFeatures = false;
      _selectedParkName = selectedPark.attributes['UNIT_NAME'];

      _featurePreserves = relatedFeaturesLists[0];

      _featureSpecies = relatedFeaturesLists[1];
    });
  }
}
