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

  Future<void> onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final styleFile = File(listPaths.first);
    final geodatabaseFile = File(listPaths.last);

    final dictionarySymbolStyle = DictionarySymbolStyle.withFileUri(
      styleFile.uri,
    );
    await dictionarySymbolStyle.load();

    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await geodatabase.load();

    EnvelopeBuilder? envelopeBuilder;
    for (final table in geodatabase.geodatabaseFeatureTables) {
      await table.load();

      final featureLayer = FeatureLayer.withFeatureTable(table);
      featureLayer.renderer = DictionaryRenderer(
        dictionarySymbolStyle: dictionarySymbolStyle,
      );
      await featureLayer.load();
      map.operationalLayers.add(featureLayer);

      final fullExtent = featureLayer.fullExtent;
      if (fullExtent == null) continue;

      envelopeBuilder ??= EnvelopeBuilder.fromEnvelope(fullExtent);
      if (envelopeBuilder.extent != fullExtent) {
        envelopeBuilder.unionWithEnvelope(fullExtent);
      }
    }

    if (envelopeBuilder != null) {
      envelopeBuilder.expandBy(1.2);
      _mapViewController.setViewpoint(
        Viewpoint.fromTargetExtent(envelopeBuilder.extent),
      );
    }
  }
}
