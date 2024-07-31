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

class ShowServiceArea extends StatefulWidget {
  const ShowServiceArea({super.key});

  @override
  State<ShowServiceArea> createState() => _ShowServiceAreaState();
}

class _ShowServiceAreaState extends State<ShowServiceArea>
    with SampleStateSupport {
  // Create a map view controller.
  final _mapViewController = ArcGISMapView.createController();

  // Create graphics overlays for displaying facilities and barriers.
  final _facilityGraphicsOverlay = GraphicsOverlay();
  final _barrierGraphicsOverlay = GraphicsOverlay();

  // Create a graphics overlay for displays service area results and a list of symbols applied for each impedence cutoff added to the service area parameters.
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

  // Create a service area task used to find service areas around a facility.
  final _serviceAreaTask = ServiceAreaTask.withUrl(Uri.parse(
      'https://route-api.arcgis.com/arcgis/rest/services/World/ServiceAreas/NAServer/ServiceArea_World'));
  late final ServiceAreaParameters _serviceAreaParameters;

  // A state variable for controlling the segmented button selection.
  var _segmentedButtonSelection = Selection.facility;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the service area task is in progress.
  var _taskInProgress = false;

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
                    onTap: onTap,
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Create segmented buttons for toggling adding a facility or barrier to the map.
                      SegmentedButton(
                        segments: const [
                          ButtonSegment(
                            value: Selection.facility,
                            label: Text('Facility'),
                          ),
                          ButtonSegment(
                            value: Selection.barrier,
                            label: Text('Barrier'),
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
                      // Create buttons for calculating the service area and resetting.
                      ElevatedButton(
                        onPressed: solveServiceArea,
                        child: const Text('Service Areas'),
                      ),
                      ElevatedButton(
                        onPressed: resetServiceArea,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Display a progress indicator when the ready flag is false - this will indicate the map is loading or the service area task is in progress.
            Visibility(
              visible: !_ready || _taskInProgress,
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
    // Create a map with the light gray basemap style and an initial viewpoint.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray)
      ..initialViewpoint = Viewpoint.withLatLongScale(
          latitude: 32.73, longitude: -117.16, scale: 25000);
    // Set the map to the map view.
    _mapViewController.arcGISMap = map;

    // Apply a renderer to the barrier graphics overlay.
    _barrierGraphicsOverlay.renderer = SimpleRenderer(
      symbol: SimpleFillSymbol(
          style: SimpleFillSymbolStyle.diagonalCross, color: Colors.red),
    );

    // Apply a renderer to the facility graphics overlay.
    _facilityGraphicsOverlay.renderer = SimpleRenderer(
      symbol: PictureMarkerSymbol.withUrl(Uri.parse(
          'https://static.arcgis.com/images/Symbols/SafetyHealth/Hospital.png')),
    );

    // Add the graphics overlays to the map view.
    _mapViewController.graphicsOverlays.addAll([
      _serviceAreaGraphicsOverlay,
      _facilityGraphicsOverlay,
      _barrierGraphicsOverlay,
    ]);

    // Create default service area parameters for using to solve a service area task.
    _serviceAreaParameters = await _serviceAreaTask.createDefaultParameters();
    // Note: returnPolygons defaults to true to return all service areas.
    // Set the overlap behavior when there are results for multiple facilities.
    _serviceAreaParameters.geometryAtOverlap =
        ServiceAreaOverlapGeometry.dissolve;
    // Customize impedance cutoffs for facilities (drive time minutes).
    // Note: the defaults are initially set as 5, 10 and 15.
    _serviceAreaParameters.defaultImpedanceCutoffs.clear();
    _serviceAreaParameters.defaultImpedanceCutoffs.addAll([3, 8, 12]);

    // Toggle the _ready flag to enable the UI.
    setState(() => _ready = true);
  }

  void onTap(Offset screenPoint) {
    // Capture the tapped point and convert it to a map point.
    final mapTapPoint =
        _mapViewController.screenToLocation(screen: screenPoint);
    if (mapTapPoint == null) return;

    // Add a facility or barrier to the map depending on the current toggle button selection.
    if (_segmentedButtonSelection == Selection.facility) {
      _facilityGraphicsOverlay.graphics.add(Graphic(geometry: mapTapPoint));
    } else {
      // Create a buffer around the tapped point to create a barrier.
      final barrierGeometry =
          GeometryEngine.buffer(geometry: mapTapPoint, distance: 200);
      _barrierGraphicsOverlay.graphics.add(Graphic(geometry: barrierGeometry));
    }
  }

  void solveServiceArea() async {
    // Require at least 1 facility to perform a service area calculation.
    if (_facilityGraphicsOverlay.graphics.isNotEmpty) {
      // Disable the UI while the service area is calculated.
      setState(() => _taskInProgress = true);
      // Clear previous calculations.
      _serviceAreaGraphicsOverlay.graphics.clear();

      // For each graphic in the facilities graphics overlay, add a facility to the parameters.
      final facilities = _facilityGraphicsOverlay.graphics
          .map((graphic) =>
              ServiceAreaFacility(point: graphic.geometry as ArcGISPoint))
          .toList();
      _serviceAreaParameters.setFacilities(facilities);

      // For each graphic in the barriers graphics overlay, add a polygon barrier to the parameters.
      final barriers = _barrierGraphicsOverlay.graphics
          .map(
              (graphic) => PolygonBarrier(polygon: graphic.geometry as Polygon))
          .toList();
      _serviceAreaParameters.setPolygonBarriers(barriers);

      // Solve the service area using the parameters.
      final serviceAreaResult = await _serviceAreaTask.solveServiceArea(
        serviceAreaParameters: _serviceAreaParameters,
      );

      // Display service area polygons for each facility - since the service area parameters have
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

      // Re-enable the UI once the service area task is finished.
      setState(() => _taskInProgress = false);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text(
              'At least 1 facility is required to perform a service area calculation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void resetServiceArea() {
    // Clear the facilities and polygon barriers from the service area parameters.
    _serviceAreaParameters.clearFacilities();
    _serviceAreaParameters.clearPolygonBarriers();
    // Clear all the graphics from the map.
    _mapViewController.graphicsOverlays
        .map((overlay) => overlay.graphics.clear())
        .toList();
  }
}

enum Selection { facility, barrier }
