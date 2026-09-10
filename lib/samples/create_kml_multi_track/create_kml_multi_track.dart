// Copyright 2026 Esri
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

import 'dart:async';
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class CreateKmlMultiTrack extends StatefulWidget {
  const CreateKmlMultiTrack({super.key});

  @override
  State<CreateKmlMultiTrack> createState() => _CreateKmlMultiTrackState();
}

class _CreateKmlMultiTrackState extends State<CreateKmlMultiTrack>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a location data source to simulate travel along a coastal trail.
  final _simulatedLocationDataSource = SimulatedLocationDataSource();
  // Create overlays to display track elements and completed tracks.
  final _trackElementOverlay = GraphicsOverlay();
  final _trackOverlay = GraphicsOverlay();
  // Store the elements for the track currently being recorded.
  final _trackElements = <KmlTrackElement>[];
  // Store the completed tracks that will form the KML multi-track.
  final _tracks = <KmlTrack>[];

  StreamSubscription<ArcGISLocation>? _locationSubscription;
  StreamSubscription<LocationDisplayAutoPanMode>? _autoPanModeSubscription;
  Directory? _temporaryDirectory;
  List<Geometry> _loadedTrackGeometries = [];
  var _selectedTrackIndex = 0;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  var _isRecording = false;
  var _isRecenterEnabled = false;
  var _isViewingSavedTracks = false;

  @override
  void initState() {
    super.initState();

    // Update the recenter button when the user pans away from navigation mode.
    _autoPanModeSubscription = _mapViewController
        .locationDisplay
        .onAutoPanModeChanged
        .listen((autoPanMode) {
          if (!mounted) return;
          setState(() {
            _isRecenterEnabled =
                autoPanMode != LocationDisplayAutoPanMode.navigation;
          });
        });
  }

  @override
  void dispose() {
    // Stop the simulation and release subscriptions and temporary files.
    _simulatedLocationDataSource.stop().ignore();
    _locationSubscription?.cancel().ignore();
    _autoPanModeSubscription?.cancel().ignore();
    _temporaryDirectory?.delete(recursive: true).ignore();

    super.dispose();
  }

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
                  child: Stack(
                    children: [
                      ArcGISMapView(
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                      ),
                      MapBanner(text: _statusText),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _isViewingSavedTracks
                      ? _buildTrackBrowser()
                      : _buildRecordingControls(),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  String get _statusText {
    // Describe the current recording or browsing state.
    if (_isViewingSavedTracks) {
      return "Saved KML multi-track to 'HikingTracks.kmz'.";
    }
    if (_isRecording) {
      return 'Recording KML track. Elements added: ${_trackElements.length}';
    }
    return 'Tap record to capture KML track elements.';
  }

  Widget _buildRecordingControls() {
    // Build controls for recentering, recording, and saving the multi-track.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          onPressed: _ready && _isRecenterEnabled ? _recenter : null,
          icon: const Icon(Icons.my_location),
          tooltip: 'Recenter',
        ),
        FilledButton(
          onPressed: _ready ? _toggleRecording : null,
          child: Text(_isRecording ? 'Stop Recording' : 'Record Track'),
        ),
        IconButton.filledTonal(
          onPressed: _ready && _tracks.isNotEmpty && !_isRecording
              ? _saveAndLoadKmlMultiTrack
              : null,
          icon: const Icon(Icons.save_alt),
          tooltip: 'Save KML multi-track',
        ),
      ],
    );
  }

  Widget _buildTrackBrowser() {
    // Build controls for previewing tracks from the saved KMZ file.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DropdownButton<int>(
          value: _selectedTrackIndex,
          items: List.generate(
            _loadedTrackGeometries.length,
            (index) => DropdownMenuItem(
              value: index,
              child: Text(index == 0 ? 'All Tracks' : 'KML Track #$index'),
            ),
          ),
          onChanged: (index) {
            if (index == null) return;
            unawaited(_previewTrack(index));
          },
        ),
        IconButton.filledTonal(
          onPressed: _reset,
          icon: const Icon(Icons.delete),
          tooltip: 'Delete KML multi-track',
        ),
      ],
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a streets basemap style.
    final map = ArcGISMap.withBasemapStyle(.arcGISStreets);
    _mapViewController.arcGISMap = map;

    // Configure renderers for track elements and completed tracks.
    _trackElementOverlay.renderer = SimpleRenderer(
      symbol: SimpleMarkerSymbol(color: Colors.red, size: 10),
    );
    _trackOverlay.renderer = SimpleRenderer(
      symbol: SimpleLineSymbol(color: Colors.black, width: 3),
    );
    _mapViewController.graphicsOverlays.addAll([
      _trackElementOverlay,
      _trackOverlay,
    ]);

    // Create the simulated trail and frame it in the map view.
    final routePolyline = _createCoastalTrail();
    await _mapViewController.setViewpointGeometry(
      routePolyline,
      paddingInDiPs: 25,
    );

    // Start the simulated navigation and listen for recording locations.
    await _startNavigation(routePolyline);

    // Set the ready state variable to true to enable the sample UI.
    if (mounted) setState(() => _ready = true);
  }

  Polyline _createCoastalTrail() {
    // Build a coastal trail near San Francisco in WGS 84 coordinates.
    final builder = PolylineBuilder(spatialReference: SpatialReference.wgs84);
    const coordinates = [
      (-122.483531, 37.832119),
      (-122.483682, 37.831871),
      (-122.483806, 37.831658),
      (-122.483889, 37.831452),
      (-122.483979, 37.831180),
      (-122.484023, 37.830919),
      (-122.484028, 37.830776),
      (-122.484017, 37.830559),
      (-122.483985, 37.830468),
      (-122.483899, 37.830352),
      (-122.483761, 37.830252),
      (-122.483510, 37.830076),
      (-122.483343, 37.829934),
      (-122.483274, 37.829838),
      (-122.483255, 37.829737),
      (-122.483286, 37.829616),
      (-122.483368, 37.829521),
      (-122.483512, 37.829436),
      (-122.483632, 37.829409),
      (-122.483674, 37.829410),
    ];

    // Add each coordinate to the route polyline.
    for (final coordinate in coordinates) {
      builder.addPoint(
        ArcGISPoint(
          x: coordinate.$1,
          y: coordinate.$2,
          spatialReference: SpatialReference.wgs84,
        ),
      );
    }
    return builder.toGeometry() as Polyline;
  }

  Future<void> _startNavigation(Polyline routePolyline) async {
    // Generate one simulated location per second along the trail.
    _simulatedLocationDataSource.setLocationsWithPolyline(
      routePolyline,
      simulationParameters: SimulationParameters(
        startTime: DateTime.now(),
        speed: 25,
      ),
    );

    // Connect the simulated source to the location display in navigation mode.
    final locationDisplay = _mapViewController.locationDisplay;
    locationDisplay.dataSource = _simulatedLocationDataSource;
    locationDisplay.autoPanMode = LocationDisplayAutoPanMode.navigation;

    try {
      // Start the source and display before collecting location updates.
      await _simulatedLocationDataSource.start();
      locationDisplay.start();
      _locationSubscription ??= _simulatedLocationDataSource.onLocationChanged
          .listen(_recordLocation);
    } on ArcGISException catch (exception) {
      if (mounted) {
        showExceptionDialog('Failed to start simulated navigation', exception);
      }
    }
  }

  void _recordLocation(ArcGISLocation location) {
    // Ignore location updates until recording is enabled.
    if (!_isRecording) return;

    // Add a timestamped KML track element and display its position.
    _trackElements.add(
      KmlTrackElement(when: DateTime.now(), coordinate: location.position),
    );
    _trackElementOverlay.graphics.add(Graphic(geometry: location.position));
    setState(() {});
  }

  void _toggleRecording() {
    // Start a fresh track or complete the active track.
    if (_isRecording) {
      _completeTrack();
    } else {
      _trackElements.clear();
      _trackElementOverlay.graphics.clear();
      setState(() => _isRecording = true);
    }
  }

  void _completeTrack() {
    // Require at least two positions to create a KML track.
    if (_trackElements.length < 2) {
      showMessageDialog(
        'Record at least two locations before stopping.',
        title: 'Not enough track elements',
      );
      return;
    }

    // Create a relative-to-ground KML track from the recorded elements.
    final track = KmlTrack(
      elements: List.of(_trackElements),
      altitudeMode: KmlAltitudeMode.relativeToGround,
    );
    _tracks.add(track);

    // Convert the track multipoint to a polyline for display.
    final multipoint = track.geometry as Multipoint;
    final polylineBuilder = PolylineBuilder(
      spatialReference: multipoint.spatialReference,
    );
    multipoint.points.forEach(polylineBuilder.addPoint);
    _trackOverlay.graphics.add(Graphic(geometry: polylineBuilder.toGeometry()));

    // Clear the active elements and return to navigation mode.
    _trackElements.clear();
    _trackElementOverlay.graphics.clear();
    setState(() => _isRecording = false);
  }

  Future<void> _saveAndLoadKmlMultiTrack() async {
    // Disable controls while writing and reading the KMZ file.
    setState(() => _ready = false);

    try {
      // Stop navigation before exporting the completed tracks.
      await _simulatedLocationDataSource.stop();
      _mapViewController.locationDisplay.stop();

      // Create a KML document containing one multi-track placemark.
      final multiTrack = KmlMultiTrack(tracks: _tracks);
      final document = KmlDocument();
      document.childNodes.add(KmlPlacemark.withGeometry(multiTrack));

      // Save the document to a temporary local KMZ file.
      _temporaryDirectory ??= await Directory.systemTemp.createTemp(
        'create-kml-multi-track-',
      );
      final kmzFile = File('${_temporaryDirectory!.path}/HikingTracks.kmz');
      if (kmzFile.existsSync()) kmzFile.deleteSync();
      await document.saveAs(kmzFileUri: kmzFile.uri);

      // Load the KMZ and retrieve its KML multi-track geometry.
      final dataset = KmlDataset(kmzFile.uri);
      await dataset.load();
      final loadedDocument = dataset.rootNodes.first as KmlDocument;
      final placemark = loadedDocument.childNodes.first as KmlPlacemark;
      final kmlGeometry = placemark.kmlGeometry;
      if (kmlGeometry is! KmlMultiTrack) {
        throw Exception('The saved placemark does not contain a multi-track.');
      }

      // Collect the union and individual geometries for the track picker.
      final trackGeometries = kmlGeometry.tracks
          .map((track) => track.geometry)
          .toList();
      var allTracks = trackGeometries.first;
      for (final geometry in trackGeometries.skip(1)) {
        allTracks = GeometryEngine.union(
          geometry1: allTracks,
          geometry2: geometry,
        );
      }

      if (!mounted) return;
      setState(() {
        _loadedTrackGeometries = [allTracks, ...trackGeometries];
        _selectedTrackIndex = 0;
        _isViewingSavedTracks = true;
        _ready = true;
      });
      await _mapViewController.setViewpointGeometry(
        allTracks,
        paddingInDiPs: 25,
      );
    } on Exception catch (exception) {
      // Restore controls and report any KML export or load failure.
      if (!mounted) return;
      setState(() => _ready = true);
      showExceptionDialog('Failed to save or load KML multi-track', exception);
    }
  }

  Future<void> _previewTrack(int index) async {
    // Select and frame the requested saved track geometry.
    setState(() => _selectedTrackIndex = index);
    await _mapViewController.setViewpointGeometry(
      _loadedTrackGeometries[index],
      paddingInDiPs: 25,
    );
  }

  void _recenter() {
    // Restore navigation auto-pan mode around the simulated location.
    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.navigation;
  }

  Future<void> _reset() async {
    // Remove recorded and loaded tracks and delete the saved KMZ file.
    _trackElementOverlay.graphics.clear();
    _trackOverlay.graphics.clear();
    _trackElements.clear();
    _tracks.clear();
    _loadedTrackGeometries = [];
    _temporaryDirectory?.delete(recursive: true).ignore();
    _temporaryDirectory = null;

    // Restart the simulation from the beginning of the coastal trail.
    setState(() {
      _isViewingSavedTracks = false;
      _isRecording = false;
      _ready = false;
    });
    final routePolyline = _createCoastalTrail();
    await _mapViewController.setViewpointGeometry(
      routePolyline,
      paddingInDiPs: 25,
    );
    await _startNavigation(routePolyline);

    if (mounted) setState(() => _ready = true);
  }
}
