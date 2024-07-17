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
  // Declare a graphic for displaying the points of the resultant geometry.
  late final Graphic _resultPointsGraphic;
  // Declare a graphic for displaying the lines of the resultant geometry.
  late final Graphic _resultPolylineGraphic;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  //fixme comments
  var _settingsVisible = false;
  var _generalize = false;
  var _maxDeviation = 10.0;
  var _densify = false;
  var _maxSegmentLength = 100.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Stack(
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
                    // A button to show the Geometry Settings bottom sheet.
                    ElevatedButton(
                      onPressed: () => setState(() => _settingsVisible = true),
                      child: const Text('Geometry Settings'),
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
        //fixme comment
        bottomSheet: _settingsVisible ? buildSettings(context) : null,
      ),
    );
  }

  Widget buildSettings(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Geometry Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _settingsVisible = false),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Generalize'),
              const Spacer(),
              Switch(
                value: _generalize,
                onChanged: (value) {
                  setState(() => _generalize = value);
                  updateGraphics();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('Densify'),
              const Spacer(),
              Switch(
                value: _densify,
                onChanged: (value) {
                  setState(() => _densify = value);
                  updateGraphics();
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: reset,
            child: const Text('Reset'),
          ),
        ],
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

    // Create graphics for displaying the original base points and lines.
    final multipoint = multipointFromPolyline(_originalPolyline);
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

    // Create graphics for displaying the resultant points and lines.
    _resultPointsGraphic = Graphic(
      symbol: SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.purple,
        size: 7.0,
      ),
    );
    _resultPolylineGraphic = Graphic(
      symbol: SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid,
        color: Colors.purple,
        width: 3.0,
      ),
    );

    // Add the graphics to a graphics overlay, and add the overlay to the map view.
    final graphicsOverlay = GraphicsOverlay()
      ..graphics.addAll(
        [
          originalPointGraphic,
          originalPolylineGraphic,
          _resultPointsGraphic,
          _resultPolylineGraphic
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

  //fixme comment
  void updateGraphics() {
    //fixme comment
    if (!_generalize && !_densify) {
      _resultPointsGraphic.geometry = null;
      _resultPolylineGraphic.geometry = null;
      return;
    }

    //fixme comment
    var resultPolyline = _originalPolyline;

    //fixme comment
    if (_generalize) {
      resultPolyline = GeometryEngine.generalize(
        geometry: resultPolyline,
        maxDeviation: _maxDeviation,
        removeDegenerateParts: true,
      ) as Polyline;
    }

    //fixme comment
    if (_densify) {
      resultPolyline = GeometryEngine.densify(
        geometry: resultPolyline,
        maxSegmentLength: _maxSegmentLength,
      ) as Polyline;
    }

    //fixme comment
    _resultPolylineGraphic.geometry = resultPolyline;
    _resultPointsGraphic.geometry = multipointFromPolyline(resultPolyline);
  }

  //fixme comment
  void reset() {
    setState(() {
      _generalize = false;
      _maxDeviation = 10.0;
      _densify = false;
      _maxSegmentLength = 100.0;
    });
    updateGraphics();
  }

  //fixme comment
  Multipoint multipointFromPolyline(Polyline polyline) {
    //fixme simplify this
    final mutablePointCollection =
        MutablePointCollection.withSpatialReference(polyline.spatialReference);
    for (var i = 0; i < polyline.parts.size; i++) {
      final part = polyline.parts.getPart(index: i);
      for (var j = 0; j < part.pointCount; j++) {
        final point = part.getPoint(pointIndex: j);
        mutablePointCollection.addPoint(point);
      }
    }
    final multipointBuilder = MultipointBuilder.fromSpatialReference(
        mutablePointCollection.spatialReference);
    multipointBuilder.points = mutablePointCollection;
    return multipointBuilder.toGeometry() as Multipoint;
  }
}
