// Copyright 2025 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class FilterFeaturesInScene extends StatefulWidget {
  const FilterFeaturesInScene({super.key});

  @override
  State<FilterFeaturesInScene> createState() => _FilterFeaturesInSceneState();
}

class _FilterFeaturesInSceneState extends State<FilterFeaturesInScene>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();
  // A flag for when the scene view is ready.
  var _ready = false;

  // ArcGIS Online services.
  final _osmTopographic =
      'https://www.arcgis.com/home/item.html?id=1e7d1784d1ef4b79ba6764d0bd6c3150';
  final _elevationSource =
      'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer';
  final _sanFranciscoBuildings =
      'https://tiles.arcgis.com/tiles/z2tnIkrLQ2BRzr6P/arcgis/rest/services/SanFrancisco_Bldgs/SceneServer';

  // San Francisco buildings scene layer for the sample.
  late ArcGISSceneLayer _sfBuildingsSceneLayer;
  // Open Street Map buildings scene layer for the sample.
  late ArcGISSceneLayer _osmBuildingsSceneLayer;

  // A Graphic to get San Francisco's information.
  Graphic _sfGraphic = Graphic();
  // A Graphics overlay to present the graphic for the sample.
  final _sfGraphicsOverlay = GraphicsOverlay();
  // A Polygon geometry that represents the San Francisco buildings scene layer full extent.
  late Geometry _sceneLayerExtentPolygon;
  // A filter that limits the visible features of the scene layer.
  late SceneLayerPolygonFilter _sceneLayerPolygonFilter;
  // A state for filtering features in a scene.
  SceneFilterAction _sceneFilterAction = SceneFilterAction.filter;

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
                Center(
                  child: ElevatedButton(
                    onPressed: onSceneActionPressed,
                    child: Text(_sceneFilterAction.label),
                  ),
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

  Future<void> onSceneViewReady() async {
    final scene = _setupScene();
    _sceneViewController.arcGISScene = scene;

    // Create a scene layer for the San Francisco buildings.
    _sfBuildingsSceneLayer = ArcGISSceneLayer.withUri(
      Uri.parse(_sanFranciscoBuildings),
    );
    await _sfBuildingsSceneLayer.load();

    // Add the graphics overlay to the scene view controller.
    _sceneViewController.graphicsOverlays.add(_sfGraphicsOverlay);

    _createAndFilterPolygon();

    _addBuildings();

    setState(() => _ready = true);
  }

  ArcGISScene _setupScene() {
    // Create a scene.
    final scene = ArcGISScene();

    // Create on ArcGIS Online portal instance.
    final arcGISOnlinePortal = Portal.arcGISOnline();

    // Create the Open Street Map scene layer from the portal item.
    _osmBuildingsSceneLayer = ArcGISSceneLayer.withItem(
      PortalItem.withPortalAndItemId(
        portal: arcGISOnlinePortal,
        itemId: 'ca0470dbbddb4db28bad74ed39949e25',
      ),
    );

    // Add base layers to the basemap in the scene.
    scene.basemap?.baseLayers.addAll([
      ArcGISVectorTiledLayer.withUri(Uri.parse(_osmTopographic)),
      _osmBuildingsSceneLayer,
    ]);

    // Add surface elevation to the scene.
    final surface = Surface();
    final worldElevationService = Uri.parse(_elevationSource);
    final elevationSource = ArcGISTiledElevationSource.withUri(
      worldElevationService,
    );
    surface.elevationSources.add(elevationSource);
    scene.baseSurface = surface;

    // Create camera with an initial camera position.
    final camera = Camera.withLocation(
      location: ArcGISPoint(x: -122.421, y: 37.7041, z: 207),
      heading: 60,
      pitch: 70,
      roll: 0,
    );

    // Set the scene's initial viewpoint.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: camera,
    );

    return scene;
  }

  // Builds a polygon from the San Francisco buildings extent,
  // adds a red outline graphic, and sets up a filter for OSM buildings.
  void _createAndFilterPolygon() {
    // Build a polygon from the full extent of the San Francisco buildings layer.
    final polygonBuilder = PolygonBuilder(
      spatialReference: _sceneViewController.spatialReference,
    );
    final extent = _sfBuildingsSceneLayer.fullExtent!;
    polygonBuilder.addPointXY(x: extent.xMin, y: extent.yMin);
    polygonBuilder.addPointXY(x: extent.xMax, y: extent.yMin);
    polygonBuilder.addPointXY(x: extent.xMax, y: extent.yMax);
    polygonBuilder.addPointXY(x: extent.xMin, y: extent.yMax);

    // Convert the polygon builder to a geometry.
    _sceneLayerExtentPolygon = polygonBuilder.toGeometry();

    // Create a red outline symbol with transparent fill.
    final outlineSymbol = SimpleFillSymbol(
      color: Colors.transparent,
      outline: SimpleLineSymbol(color: Colors.red, width: 5),
    );

    // Create a graphic using the polygon geometry and symbol.
    _sfGraphic = Graphic(
      geometry: polygonBuilder.toGeometry(),
      symbol: outlineSymbol,
    );

    // Create the SceneLayerPolygonFilter to later apply to the OSM buildings layer.
    _sceneLayerPolygonFilter = SceneLayerPolygonFilter(
      polygons: [polygonBuilder.toGeometry() as Polygon],
      spatialRelationship: SceneLayerPolygonFilterSpatialRelationship.disjoint,
    );
  }

  // Filter scene based on the current filter action.
  void onSceneActionPressed() {
    switch (_sceneFilterAction) {
      case SceneFilterAction.load:
        _addBuildings();
      case SceneFilterAction.filter:
        _filterScene();
      case SceneFilterAction.reset:
        _resetScene();
    }
    setState(() => _sceneFilterAction = _sceneFilterAction.next());
  }

  // Add the San Francisco buildings scene layer and its extent graphic to the scene.
  void _addBuildings() {
    _sceneViewController.arcGISScene?.operationalLayers.add(
      _sfBuildingsSceneLayer,
    );
    _sfGraphicsOverlay.graphics.add(_sfGraphic);
  }

  // Apply a polygon filter to hide OSM buildings within the San Francisco extent.
  void _filterScene() {
    // If no filter is set, assign the polygon filter.
    if (_osmBuildingsSceneLayer.polygonFilter == null) {
      _osmBuildingsSceneLayer.polygonFilter = _sceneLayerPolygonFilter;
    }
    // If the filter exists but has no polygons, add the extent polygon.
    else {
      _sceneLayerPolygonFilter.polygons.add(
        _sceneLayerExtentPolygon as Polygon,
      );
    }
  }

  // Reset the scene by removing layers, filters, and graphics.
  void _resetScene() {
    _sceneViewController.arcGISScene!.operationalLayers.clear();
    _osmBuildingsSceneLayer.polygonFilter?.polygons.clear();
    _sfGraphicsOverlay.graphics.clear();
  }
}

// The different states for filtering features in a scene.
enum SceneFilterAction {
  load('Load detailed buildings'),
  filter('Filter OSM buildings'),
  reset('Reset scene');

  const SceneFilterAction(this.label);

  final String label;

  // The next action to apply to a scene.
  SceneFilterAction next() {
    switch (this) {
      case SceneFilterAction.load:
        return SceneFilterAction.filter;
      case SceneFilterAction.filter:
        return SceneFilterAction.reset;
      case SceneFilterAction.reset:
        return SceneFilterAction.load;
    }
  }
}
