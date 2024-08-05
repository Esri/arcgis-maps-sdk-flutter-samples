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
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ApplyClassBreaksRendererToSublayer extends StatefulWidget {
  const ApplyClassBreaksRendererToSublayer({super.key});

  @override
  State<ApplyClassBreaksRendererToSublayer> createState() =>
      _ApplyClassBreaksRendererToSublayerState();
}

class _ApplyClassBreaksRendererToSublayerState
    extends State<ApplyClassBreaksRendererToSublayer> with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();
  // Create a map with a basemap style.
  final _map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the renderer has been updated.
  var _rendered = false;
  // Create an image sublayer.
  late ArcGISMapImageSublayer _countiesSublayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              // Add the map view and buttons to a column.
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Center(
                  // Apply renderer button.
                  child: ElevatedButton(
                    onPressed: !_rendered ? renderLayer : null,
                    child: const Text('Change Sublayer Renderer'),
                  ),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create an image layer.
    final imageLayer = ArcGISMapImageLayer.withUri(
      Uri.parse(
        'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer',
      ),
    );
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = _map;
    // Set the initial viewpoint.
    _mapViewController.setViewpoint(
      Viewpoint.withLatLongScale(
        latitude: 48.354406,
        longitude: -99.998267,
        scale: 147914382,
      ),
    );
    // Add the image layer to the map.
    _map.operationalLayers.add(imageLayer);

    // Load the image layer and counties sublayer.
    await imageLayer.load();
    _countiesSublayer = imageLayer.arcGISMapImageSublayers.elementAt(2);
    await _countiesSublayer.load();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void renderLayer() async {
    // Apply class breaks renderer.
    _countiesSublayer.renderer = createPopulationClassBreaksRenderer();
    // Update the rendered state.
    setState(() => _rendered = true);
  }

  ClassBreaksRenderer createPopulationClassBreaksRenderer() {
    // Create colors for the class breaks.
    const blue1 = Color.fromARGB(255, 153, 206, 231);
    const blue2 = Color.fromARGB(255, 108, 192, 232);
    const blue3 = Color.fromARGB(255, 77, 173, 218);
    const blue4 = Color.fromARGB(255, 28, 130, 178);
    const blue5 = Color.fromARGB(255, 2, 75, 109);

    // Create symbols for the class breaks.
    final outline = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid,
      color: Colors.grey,
      width: 1,
    );
    final classSymbol1 = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: blue1,
      outline: outline,
    );
    final classSymbol2 = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: blue2,
      outline: outline,
    );
    final classSymbol3 = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: blue3,
      outline: outline,
    );
    final classSymbol4 = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: blue4,
      outline: outline,
    );
    final classSymbol5 = SimpleFillSymbol(
      style: SimpleFillSymbolStyle.solid,
      color: blue5,
      outline: outline,
    );

    // Create class breaks.
    final classBreak1 = ClassBreak(
      description: '-99 to 8560',
      label: '-99 to 8560',
      minValue: -99,
      maxValue: 8560,
      symbol: classSymbol1,
    );
    final classBreak2 = ClassBreak(
      description: '> 8,560 to 18,109',
      label: '> 8,560 to 18,109',
      minValue: 8560,
      maxValue: 18109,
      symbol: classSymbol2,
    );
    final classBreak3 = ClassBreak(
      description: '> 18,109 to 35,501',
      label: '> 18,109 to 35,501',
      minValue: 18109,
      maxValue: 35501,
      symbol: classSymbol3,
    );
    final classBreak4 = ClassBreak(
      description: '> 35,501 to 86,100',
      label: '> 35,501 to 86,100',
      minValue: 35501,
      maxValue: 86100,
      symbol: classSymbol4,
    );
    final classBreak5 = ClassBreak(
      description: '> 86,100 to 10,110,975',
      label: '> 86,100 to 10,110,975',
      minValue: 86100,
      maxValue: 10110975,
      symbol: classSymbol5,
    );

    // Create and return a class breaks renderer.
    return ClassBreaksRenderer(
      fieldName: 'POP2007',
      classBreaks: [
        classBreak1,
        classBreak2,
        classBreak3,
        classBreak4,
        classBreak5,
      ],
    );
  }
}
