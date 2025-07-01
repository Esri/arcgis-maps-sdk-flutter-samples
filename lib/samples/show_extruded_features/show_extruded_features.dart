// Copyright 2025 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class ShowExtrudedFeatures extends StatefulWidget {
  const ShowExtrudedFeatures({super.key});

  @override
  State<ShowExtrudedFeatures> createState() => _ShowExtrudedFeaturesState();
}

class _ShowExtrudedFeaturesState extends State<ShowExtrudedFeatures>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;
  // An enum representing types of population statistics.
  FilterType _filterType = FilterType.totalPopulation;

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
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  // Create a set of evenly spaced buttons for each FilterType value, and when a button is pressed,
                  // it triggers the changeExtrusionExpression function with the selected filter.
                  children: FilterType.values
                      .map<Widget>(
                        (filterType) => ElevatedButton(
                          onPressed: () =>
                              changeExtrusionExpression(filterType),
                          child: Text(filterType.name),
                        ),
                      )
                      .toList(),
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

  Future<void> onSceneViewReady() async {
    // Define the Uri for the service feature table (US state polygons).
    final serviceFeatureTableUri = Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3',
    );

    // Create a service feature table from the Uri.
    final featureTable = ServiceFeatureTable.withUri(serviceFeatureTableUri);

    // Create a feature layer from the service feature table.
    final featureLayer = FeatureLayer.withFeatureTable(featureTable);
    // Set the rendering mode of the feature layer to be dynamic (needed for extrusion to work).
    featureLayer.renderingMode = FeatureRenderingMode.dynamic;

    // Create a simple line symbol for the feature layer.
    final simpleLineSymbol = SimpleLineSymbol(
      color: Colors.white.withAlpha(100),
    );
    // Create a simple fill symbol for the feature layer.
    final simpleFillSymbol = SimpleFillSymbol(
      color: const Color(0xFF2727f1),
      outline: simpleLineSymbol,
    );

    // Create a simple renderer for the feature layer.
    final simpleRenderer = SimpleRenderer(symbol: simpleFillSymbol);
    // Get the scene properties from the simple renderer.
    final sceneProperties = simpleRenderer.sceneProperties;

    // Set the renderer scene properties.
    sceneProperties.extrusionMode = ExtrusionMode.absoluteHeight;
    sceneProperties.extrusionExpression = _filterType.extrusionExpression;

    // Set the feature layer's renderer to the define simple renderer.
    featureLayer.renderer = simpleRenderer;

    // Create a scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _sceneViewController.arcGISScene = scene;

    // Add the feature layer to the scene's operational layer collection.
    scene.operationalLayers.add(featureLayer);

    // Set the scene view's viewpoint specified by the camera position.
    final point = ArcGISPoint(
      x: -10974490,
      y: 4814376,
      z: 0,
      spatialReference: SpatialReference.webMercator,
    );

    // Create an orbit location camera controller.
    final cameraController =
        OrbitLocationCameraController.withTargetPositionAndCameraDistance(
          targetLocation: point,
          distance: 20000000,
        );

    // Set the scene view's camera controller to the orbit location camera controller.
    _sceneViewController.cameraController = cameraController;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void changeExtrusionExpression(FilterType filterType) {
    setState(() => _filterType = filterType);

    // Get the first layer from the scene view's operational layers.
    final featureLayer =
        _sceneViewController.arcGISScene!.operationalLayers[0] as FeatureLayer;
    // Get the renderer from the feature layer.
    final renderer = featureLayer.renderer;
    // Get the scene properties from the feature layer's renderer.
    final sceneProperties = renderer!.sceneProperties;
    // Update renderer's scene properties extrusion expression.
    sceneProperties.extrusionExpression = _filterType.extrusionExpression;
  }
}

// An enum representing different types of population statistics filters.
enum FilterType {
  totalPopulation(
    name: 'Total Population',
    extrusionExpression: '[POP2007] / 10',
  ),

  populationDensity(
    name: 'Population Density',
    extrusionExpression: '[POP07_SQMI] * 5000 + 100000',
  );

  const FilterType({required this.name, required this.extrusionExpression});

  final String name;
  final String extrusionExpression;
}
