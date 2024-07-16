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

class DensifyAndGeneralizeGeometrySample extends StatefulWidget {
  const DensifyAndGeneralizeGeometrySample({super.key});

  @override
  State<DensifyAndGeneralizeGeometrySample> createState() =>
      _DensifyAndGeneralizeGeometrySampleState();
}

class _DensifyAndGeneralizeGeometrySampleState
    extends State<DensifyAndGeneralizeGeometrySample> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Declare a polyline geometry representing the ship's route.
  late final Polyline _originalPolyline;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to perform a task.
                    ElevatedButton(
                      onPressed: performTask,
                      child: const Text('Perform Task'),
                    ),
                  ],
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

  void onMapViewReady() {
    // Build the polyline that represents the ship's route.
    // The spatial reference is NAD83 / Oregon North.
    final polylineBuilder =
        PolylineBuilder.fromSpatialReference(SpatialReference(wkid: 32126))
          ..addPointXY(x: 2330611.130549, y: 202360.002957)
          ..addPointXY(x: 2330583.834672, y: 202525.984012)
          ..addPointXY(x: 2330574.164902, y: 202691.488009)
          ..addPointXY(x: 2330689.292623, y: 203170.045888)
          ..addPointXY(x: 2330696.773344, y: 203317.495798)
          ..addPointXY(x: 2330691.419723, y: 203380.917080)
          ..addPointXY(x: 2330435.065296, y: 203816.662457)
          ..addPointXY(x: 2330369.500800, y: 204329.861789)
          ..addPointXY(x: 2330400.929891, y: 204712.129673)
          ..addPointXY(x: 2330484.300447, y: 204927.797132)
          ..addPointXY(x: 2330514.469919, y: 205000.792463)
          ..addPointXY(x: 2330638.099138, y: 205271.601116)
          ..addPointXY(x: 2330725.315888, y: 205631.231308)
          ..addPointXY(x: 2330755.640702, y: 206433.354860)
          ..addPointXY(x: 2330680.644719, y: 206660.240923)
          ..addPointXY(x: 2330386.957926, y: 207340.947204)
          ..addPointXY(x: 2330485.861737, y: 207742.298501);
    _originalPolyline = polylineBuilder.toGeometry() as Polyline;

    // Create graphics for displaying the base points and lines.
    final mutablePointCollection = MutablePointCollection.withSpatialReference(
        _originalPolyline.spatialReference);
    //fixme simplify this
    for (var i = 0; i < _originalPolyline.parts.size; i++) {
      final part = _originalPolyline.parts.getPart(index: i);
      for (var j = 0; j < part.pointCount; j++) {
        final point = part.getPoint(pointIndex: j);
        mutablePointCollection.addPoint(point);
      }
    }
    final multipointBuilder = MultipointBuilder.fromSpatialReference(
        _originalPolyline.spatialReference)
      ..points = mutablePointCollection;
    final multipoint = multipointBuilder.toGeometry() as Multipoint;
    final originalPointGraphic = Graphic(
      geometry: multipoint,
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.red,
        size: 7.0,
      ),
    );
    final originalPolylineGraphic = Graphic(
      geometry: _originalPolyline,
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.dot,
        color: Colors.red,
        width: 3.0,
      ),
    );

    // Add the graphics to a graphics overlay, and add the overlay to the map view.
    final graphicsOverlay = GraphicsOverlay()
      ..graphics.addAll(
        [
          originalPointGraphic,
          originalPolylineGraphic,
        ],
      );
    _mapViewController.graphicsOverlays.add(graphicsOverlay);

    // Create a map with a basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    // Set the initial viewpoint to show the extent of the polyline.
    map.initialViewpoint = Viewpoint.fromCenter(
      _originalPolyline.extent.center,
      scale: 65907,
    );
    _mapViewController.arcGISMap = map;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void performTask() async {
    setState(() => _ready = false);
    // Perform some task.
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
