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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class ApplyStyleToWmsLayer extends StatefulWidget {
  const ApplyStyleToWmsLayer({super.key});

  @override
  State<ApplyStyleToWmsLayer> createState() => _ApplyStyleToWmsLayerState();
}

class _ApplyStyleToWmsLayerState extends State<ApplyStyleToWmsLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Hold a reference to the layer to enable re-styling.
  late WmsLayer _wmsLayer;

  // String array to store the styles.
  final _stylesTitles = [
    'Default',
    'Contrast stretch',
  ];

  // Create variable for holding sublayer style.
  String? _selectedStyle;

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
                // Build the bottom menu.
                buildBottomMenu(),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Widget buildBottomMenu() {
    return Center(
      // A drop down button for selecting style.
      child: DropdownButton(
        alignment: Alignment.center,
        hint: Text(
          'Choose a style',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        icon: const Icon(Icons.arrow_drop_down),
        iconEnabledColor: Theme.of(context).primaryColor,
        iconDisabledColor: Theme.of(context).disabledColor,
        style: Theme.of(context).textTheme.labelMedium,
        value: _selectedStyle,
        items: _stylesTitles.map((items) {
          return DropdownMenuItem(
            value: items,
            child: Text(items),
          );
        }).toList(),
        onChanged: (style) {
          if (style != null) {
            changeStyle(style);
          }
        },
      ),
    );
  }

  void changeStyle(String style) {
    // Set the selected style.
    setState(() => _selectedStyle = style);

    // Get the available styles from the first sublayer.
    final styles = _wmsLayer.layerInfos.first.styles;
    final wmsSublayer = _wmsLayer.sublayers.first as WmsSublayer;

    switch (style) {
      case 'Default':
        // Apply the first style to the first sublayer.
        setState(() => wmsSublayer.currentStyle = styles[0]);
      case 'Contrast stretch':
        // Apply the second style to the first sublayer.
        setState(() => wmsSublayer.currentStyle = styles[1]);
      default:
        throw StateError('Unknown style');
    }
  }

  Future<void> onMapViewReady() async {
    // Create a map with spatial reference appropriate for the service.
    final map = ArcGISMap(spatialReference: SpatialReference(wkid: 26915))
      ..minScale = 7000000.0;
    // Create a new WMS layer displaying the specified layers from the service.
    // The default styles are chosen by default.
    const wmsLayerUri =
        'https://imageserver.gisdata.mn.gov/cgi-bin/mncomp?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities';
    _wmsLayer = WmsLayer.withUriAndLayerNames(
      uri: Uri.parse(wmsLayerUri),
      layerNames: ['mncomp'],
    );

    // Wait for the layer to load.
    await _wmsLayer.load();

    if (_wmsLayer.fullExtent != null) {
      // Center the map on the layer's contents.
      map.initialViewpoint = Viewpoint.fromTargetExtent(_wmsLayer.fullExtent!);
    }

    // Add the layer to the map.
    map.operationalLayers.add(_wmsLayer);

    // Add the map to the view.
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }
}
