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
import 'dart:async';

class ShowLocationSample extends StatefulWidget {
  const ShowLocationSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  ShowLocationSampleState createState() => ShowLocationSampleState();
}

class ShowLocationSampleState extends State<ShowLocationSample> {
  final _mapViewController = ArcGISMapView.createController();
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _heading = 0.0;
  final _locationDataSource = SystemLocationDataSource();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _locationSubscription;
  ArcGISException? _ldsException;

  @override
  void dispose() {
    _locationDataSource.stop();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();

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
    locationDisplay.useCourseSymbolOnMovement = true;
    locationDisplay.autoPanMode = LocationDisplayAutoPanMode.compassNavigation;

    await _initLocationDataSource();
  }

  Future<void> _initLocationDataSource() async {
    _statusSubscription = _locationDataSource.onStatusChanged.listen((_) {
      // Redraw the screen when the LDS status changes
      setState(() {});
    });

    try {
      await _locationDataSource.start();
      _locationSubscription = _locationDataSource.onLocationChanged
          .listen(_handleLdsLocationChange);
    } on ArcGISException catch (e) {
      setState(() {
        _ldsException = e;
      });
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
