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

class CutGeometrySample extends StatefulWidget {
  const CutGeometrySample({super.key});

  @override
  State<CutGeometrySample> createState() => _CutGeometrySampleState();
}

class _CutGeometrySampleState extends State<CutGeometrySample>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag to track if the geometry has been cut.
  var _geometryCut = false;

  // The graphics for the original state of the sample.
  late final Graphic _lakeGraphic;
  late final Graphic _borderGraphic;

  // Graphics overlay to present the graphics for the sample.
  final _graphicsOverlay = GraphicsOverlay();

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
                    // Button to trigger the cut function or reset to the original state.
                    ElevatedButton(
                      onPressed: _geometryCut ? resetGeometry : cutGeometry,
                      child: _geometryCut
                          ? const Text('Reset')
                          : const Text('Cut'),
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
    // Create a map with a topographic basemap style and add it to the map view controller.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    // Add the graphics overlay to the map view controller.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Initialize the graphics for the sample.
    _initLakeGraphic();
    _initBorderGraphic();

    // Add the graphics to the graphics overlay.
    _graphicsOverlay.graphics.addAll([_lakeGraphic, _borderGraphic]);

    // Set the viewpoint to the lake graphic.
    _mapViewController.setViewpoint(
      Viewpoint.fromTargetExtent(_lakeGraphic.geometry!.extent),
    );

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Cut the lake geometry with the border geometry. The results
  // of the cut will be displayed on the map.
  void cutGeometry() {
    // Cut the lake geometry with the border geometry.
    final cutGeometries = GeometryEngine.cut(
      geometry: _lakeGraphic.geometry!,
      cutter: _borderGraphic.geometry! as Polyline,
    );

    // Create graphics for the cut geometries.
    final canadianGraphic = Graphic(
      geometry: cutGeometries.first,
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.backwardDiagonal,
        color: Colors.green,
      ),
    );
    final usaGraphic = Graphic(
      geometry: cutGeometries.last,
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.forwardDiagonal,
        color: Colors.red,
      ),
    );

    // Add the graphics for the cut geometries to the graphics overlay.
    _graphicsOverlay.graphics.addAll([canadianGraphic, usaGraphic]);

    // Update the state to reflect the geometry cut.
    setState(() => _geometryCut = true);
  }

  // Reset the graphics to the original state.
  void resetGeometry() {
    // Clear the graphics overlay and add the original graphics.
    _graphicsOverlay.graphics.clear();
    _graphicsOverlay.graphics.addAll([_lakeGraphic, _borderGraphic]);

    // Update the state to reflect the geometry reset.
    setState(() => _geometryCut = false);
  }

  // Utility function to build the Polygon geometry and create the Graphic for
  // the lake. This geometry will be cut by the border geometry.
  void _initLakeGraphic() {
    // Build the Polygon for the lake.
    final lakePolygonBuilder = PolygonBuilder.fromSpatialReference(
        _mapViewController.spatialReference);
    lakePolygonBuilder.addPointXY(x: -10254374.668616, y: 5908345.076380);
    lakePolygonBuilder.addPointXY(x: -10178382.525314, y: 5971402.386779);
    lakePolygonBuilder.addPointXY(x: -10118558.923141, y: 6034459.697178);
    lakePolygonBuilder.addPointXY(x: -9993252.729399, y: 6093474.872295);
    lakePolygonBuilder.addPointXY(x: -9882498.222673, y: 6209888.368416);
    lakePolygonBuilder.addPointXY(x: -9821057.766387, y: 6274562.532928);
    lakePolygonBuilder.addPointXY(x: -9690092.583250, y: 6241417.023616);
    lakePolygonBuilder.addPointXY(x: -9605207.742329, y: 6206654.660191);
    lakePolygonBuilder.addPointXY(x: -9564786.389509, y: 6108834.986367);
    lakePolygonBuilder.addPointXY(x: -9449989.747500, y: 6095091.726408);
    lakePolygonBuilder.addPointXY(x: -9462116.153346, y: 6044160.821855);
    lakePolygonBuilder.addPointXY(x: -9417652.665244, y: 5985145.646738);
    lakePolygonBuilder.addPointXY(x: -9438671.768711, y: 5946341.148031);
    lakePolygonBuilder.addPointXY(x: -9398250.415891, y: 5922088.336339);
    lakePolygonBuilder.addPointXY(x: -9419269.519357, y: 5855797.317714);
    lakePolygonBuilder.addPointXY(x: -9467775.142741, y: 5858222.598884);
    lakePolygonBuilder.addPointXY(x: -9462924.580403, y: 5902686.086985);
    lakePolygonBuilder.addPointXY(x: -9598740.325877, y: 5884092.264688);
    lakePolygonBuilder.addPointXY(x: -9643203.813979, y: 5845287.765981);
    lakePolygonBuilder.addPointXY(x: -9739406.633691, y: 5879241.702350);
    lakePolygonBuilder.addPointXY(x: -9783061.694736, y: 5922896.763395);
    lakePolygonBuilder.addPointXY(x: -9844502.151022, y: 5936640.023354);
    lakePolygonBuilder.addPointXY(x: -9773360.570059, y: 6019099.583107);
    lakePolygonBuilder.addPointXY(x: -9883306.649729, y: 5968977.105610);
    lakePolygonBuilder.addPointXY(x: -9957681.938918, y: 5912387.211662);
    lakePolygonBuilder.addPointXY(x: -10055501.612742, y: 5871965.858842);
    lakePolygonBuilder.addPointXY(x: -10116942.069028, y: 5884092.264688);
    lakePolygonBuilder.addPointXY(x: -10111283.079633, y: 5933406.315128);
    lakePolygonBuilder.addPointXY(x: -10214761.742852, y: 5888134.399970);

    // Generate the polygon graphic.
    _lakeGraphic = Graphic(
      geometry: lakePolygonBuilder.toGeometry(),
      symbol: SimpleFillSymbol(
        color: Colors.blue.withOpacity(0.5),
        outline: SimpleLineSymbol(
          color: Colors.blue,
          width: 4.0,
          style: SimpleLineSymbolStyle.solid,
        ),
      ),
    );
  }

  // Utility funciton to build the Polyline geometry and create the Graphic for
  // the border. This geometry will be used to cut the lake geometry.
  void _initBorderGraphic() {
    // Build the Polyline geometry for the border.
    final borderPolylineBuilder = PolylineBuilder.fromSpatialReference(
        _mapViewController.spatialReference);
    borderPolylineBuilder.addPointXY(x: -9981328.687124, y: 6111053.281447);
    borderPolylineBuilder.addPointXY(x: -9946518.044066, y: 6102350.620682);
    borderPolylineBuilder.addPointXY(x: -9872545.427566, y: 6152390.920079);
    borderPolylineBuilder.addPointXY(x: -9838822.617103, y: 6157830.083057);
    borderPolylineBuilder.addPointXY(x: -9446115.050097, y: 5927209.572793);
    borderPolylineBuilder.addPointXY(x: -9430885.393759, y: 5876081.440801);
    borderPolylineBuilder.addPointXY(x: -9415655.737420, y: 5860851.784463);

    // Generate the polyline graphic.
    _borderGraphic = Graphic(
      geometry: borderPolylineBuilder.toGeometry(),
      symbol: SimpleLineSymbol(
        color: Colors.red,
        width: 4.0,
        style: SimpleLineSymbolStyle.dot,
      ),
    );
  }
}
