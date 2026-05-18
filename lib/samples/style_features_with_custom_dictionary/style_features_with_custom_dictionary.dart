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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StyleFeaturesWithCustomDictionary extends StatefulWidget {
  const StyleFeaturesWithCustomDictionary({super.key});

  @override
  State<StyleFeaturesWithCustomDictionary> createState() =>
      _StyleFeaturesWithCustomDictionaryState();
}

class _StyleFeaturesWithCustomDictionaryState
    extends State<StyleFeaturesWithCustomDictionary>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A feature layer showing restaurants in Redlands, CA.
  late final FeatureLayer _restaurantFeatureLayer;

  // Renderers for each of the dictionary renderer style options.
  final _rendererForStyle = <_RendererStyle, DictionaryRenderer>{};

  // The currently selected style.
  var _selectedStyle = _RendererStyle.styleFile;

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
                // Add a segmented button to switch between "Style File" and "Web Style" options.
                SegmentedButton(
                  segments: _RendererStyle.values
                      .map(
                        (style) => ButtonSegment(
                          value: style,
                          label: Text(style.label),
                        ),
                      )
                      .toList(),
                  selected: {_selectedStyle},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedStyle = selection.first);
                    _restaurantFeatureLayer.renderer =
                        _rendererForStyle[_selectedStyle];
                  },
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

  void onMapViewReady() {
    // Create a map with a topographic basemap style and initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 34.0543,
        longitude: -117.1963,
        scale: 10000,
      );
    _mapViewController.arcGISMap = map;

    // Prepare a feature layer with restaurants in Redlands, CA.
    _restaurantFeatureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(
          'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Redlands_Restaurants/FeatureServer/0',
        ),
      ),
    );
    map.operationalLayers.add(_restaurantFeatureLayer);

    // Prepare a DictionaryRenderer with the style file that was downloaded and stored locally.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final styleFileUri = Uri.file(listPaths.first);
    _rendererForStyle[.styleFile] = DictionaryRenderer(
      dictionarySymbolStyle: DictionarySymbolStyle.withFileUri(styleFileUri),
    );

    // Prepare a DictionaryRenderer with a web style from ArcGIS Online.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: 'adee951477014ec68d7cf0ea0579c800',
    );
    _rendererForStyle[.webStyle] = DictionaryRenderer(
      dictionarySymbolStyle: DictionarySymbolStyle.withPortalItem(portalItem),
      // This style uses the "Inspection" field to symbolize health grades.
      symbologyFieldOverrides: {'healthgrade': 'Inspection'},
    );

    // Set the selected renderer on the feature layer.
    _restaurantFeatureLayer.renderer = _rendererForStyle[_selectedStyle];

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}

// An enum to represent the different renderer style options.
enum _RendererStyle {
  styleFile('Style File'),
  webStyle('Web Style');

  const _RendererStyle(this.label);

  final String label;
}
