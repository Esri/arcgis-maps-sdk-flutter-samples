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

class ShowServiceAreaSample extends StatefulWidget {
  const ShowServiceAreaSample({super.key});

  @override
  State<ShowServiceAreaSample> createState() => _ShowServiceAreaSampleState();
}

class _ShowServiceAreaSampleState extends State<ShowServiceAreaSample> {
  // create a map view controller
  final _mapViewController = ArcGISMapView.createController();

  // create graphics overlays for displaying facilities and barriers and apply renderers for the symbology.
  final _facilityGraphicsOverlay = GraphicsOverlay()
    ..renderer = SimpleRenderer(
      symbol: PictureMarkerSymbol.withUrl(Uri.parse(
          'https://static.arcgis.com/images/Symbols/SafetyHealth/Hospital.png')),
    );
  final _barrierGraphicsOverlay = GraphicsOverlay()
    ..renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
          style: SimpleFillSymbolStyle.diagonalCross, color: Colors.red),
    );

  // create a graphics overlay for displays service area results and a list of symbols applied for each impedence cutoff added to the service area parameters.
  final _serviceAreaGraphicsOverlay = GraphicsOverlay();
  final _serviceAreaSymbols = [
    SimpleFillSymbol(
      color: Colors.yellowAccent.withOpacity(0.4),
      outline: SimpleLineSymbol(color: Colors.yellow.withOpacity(0.8)),
    ),
    SimpleFillSymbol(
      color: Colors.orangeAccent.withOpacity(0.4),
      outline: SimpleLineSymbol(color: Colors.orange.withOpacity(0.8)),
    ),
    SimpleFillSymbol(
      color: Colors.greenAccent.withOpacity(0.4),
      outline: SimpleLineSymbol(color: Colors.green.withOpacity(0.8)),
    ),
  ];

  // create a service area task used to find service areas around a facility.
  final _serviceAreaTask = ServiceAreaTask.withUrl(Uri.parse(
      'https://route-api.arcgis.com/arcgis/rest/services/World/ServiceAreas/NAServer/ServiceArea_World'));
  late final ServiceAreaParameters _serviceAreaParameters;

  bool _ready = false;
  Selection _segmentedButtonSelection = Selection.facility;

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
                  // add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: _ready ? onTap : null,
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // create segmented buttons for toggling adding a facility or barrier to the map.
                      SegmentedButton<Selection>(
                        segments: [
                          ButtonSegment(
                            value: Selection.facility,
                            label: Text(Selection.facility.name),
                          ),
                          ButtonSegment(
                            value: Selection.barrier,
                            label: Text(Selection.barrier.name),
                          ),
                        ],
                        selected: {_segmentedButtonSelection},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _segmentedButtonSelection = newSelection.first;
                          });
                        },
                        multiSelectionEnabled: false,
                        showSelectedIcon: false,
                      ),
                      // create buttons for calculating the service area and resetting.
                      TextButton(
                        onPressed: _ready ? solveServiceArea : null,
                        child: const Text('Service Areas'),
                      ),
                      TextButton(
                        onPressed: _ready ? resetServiceArea : null,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // display a progress indicator when the ready flag is false - this will indicate the map is loading or the service area task is in progress.
            Visibility(
              visible: !_ready,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // create a map with the light gray basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray)
      ..initialViewpoint = Viewpoint.withLatLongScale(
          latitude: 32.73, longitude: -117.16, scale: 25000);
    // set the map to the map view.
    _mapViewController.arcGISMap = map;

    // add the graphics overlays to the map view.
    _mapViewController.graphicsOverlays.addAll([
      _serviceAreaGraphicsOverlay,
      _facilityGraphicsOverlay,
      _barrierGraphicsOverlay,
    ]);

    // create default service area parameters for using to solve a service area task.
    _serviceAreaParameters = await _serviceAreaTask.createDefaultParameters();
    // returnPolygons defaults to true to return all service areas.
    // set the overlap behavior when there are results for multiple facilities.
    _serviceAreaParameters.geometryAtOverlap =
        ServiceAreaOverlapGeometry.dissolve;
    // customize impedance cutoffs for facilities (drive time minutes).
    // Note the defaults are initially set as 5, 10 and 15.
    _serviceAreaParameters.defaultImpedanceCutoffs.clear();
    _serviceAreaParameters.defaultImpedanceCutoffs.addAll([3, 8, 12]);

    // toggle the _ready flag to enable the UI.
    setState(() => _ready = true);
  }

  void onTap(Offset screenPoint) {
    // capture the tapped point and convert it to a map point.
    final mapTapPoint =
        _mapViewController.screenToLocation(screen: screenPoint);
    if (mapTapPoint == null) return;

    // add a facility or barrier to the map depending on the current toggle button selection.
    if (_segmentedButtonSelection == Selection.facility) {
      _facilityGraphicsOverlay.graphics.add(Graphic(geometry: mapTapPoint));
    } else {
      // create a buffer around the tapped point to create a barrier.
      final barrierGeometry =
          GeometryEngine.buffer(geometry: mapTapPoint, distance: 200);
      _barrierGraphicsOverlay.graphics.add(Graphic(geometry: barrierGeometry));
    }
  }

  void solveServiceArea() async {
    // require at least 1 facility to perform a service area calculation.
    if (_facilityGraphicsOverlay.graphics.isNotEmpty) {
      // disable the UI while the service area is calculated.
      setState(() {
        _ready = false;
      });
      // clear previous calculations
      _serviceAreaGraphicsOverlay.graphics.clear();

      // for each graphic in the facilities graphics overlay, add a facility to the parameters.
      final facilities = _facilityGraphicsOverlay.graphics
          .map((graphic) =>
              ServiceAreaFacility(point: graphic.geometry as ArcGISPoint))
          .toList();
      _serviceAreaParameters.setFacilities(facilities);

      // for each graphic in the barriers graphics overlay, add a polygon barrier to the parameters.
      final barriers = _barrierGraphicsOverlay.graphics
          .map(
              (graphic) => PolygonBarrier(polygon: graphic.geometry as Polygon))
          .toList();
      _serviceAreaParameters.setPolygonBarriers(barriers);

      // solve the service area using the parameters.
      final serviceAreaResult = await _serviceAreaTask.solveServiceArea(
        serviceAreaParameters: _serviceAreaParameters,
      );

      // display service area polygons for each facility - since the service area parameters have
      // geometryAtOverlap set to dissolve and the impedence cutoff values are the same across facilities,
      // we only need to draw the joined polygons for one of the facilities.
      final serviceAreaPolygons =
          serviceAreaResult.getResultPolygons(facilityIndex: 0);
      for (var i = 0; i < serviceAreaPolygons.length; i++) {
        _serviceAreaGraphicsOverlay.graphics.add(
          Graphic(
            geometry: serviceAreaPolygons[i].geometry,
            symbol: _serviceAreaSymbols[i],
          ),
        );
      }

      // re-enable the UI once the service area task is finished.
      setState(() {
        _ready = true;
      });
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text(
                'At least 1 facility is required to perform a service area calculation.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  void resetServiceArea() {
    // clear the facilities and polygon barriers from the service area parameters.
    _serviceAreaParameters.clearFacilities();
    _serviceAreaParameters.clearPolygonBarriers();
    // clear all the graphics from the map.
    for (final overlay in _mapViewController.graphicsOverlays) {
      overlay.graphics.clear();
    }
  }
}

enum Selection { facility, barrier }
