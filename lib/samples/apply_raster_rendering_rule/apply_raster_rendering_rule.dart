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

class _ApplyRasterRenderingRuleState extends State<ApplyRasterRenderingRule> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A map with a streets basemap.
  final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);

  // The web URI to the "CharlotteLAS" image service containing LAS files for Charlotte, NC downtown area.
  final _charlotteLASUri = Uri.parse(
    'https://sampleserver6.arcgisonline.com/arcgis/rest/services/CharlotteLAS/ImageServer',
  );

  // An array of raster layers, each with a different rendering rule.
  List<RasterLayer> rasterLayers = [];

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
    return Center(
      // A dropdown button for selecting a rendering rule.
      child: DropdownButton(
        alignment: Alignment.center,
        hint: Text(
          'Rendering Rule',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: Theme.of(context).textTheme.labelMedium,
        value: _selectedRasterLayer,
        onChanged: (rasterLayer) {
          setState(() => _selectedRasterLayer = rasterLayer);
          addLayer(rasterLayer!);
        },
        items: rasterLayers.map((rasterLayer) {
          return DropdownMenuItem(
            value: rasterLayer,
            child: Text(rasterLayer.name),
          );
        }).toList(),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Gets the raster layers when the sample opens.
    rasterLayers = await getRasterLayers();
    if (rasterLayers.isNotEmpty) {
      // Load the first raster layer.
      await rasterLayers.first.load();
      addLayer(rasterLayers.first);
    }

    setState(() => _ready = true);
  }

  // Sets a given layer on the map and zooms the viewpoint to the layer's extent.
  // - Parameter layer: The layer to set.
  void addLayer(Layer layer) {
    map.operationalLayers.clear();
    map.operationalLayers.add(layer);

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
      imageServiceRaster.renderingRule =
          RenderingRule.withRenderingRuleInfo(renderingRuleInfo);

      // Creates a layer using the raster.
      final rasterLayer = RasterLayer.withRaster(imageServiceRaster);
      rasterLayer.name = renderingRuleInfo.name;

      return rasterLayer;
    }).toList();
  }
}
