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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListContentsOfKmlFile extends StatefulWidget {
  const ListContentsOfKmlFile({super.key});

  @override
  State<ListContentsOfKmlFile> createState() => _ListContentsOfKmlFileState();
}

class _ListContentsOfKmlFileState extends State<ListContentsOfKmlFile>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // Dataset for the data in KML file.
  late final KmlDataset _kmlDataset;

  // The KML document containing the nodes to list.
  KmlDocument? _kmlDocument;

  var _showBottomSheet = true;

  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _kmlDataset = _initKmlDataset();
  }

  @override
  void dispose() {
    // Clean up the scene to avoid memory retention.
    _sceneViewController.arcGISScene?.operationalLayers.clear();
    _sceneViewController.arcGISScene = null;
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
                  // Add a scene view to the widget tree and set a controller.
                  child: ArcGISSceneView(
                    controllerProvider: () => _sceneViewController,
                    onSceneViewReady: onSceneViewReady,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _showBottomSheet = true),
                  child: const Text('Show KML contents'),
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      bottomSheet: _showBottomSheet
          ? FractionallySizedBox(
              heightFactor: 0.75,
              child: Padding(
                padding: bottomSheetPadding(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'KML Contents',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _showBottomSheet = false;
                          }),
                        ),
                      ],
                    ),
                    Expanded(child: _buildKmlList()),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with an imagery basemap style and add it to the scene view.
    final scene = ArcGISScene.withBasemapStyle(.arcGISImagery);
    _sceneViewController.arcGISScene = scene;

    // Add a surface to the scene based on elevation data.
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );

    // Create a KML layer and add it to the scene.
    await _kmlDataset.load();
    final kmlDocument = _kmlDataset.rootNodes.first as KmlDocument;
    final kmlLayer = KmlLayer(_kmlDataset);
    scene.operationalLayers.add(kmlLayer);

    // Check if the widget is still mounted after the await before continuing.
    if (!mounted) return;

    // Set the ready state variable to true to enable the sample UI.
    setState(() {
      _kmlDocument = kmlDocument;
      _ready = true;
    });
  }

  // Function to initialize a KmlDataset based on the smaple's KML file.
  KmlDataset _initKmlDataset() {
    // Create a KML layer and add it to the scene.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final kmlFile = File(listPaths.first);
    final kmlDataset = KmlDataset(kmlFile.uri);
    return kmlDataset;
  }

  // Build function to create the collapsible list for the contents of the KML file.
  Widget _buildKmlList() {
    return _kmlDocument == null
        ? const Center(child: Text('KML dataset loading...'))
        : Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Text('Expand the KML folders to view child nodes.'),
                    Text('Tap on the nodes to view them in a scene.'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ExpansionTile(
                      title: const Text('Document'),
                      initiallyExpanded: true,
                      childrenPadding: const EdgeInsets.only(left: 16),
                      children: _kmlDocument!.childNodes
                          .map(_buildKmlNode)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  // Build function for KML leaf nodes. Clicking on these will view the item on the scene view.
  Widget _buildKmlNode(KmlNode node) {
    if (node is KmlFolder) {
      return ExpansionTile(
        title: Text(node.name),
        subtitle: Text(_getFriendlyTypeName(node)),
        childrenPadding: const EdgeInsets.only(left: 16),
        children: node.childNodes.map(_buildKmlNode).toList(),
      );
    }

    return ListTile(
      title: Text(node.name),
      subtitle: Text(_getFriendlyTypeName(node)),
      onTap: () => _onKmlNodeSelected(node).ignore(),
    );
  }

  String _getFriendlyTypeName(KmlNode node) {
    return node.runtimeType
        .toString()
        .replaceFirst(RegExp('^Kml'), '')
        .replaceAllMapped(
          RegExp('[A-Z][a-z]*'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
  }

  // Function called when a leaf node is tapped. Sets viewpoint for the selected KML node.
  Future<void> _onKmlNodeSelected(KmlNode kmlNode) async {
    Viewpoint? nodeViewpoint;

    final surface = _sceneViewController.arcGISScene?.baseSurface;
    if (surface != null) {
      nodeViewpoint = await _createViewpointForKmlNode(kmlNode, surface);
    }

    if (!mounted) return;

    if (nodeViewpoint != null) {
      // Change the viewpoint to show the item on the scene.
      _sceneViewController.setViewpointAnimated(nodeViewpoint, duration: 1);
      // Hide the bottom sheet.
      setState(() => _showBottomSheet = false);
    } else {
      // Nothing to show, so alert the user.
      showAlertDialog(
        context,
        'This node has no viewpoint or extent to view.',
        showOK: true,
      ).ignore();
    }
  }

  // Function to create a Viewpoint based on a KML node.
  Future<Viewpoint?> _createViewpointForKmlNode(
    KmlNode kmlNode,
    Surface surface,
  ) async {
    // Ensure the surface for the scene is loaded.
    if (surface.loadStatus != .loaded) {
      await surface.load();
    }

    final kmlViewpoint = kmlNode.viewpoint;
    if (kmlViewpoint != null) {
      // The node has a KML viewpoint. Get an ArcGIS Viewpoint from the KML viewpoint.
      return _createViewpointWithKmlViewpoint(kmlViewpoint, surface);
    } else if (kmlNode.extent != null) {
      // The node does not have a KML viewpoint. Build an ArcGIS Viewpoint based on the extent.
      return _createViewpointWithExtent(kmlNode.extent, surface);
    } else {
      return null;
    }
  }

  // Function to create a Viewpiont based on a KML viewpoint.
  Future<Viewpoint> _createViewpointWithKmlViewpoint(
    KmlViewpoint kmlViewpoint,
    Surface surface,
  ) async {
    final Camera viewpointCamera;

    if (kmlViewpoint.type == .lookAt) {
      var lookAtPoint = kmlViewpoint.location;
      if (kmlViewpoint.altitudeMode != .absolute) {
        // If the elevation is relative, account for the surface's elevation.
        final elevation = await surface.getElevation(kmlViewpoint.location);
        final kmlViewpointAltitude = kmlViewpoint.location.z ?? 0;
        lookAtPoint = ArcGISPoint(
          x: kmlViewpoint.location.x,
          y: kmlViewpoint.location.y,
          z: kmlViewpointAltitude + elevation,
        );
      }

      viewpointCamera = Camera.withLookAtPoint(
        lookAtPoint: lookAtPoint,
        distance: kmlViewpoint.range,
        heading: kmlViewpoint.heading,
        pitch: kmlViewpoint.pitch,
        roll: kmlViewpoint.roll,
      );
    } else {
      viewpointCamera = Camera.withLocation(
        location: kmlViewpoint.location,
        heading: kmlViewpoint.heading,
        pitch: kmlViewpoint.pitch,
        roll: kmlViewpoint.roll,
      );
    }

    // Create Viewpoint using the viewpointCamera.
    return Viewpoint.withLatLongScaleCamera(
      latitude: 0,
      longitude: 0,
      scale: 1,
      camera: viewpointCamera,
    );
  }

  // Function to create a Viewpoint based on an KML node extent.
  Future<Viewpoint?> _createViewpointWithExtent(
    Envelope? extent,
    Surface surface,
  ) async {
    if (extent == null || extent.isEmpty) return null;

    final extentCenter = extent.center;
    final elevation = await surface.getElevation(extentCenter);

    if (extent.width == 0 || extent.height == 0) {
      // If the extent is not empty, but the width and height are still zero,
      // default values (based on Google Earth) are used to create a camera.
      final centerAltitude = extentCenter.z ?? 0;
      final elevatedCenter = ArcGISPoint(
        x: extentCenter.x,
        y: extentCenter.y,
        z: centerAltitude + elevation,
      );
      final viewpointCamera = Camera.withLookAtPoint(
        lookAtPoint: elevatedCenter,
        distance: 1000,
        heading: 0,
        pitch: 45,
        roll: 0,
      );

      return Viewpoint.withLatLongScaleCamera(
        latitude: 0,
        longitude: 0,
        scale: 1,
        camera: viewpointCamera,
      );
    } else {
      final extentBuilder = EnvelopeBuilder.fromEnvelope(extent)
        ..zMax += elevation
        ..zMin += elevation
        ..expandBy(1.1);

      return Viewpoint.fromTargetExtent(extentBuilder.extent);
    }
  }
}
