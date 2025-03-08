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

class ApplyMosaicRuleToRasters extends StatefulWidget {
  const ApplyMosaicRuleToRasters({super.key});

  @override
  State<ApplyMosaicRuleToRasters> createState() =>
      _ApplyMosaicRuleToRastersState();
}
class _ApplyMosaicRuleToRastersState extends State<ApplyMosaicRuleToRasters>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  
  var _showMosaicOptions = false;
  final _mosaicMethods = ['Object ID', 'North West', 'Center', 'By Attribute', 'Lock Raster'];
  var _selectedMosaicMethod = 'Object ID';

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
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;
    //Create a Raster with the provided URL
    final raster = ImageServiceRaster(
      uri: Uri.parse(
        'https://sampleserver7.arcgisonline.com/server/rest/services/amberg_germany/ImageServer',
      ),
    );

    //Create a RasterLayer with the Raster
    final rasterLayer = RasterLayer.withRaster(raster);
    await rasterLayer.load();
    //Set a default MosaicRule to the RasterLayer
    raster.mosaicRule = MosaicRule();
    //Add the RasterLayer to the operational layers of the map
    map.operationalLayers.add(rasterLayer);
    await _mapViewController.setViewpointCenter(
      rasterLayer.fullExtent!.center,
      scale: 25000,
    );
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> updateMosaicMethod() async {
    setState(() => _ready = false);
    final rasterLayer = _mapViewController
        .arcGISMap!.operationalLayers.firstWhere((layer) => layer is RasterLayer) as RasterLayer;
    final raster = rasterLayer.raster! as ImageServiceRaster;
    switch(_selectedMosaicMethod) {
      case 'Object ID':
        raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.none;
      case 'North West':
        raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.northwest;
      case 'Center':
        raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.center;
      case 'By Attribute':
        raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.attribute;
      case 'Lock Raster':
        raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.lockRaster;
    } 
    
    setState(() => _ready = true);
  }

  Widget _buildBottomSheet() {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showMosaicOptions = !_showMosaicOptions;
                  });
                },
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(_selectedMosaicMethod),
                ],
              ),
              ),
              if (_showMosaicOptions)
                ListView(
                  shrinkWrap: true,
                  children: _mosaicMethods.map((method) {
                    return ListTile(
                      leading: (method == _selectedMosaicMethod)
                          ? const Icon(Icons.check, color: Colors.blue)
                          : const SizedBox(width: 16),
                      title: Text(method),
                      onTap: () {
                        setState(() {
                          _selectedMosaicMethod = method;
                          _showMosaicOptions = false;
                        });
                        updateMosaicMethod();
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
