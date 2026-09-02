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

// Define the available KML data sources.
enum KmlSource { url, localFile, portalItem }

class AddKmlLayer extends StatefulWidget {
  const AddKmlLayer({super.key});

  @override
  State<AddKmlLayer> createState() => _AddKmlLayerState();
}

class _AddKmlLayerState extends State<AddKmlLayer> with SampleStateSupport {
  // Create a map with a dark gray basemap style.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISDarkGrayBase);

  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Store the KML sources shown in the dropdown menu.
  final _kmlSources = const [
    DropdownMenuEntry(value: KmlSource.url, label: 'URL'),
    DropdownMenuEntry(value: KmlSource.localFile, label: 'Local file'),
    DropdownMenuEntry(value: KmlSource.portalItem, label: 'Portal item'),
  ];

  // Track the currently selected KML source.
  var _selectedSource = KmlSource.url;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Add a map view to the widget tree and set a controller.
                  ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: _onMapViewReady,
                  ),
                  // Display a progress indicator while loading a KML layer.
                  LoadingIndicator(visible: !_ready),
                ],
              ),
            ),
            // Add a dropdown menu to select a KML data source.
            Padding(
              padding: const EdgeInsets.all(8),
              child: DropdownMenu<KmlSource>(
                dropdownMenuEntries: _kmlSources,
                enabled: _ready,
                initialSelection: _selectedSource,
                label: const Text('KML source'),
                onSelected: (source) {
                  if (source != null) {
                    // Load the layer for the selected KML source.
                    _loadKmlLayer(source).ignore();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    // Set the map on the map view controller.
    _mapViewController.arcGISMap = _map;

    // Load the initially selected KML layer.
    await _loadKmlLayer(_selectedSource);
  }

  Future<void> _loadKmlLayer(KmlSource source) async {
    // Disable the controls and display the loading indicator.
    setState(() {
      _ready = false;
      _selectedSource = source;
    });

    try {
      // Create a KML layer from the selected source.
      final kmlLayer = _createKmlLayer(source);

      // Replace the current operational layer with the KML layer.
      _map.operationalLayers
        ..clear()
        ..add(kmlLayer);

      // Load the KML layer and its underlying dataset.
      await kmlLayer.load();

      // Zoom to the full extent of the loaded KML layer.
      final fullExtent = kmlLayer.fullExtent;
      if (fullExtent != null) {
        await _mapViewController.setViewpointGeometry(
          fullExtent,
          paddingInDiPs: 25,
        );
      }
    } on Exception catch (exception) {
      // Report a KML layer loading failure to the user.
      showExceptionDialog('Failed to load KML layer', exception);
    } finally {
      // Re-enable the controls and hide the loading indicator.
      setState(() => _ready = true);
    }
  }

  KmlLayer _createKmlLayer(KmlSource source) {
    // Create the layer with the constructor appropriate to its source.
    switch (source) {
      case KmlSource.url:
        final dataset = KmlDataset(
          Uri.parse(
            'https://www.spc.noaa.gov/products/outlook/SPC_outlooks.kml',
          ),
        );
        return KmlLayer(dataset);
      case KmlSource.localFile:
        final extra = GoRouter.of(context).state.extra;
        if (extra is! List<String> || extra.isEmpty) {
          throw Exception(
            'Offline data path not available. Download the sample data first.',
          );
        }
        final dataset = KmlDataset(Uri.file(extra.first));
        return KmlLayer(dataset);
      case KmlSource.portalItem:
        final portalItem = PortalItem.withPortalAndItemId(
          portal: Portal.arcGISOnline(),
          itemId: '9fe0b1bfdcd64c83bd77ea0452c76253',
        );
        return KmlLayer.withItem(portalItem);
    }
  }
}
