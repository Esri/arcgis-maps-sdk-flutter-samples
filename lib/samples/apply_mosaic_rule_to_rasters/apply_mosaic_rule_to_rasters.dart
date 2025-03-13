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

enum MosaicMethodEnum {
  objectID('Object ID', 'Orders rasters based on the order (ObjectID).'),
  northwest(
    'North West',
    'Orders rasters based on the distance between each raster center and the northwest point.',
  ),
  center(
    'Center',
    'Orders rasters based on the distance between each raster center and the view center.',
  ),
  attribute(
    'By Attribute',
    'Orders rasters based on the absolute distance between their values of an attribute and a base value.',
  ),
  lockRaster(
    'Lock Raster',
    'Displays only the selected rasters specified in [MosaicRule.lockRasterIds].',
  );

  const MosaicMethodEnum(this.value, this.description);
  final String value;
  final String description;
}

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
  // If the mosaic options should be shown.
  var _showMosaicOptions = false;
  // Current selected mosaic method.
  var _selectedMosaicMethod = MosaicMethodEnum.objectID;
  // Raster to apply the mosaic rule.
  late ImageServiceRaster _raster;

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
    // Create a Raster with the provided URL
    _raster = ImageServiceRaster(
      uri: Uri.parse(
        'https://sampleserver7.arcgisonline.com/server/rest/services/amberg_germany/ImageServer',
      ),
    );

    // Create a RasterLayer with the Raster
    final rasterLayer = RasterLayer.withRaster(_raster);
    await rasterLayer.load();
    // Set a default MosaicRule to the RasterLayer
    _raster.mosaicRule = MosaicRule()..mosaicMethod = MosaicMethod.none;
    // Add the RasterLayer to the operational layers of the map
    map.operationalLayers.add(rasterLayer);
    await _mapViewController.setViewpointCenter(
      rasterLayer.fullExtent!.center,
      scale: 25000,
    );
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Update the mosaic method of the raster layer.
  void _updateMosaicMethod() {
    switch (_selectedMosaicMethod) {
      case MosaicMethodEnum.objectID:
        _raster.mosaicRule!.mosaicMethod = MosaicMethod.none;
      case MosaicMethodEnum.northwest:
        _raster.mosaicRule!.mosaicMethod = MosaicMethod.northwest;
      case MosaicMethodEnum.center:
        _raster.mosaicRule!.mosaicMethod = MosaicMethod.center;
      case MosaicMethodEnum.attribute:
        _raster.mosaicRule!.mosaicMethod = MosaicMethod.attribute;
      case MosaicMethodEnum.lockRaster:
        _raster.mosaicRule!.mosaicMethod = MosaicMethod.lockRaster;
    }
  }

  // Build a bottom sheet to display mosaic method options.
  Widget _buildBottomSheet() {
    return BottomSheet(
      onClosing: () {},
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a mosaic rule for image service.'),
              const Divider(),
              if (!_showMosaicOptions)
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
                      Text(_selectedMosaicMethod.value),
                    ],
                  ),
                ),
              if (_showMosaicOptions)
                ListView(
                  shrinkWrap: true,
                  children:
                      MosaicMethodEnum.values.map((method) {
                        return ListTile(
                          leading:
                              (method == _selectedMosaicMethod)
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : const SizedBox(width: 16),
                          title: Text(method.value),
                          subtitle: Text(method.description),
                          onTap: () {
                            setState(() {
                              _selectedMosaicMethod = method;
                              _showMosaicOptions = false;
                            });
                            _updateMosaicMethod();
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
