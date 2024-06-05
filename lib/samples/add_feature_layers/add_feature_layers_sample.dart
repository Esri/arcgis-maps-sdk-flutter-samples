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
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/sample_data.dart';

class AddFeatureLayersSample extends StatefulWidget {
  const AddFeatureLayersSample({super.key});

  @override
  State<AddFeatureLayersSample> createState() => _AddFeatureLayersSampleState();
}

class _AddFeatureLayersSampleState extends State<AddFeatureLayersSample> {
  final _mapViewController = ArcGISMapView.createController();
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
  final _featureLayerSources =
      List<DropdownMenuItem<String>>.empty(growable: true);
  String? _selectedFeatureLayerSource;

  @override
  void initState() {
    super.initState();

    _mapViewController.arcGISMap = _map;

    _featureLayerSources.addAll([
      DropdownMenuItem(
        onTap: loadFeatureServiceFromUri,
        value: 'URL',
        child: const Text('URL'),
      ),
      DropdownMenuItem(
        onTap: loadGeodatabase,
        value: 'Geodatabase',
        child: const Text('Geodatabase'),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
              ),
            ),
            DropdownButton<String>(
              alignment: Alignment.center,
              hint: const Text(
                'Select a feature layer source',
                style: TextStyle(
                  color: Colors.deepPurple,
                ),
              ),
              value: _selectedFeatureLayerSource,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.deepPurple,
              ),
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
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

  void loadFeatureServiceFromUri() {
    final uri = Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0');
    final serviceFeatureTable = ServiceFeatureTable.fromUri(uri);
    final featureLayer = FeatureLayer.withFeatureTable(serviceFeatureTable);
    _map.operationalLayers.clear();
    _map.operationalLayers.add(featureLayer);
    _mapViewController.setViewpoint(Viewpoint.withLatLongScale(
      latitude: 41.773519,
      longitude: -88.153104,
      scale: 6000,
    ));
  }

  void loadGeodatabase() async {
    await downloadSampleData(['cb1b20748a9f4d128dad8a87244e3e37']);

    final appDir = await getApplicationDocumentsDirectory();
    final geodatabaseFile =
        File('${appDir.absolute.path}/LA_Trails/LA_Trails.geodatabase');
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await geodatabase.load();
    final featureTable =
        geodatabase.getGeodatabaseFeatureTable(tableName: 'Trailheads');
    if (featureTable != null) {
      final featureLayer = FeatureLayer.withFeatureTable(featureTable);
      _map.operationalLayers.clear();
      _map.operationalLayers.add(featureLayer);
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
}
