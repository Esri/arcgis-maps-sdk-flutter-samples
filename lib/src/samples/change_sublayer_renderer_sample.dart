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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class ChangeSublayerRendererSample extends StatefulWidget {
  const ChangeSublayerRendererSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ChangeSublayerRendererSampleState createState() =>
      ChangeSublayerRendererSampleState();
}

class ChangeSublayerRendererSampleState
    extends State<ChangeSublayerRendererSample> {
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);

    final imageLayer = ArcGISMapImageLayer.withUri(Uri.parse(
        "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer"));
    await imageLayer.load();
    final subLayers = imageLayer.arcGISMapImageSublayers;
    final countiesSublayer = subLayers.elementAt(2);

    final classBreaksRenderer = createPopulationClassBreaksRenderer();
    countiesSublayer.renderer = classBreaksRenderer;

    map.operationalLayers.add(imageLayer);
    _mapViewController.arcGISMap = map;
    _mapViewController.setViewpoint(Viewpoint.withLatLongScale(
        latitude: 48.354406, longitude: -99.998267, scale: 147914382));
  }

  ClassBreaksRenderer createPopulationClassBreaksRenderer() {
    var blue1 = const Color.fromARGB(255, 153, 206, 231);
    var blue2 = const Color.fromARGB(255, 108, 192, 232);
    var blue3 = const Color.fromARGB(255, 77, 173, 218);
    var blue4 = const Color.fromARGB(255, 28, 130, 178);
    var blue5 = const Color.fromARGB(255, 2, 75, 109);

    final outline = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid, color: Colors.grey, width: 1);
    final classSymbol1 = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid, color: blue1, outline: outline);
    final classSymbol2 = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid, color: blue2, outline: outline);
    final classSymbol3 = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid, color: blue3, outline: outline);
    final classSymbol4 = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid, color: blue4, outline: outline);
    final classSymbol5 = SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid, color: blue5, outline: outline);

    final classBreak1 = ClassBreak(
        description: '-99 to 8560',
        label: '-99 to 8560',
        minValue: -99,
        maxValue: 8560,
        symbol: classSymbol1);
    final classBreak2 = ClassBreak(
        description: '> 8,560 to 18,109',
        label: '> 8,560 to 18,109',
        minValue: 8560,
        maxValue: 18109,
        symbol: classSymbol2);
    final classBreak3 = ClassBreak(
        description: '> 18,109 to 35,501',
        label: '> 18,109 to 35,501',
        minValue: 18109,
        maxValue: 35501,
        symbol: classSymbol3);
    final classBreak4 = ClassBreak(
        description: '> 35,501 to 86,100',
        label: '> 35,501 to 86,100',
        minValue: 35501,
        maxValue: 86100,
        symbol: classSymbol4);
    final classBreak5 = ClassBreak(
        description: '> 86,100 to 10,110,975',
        label: '> 86,100 to 10,110,975',
        minValue: 86100,
        maxValue: 10110975,
        symbol: classSymbol5);

    return ClassBreaksRenderer(
      fieldName: 'POP2007',
      classBreaks: [
        classBreak1,
        classBreak2,
        classBreak3,
        classBreak4,
        classBreak5
      ],
    );
  }
}
