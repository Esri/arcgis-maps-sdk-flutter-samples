//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
//

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SimulateLocationSample extends StatefulWidget {
  const SimulateLocationSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SimulateLocationSampleState createState() => SimulateLocationSampleState();
}

class SimulateLocationSampleState extends State<SimulateLocationSample> {
  final _mapViewController = ArcGISMapView.createController();
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _heading = 0.0;
  final _locationDataSource = SimulatedLocationDataSource();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _locationSubscription;
  ArcGISException? _ldsException;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    if (_locationDataSource.status == LocationDataSourceStatus.starting ||
        _locationDataSource.status == LocationDataSourceStatus.started) {
      _locationDataSource.stop();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                  Positioned(
                    bottom: 60.0,
                    right: 10.0,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Location:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Latitude: $_latitude'),
                          Text('Longitude: $_longitude'),
                          Text('Heading: $_heading')
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Column(
                children: [
                  const Text('Location Data Source'),
                  Visibility(
                    visible: _ldsException == null,
                    child: ElevatedButton(
                      child: Text(_locationDataSource.status ==
                              LocationDataSourceStatus.started
                          ? 'Stop'
                          : 'Start'),
                      onPressed: () {
                        if (_locationDataSource.status ==
                            LocationDataSourceStatus.started) {
                          _mapViewController.locationDisplay.stop();
                        } else {
                          _mapViewController.locationDisplay.start();
                        }
                      },
                    ),
                  ),
                  Visibility(
                    visible: _ldsException != null,
                    child: Text('Exception: ${_ldsException?.message}'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard);

    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -110.8258,
        y: 32.154089,
        spatialReference: SpatialReference.wgs84,
      ),
      scale: 2e4,
    );

    _mapViewController.arcGISMap = map;
    await _initLocationDisplay();
  }

  Future<void> _initLocationDisplay() async {
    final locationDisplay = _mapViewController.locationDisplay;
    locationDisplay.dataSource = _locationDataSource;
    locationDisplay.autoPanMode = LocationDisplayAutoPanMode.recenter;
    locationDisplay.useCourseSymbolOnMovement = true;
    await _initLocationDataSource();
  }

  Future<void> _initLocationDataSource() async {
    final routeLineJson =
        await rootBundle.loadString('assets/samples/SimulatedRoute.json');
    final routeLine = Geometry.fromJsonString(routeLineJson) as Polyline;
    _locationDataSource.setLocationsWithPolyline(routeLine);
    _statusSubscription = _locationDataSource.onStatusChanged.listen((_) {
      // Redraw the screen when the LDS status changes
      setState(() {});
    });

    try {
      await _locationDataSource.start();
      _locationSubscription = _locationDataSource.onLocationChanged
          .listen(_handleLdsLocationChange);
    } on ArcGISException catch (e) {
      setState(() => _ldsException = e);
    }
  }

  void _handleLdsLocationChange(ArcGISLocation location) {
    setState(() {
      _latitude = location.position.y;
      _longitude = location.position.x;
      _heading = location.course;
    });
  }
}
