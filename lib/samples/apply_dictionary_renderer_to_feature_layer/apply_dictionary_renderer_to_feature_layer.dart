// Copyright 2026 Esri
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

class ApplyDictionaryRendererToFeatureLayer extends StatefulWidget {
  const ApplyDictionaryRendererToFeatureLayer({super.key});

  @override
  State<ApplyDictionaryRendererToFeatureLayer> createState() =>
      _ApplyDictionaryRendererToFeatureLayerState();
}

class _ApplyDictionaryRendererToFeatureLayerState
    extends State<ApplyDictionaryRendererToFeatureLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  //fixme screenshot

  Future<void> onMapViewReady() async {
    final listPaths = GoRouter.of(context).state.extra! as List<String>;

    // Create file references for the dictionary style and geodatabase.
    final styleFile = File(listPaths.first);
    final geodatabaseFile = File(listPaths.last);

    // Create the map and assign it to the map view controller.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Open the geodatabase that contains the military overlay features.
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await geodatabase.load();

    // Load the dictionary symbol style from the local stylx file.
    final dictionarySymbolStyle = DictionarySymbolStyle.withFileUri(
      styleFile.uri,
    );
    await dictionarySymbolStyle.load();

    // Create a feature layer for each table in the geodatabase.
    final featureLayers = <FeatureLayer>[];
    for (final table in geodatabase.geodatabaseFeatureTables) {
      final featureLayer = FeatureLayer.withFeatureTable(table);

      // Apply a dictionary renderer so the layer uses military symbols.
      featureLayer.renderer = DictionaryRenderer(
        dictionarySymbolStyle: dictionarySymbolStyle,
      );
      featureLayer.minScale = 1000000;

      featureLayers.add(featureLayer);
    }

    // Add all of the feature layers to the map.
    map.operationalLayers.addAll(featureLayers);

    // Load the layers so their content and extents are available.
    await Future.wait(featureLayers.map((layer) => layer.load()));

    // Build a combined extent from all loaded feature layers.
    final envelopeBuilder = EnvelopeBuilder(
      spatialReference: SpatialReference.wgs84,
    );
    featureLayers
        .map((layer) => layer.fullExtent)
        .nonNulls
        .forEach(envelopeBuilder.unionWithEnvelope);

    // Set the map viewpoint so all rendered features are visible.
    _mapViewController.setViewpoint(
      Viewpoint.fromTargetExtent(envelopeBuilder.extent),
    );
  }
}
