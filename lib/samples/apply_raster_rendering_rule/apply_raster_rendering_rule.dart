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

class ApplyRasterRenderingRule extends StatefulWidget {
  const ApplyRasterRenderingRule({super.key});

  @override
  State<ApplyRasterRenderingRule> createState() =>
      _ApplyRasterRenderingRuleState();
}

class _ApplyRasterRenderingRuleState extends State<ApplyRasterRenderingRule>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A map with a streets basemap.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);

  // The web URI to the "CharlotteLAS" image service containing LAS files for Charlotte, NC downtown area.
  final _charlotteLASUri = Uri.parse(
    'https://sampleserver6.arcgisonline.com/arcgis/rest/services/CharlotteLAS/ImageServer',
  );

  // An array of raster layers, each with a different rendering rule.
  List<RasterLayer> _rasterLayers = [];

  // The selected raster layer from the dropdown menu.
  RasterLayer? _selectedRasterLayer;

  // The viewpoint for zooming the map view to a layer's extent.
  late Viewpoint _viewpoint;

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
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                buildBottomMenu(),
              ],
            ),
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Widget buildBottomMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        spacing: 10,
        children: [
          const Text('Rule:'),
          Flexible(
            child: DropdownMenu(
              expandedInsets: EdgeInsets.zero,
              textStyle: Theme.of(context).textTheme.labelMedium,
              initialSelection: _selectedRasterLayer,
              onSelected: (rasterLayer) {
                setState(() => _selectedRasterLayer = rasterLayer);
                setLayer(rasterLayer!);
              },
              dropdownMenuEntries: _rasterLayers.map((rasterLayer) {
                return DropdownMenuEntry(
                  value: rasterLayer,
                  label: rasterLayer.name,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = _map;

    // Gets the raster layers when the sample opens.
    _rasterLayers = await getRasterLayers();
    if (_rasterLayers.isNotEmpty) {
      // Load the first raster layer.
      await _rasterLayers.first.load();
      _selectedRasterLayer = _rasterLayers.first;
      setLayer(_rasterLayers.first);
    }

    setState(() => _ready = true);
  }

  // Sets a given layer on the map and zooms the viewpoint to the layer's extent.
  // - Parameter layer: The layer to set.
  void setLayer(Layer layer) {
    _map.operationalLayers.clear();
    _map.operationalLayers.add(layer);

    if (layer.fullExtent != null) {
      _viewpoint = Viewpoint.fromTargetExtent(layer.fullExtent! as Geometry);
      _mapViewController.setViewpoint(_viewpoint);
    }
  }

  // Creates raster layers for all the rendering rules from an image service raster.
  // - Returns: An array of new `RasterLayer` objects.
  Future<List<RasterLayer>> getRasterLayers() async {
    // Creates and loads an image service raster using an image service URL.
    final imageServiceRaster = ImageServiceRaster(uri: _charlotteLASUri);
    await imageServiceRaster.load();

    // Gets the rendering rule infos from the raster's service info.
    final renderingRuleInfos =
        imageServiceRaster.serviceInfo?.renderingRuleInfos ?? [];

    return renderingRuleInfos.map((renderingRuleInfo) {
      // Creates another image service raster and sets its rendering rule using the info.
      // This is required since the raster can't be loaded when setting its rendering rule.
      final imageServiceRaster = ImageServiceRaster(uri: _charlotteLASUri);
      imageServiceRaster.renderingRule = RenderingRule.withRenderingRuleInfo(
        renderingRuleInfo,
      );

      // Creates a layer using the raster.
      final rasterLayer = RasterLayer.withRaster(imageServiceRaster);
      rasterLayer.name = renderingRuleInfo.name;

      return rasterLayer;
    }).toList();
  }
}
