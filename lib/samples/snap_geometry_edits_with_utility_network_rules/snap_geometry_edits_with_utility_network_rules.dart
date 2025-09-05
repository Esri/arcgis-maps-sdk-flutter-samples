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

import 'dart:async';
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SnapGeometryEditsWithUtilityNetworkRules extends StatefulWidget {
  const SnapGeometryEditsWithUtilityNetworkRules({super.key});

  @override
  State<SnapGeometryEditsWithUtilityNetworkRules> createState() =>
      _SnapGeometryEditsWithUtilityNetworkRulesState();
}

class _SnapGeometryEditsWithUtilityNetworkRulesState
    extends State<SnapGeometryEditsWithUtilityNetworkRules>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The geodatabase containing the utility network data.
  Geodatabase? _geodatabase;
  // The utility network from the geodatabase.
  late UtilityNetwork _utilityNetwork;
  // A default renderer for graphics overlays when not being used as a snap source.
  final _defaultGraphicRenderer = SimpleRenderer(
    symbol: SimpleLineSymbol(
      style: SimpleLineSymbolStyle.dash,
      color: Colors.grey,
      width: 3,
    ),
  );
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // The currently selected feature and element, if any.
  ArcGISFeature? _selectedFeature;
  UtilityElement? _selectedElement;
  // A flag for whether there are outstanding edits.
  var _canUndo = false;
  StreamSubscription<bool>? _canUndoSubscription;

  @override
  void dispose() {
    _geodatabase?.close();
    _canUndoSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: _selectedElement != null ? null : onTap,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _selectedElement == null ? null : discardEdits,
                    ),
                    const Spacer(),
                    const Text('Snap Sources'), //fixme toggle sources
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _canUndo ? saveEdits : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
          // Display a banner with instructions at the top.
          SafeArea(
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white.withValues(alpha: 0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedElement == null
                          ? 'Tap a point feature to edit'
                          : 'Group: ${_selectedElement!.assetGroup.name}, Type: ${_selectedElement!.assetType.name}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Download the Naperville utility network geodatabase.
    const downloadFileName = 'NapervilleGasUtilities';
    final appDir = await getApplicationDocumentsDirectory();
    final zipFile = File('${appDir.absolute.path}/$downloadFileName.zip');
    if (!zipFile.existsSync()) {
      await downloadSampleDataWithProgress(
        itemIds: ['0fd3a39660d54c12b05d5f81f207dffd'],
        destinationFiles: [zipFile],
      );
    }
    final geodatabaseFile = File(
      '${appDir.absolute.path}/$downloadFileName/$downloadFileName.geodatabase',
    );

    // Configure the map, centered on Naperville, IL.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreetsNight);
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: -9811055.1560284,
        y: 5131792.195025,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 10000,
    );
    map.loadSettings.featureTilingMode =
        FeatureTilingMode.enabledWithFullResolutionWhenSupported;
    _mapViewController.arcGISMap = map;

    // Add a GraphicsOverlay to be used as a snap source.
    final graphicsOverlay = GraphicsOverlay();
    graphicsOverlay.renderer = _defaultGraphicRenderer;
    final geometry = Geometry.fromJsonString(
      '{"paths":[[[-9811826.6810284462,5132074.7700250093],[-9811786.4643617794,5132440.9533583419],[-9811384.2976951133,5132354.1700250087],[-9810372.5310284477,5132360.5200250093],[-9810353.4810284469,5132066.3033583425]]],"spatialReference":{"wkid":102100,"latestWkid":3857}}',
    );
    graphicsOverlay.graphics.add(Graphic(geometry: geometry));
    _mapViewController.graphicsOverlays.add(graphicsOverlay);

    // Load the geodatabase from the downloaded file.
    final geodatabase = Geodatabase.withFileUri(geodatabaseFile.uri);
    await geodatabase.load();
    if (geodatabase.utilityNetworks.isEmpty) {
      throw Exception('No utility networks found in geodatabase');
    }
    _utilityNetwork = geodatabase.utilityNetworks.first;
    await _utilityNetwork.load();

    // Create feature layers from the geodatabase tables.
    final pipelineLayer = SubtypeFeatureLayer.withFeatureTable(
      geodatabase.getGeodatabaseFeatureTable(tableName: 'PipelineLine')!,
    );
    final deviceLayer = SubtypeFeatureLayer.withFeatureTable(
      geodatabase.getGeodatabaseFeatureTable(tableName: 'PipelineDevice')!,
    );
    final junctionLayer = SubtypeFeatureLayer.withFeatureTable(
      geodatabase.getGeodatabaseFeatureTable(tableName: 'PipelineJunction')!,
    );
    _geodatabase = geodatabase;

    // Add the layers to the map and load them.
    map.operationalLayers.addAll([pipelineLayer, deviceLayer, junctionLayer]);
    await Future.wait(map.operationalLayers.map((layer) => layer.load()));

    // Make visible the desired sublayers from the pipeline and device layers.
    final visibleSublayers = {
      'Distribution Pipe',
      'Service Pipe',
      'Excess Flow Valve',
      'Controllable Tee',
    };
    final sublayers =
        pipelineLayer.subtypeSublayers + deviceLayer.subtypeSublayers;
    for (final sublayer in sublayers) {
      sublayer.isVisible = visibleSublayers.contains(sublayer.name);
    }

    // Create and configure the geometry editor.
    final geometryEditor = GeometryEditor()
      ..snapSettings.isEnabled = true
      ..snapSettings.isFeatureSnappingEnabled = true;
    final tool = ReticleVertexTool()..style.vertexTextSymbol = null;
    geometryEditor.tool = tool;
    _canUndoSubscription = geometryEditor.onCanUndoChanged.listen((canUndo) {
      setState(() => _canUndo = canUndo);
    });
    _mapViewController.geometryEditor = geometryEditor;

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> onTap(Offset localPosition) async {
    final identifyLayersResults = await _mapViewController.identifyLayers(
      screenPoint: localPosition,
      tolerance: 12,
    );
    if (!mounted) return;

    // Look through the sublayer results for a point feature to edit.
    final pointFeatures = identifyLayersResults
        .expand((result) => result.sublayerResults)
        .expand((result) => result.geoElements)
        .whereType<ArcGISFeature>()
        .where((feature) => feature.geometry is ArcGISPoint);
    if (pointFeatures.isEmpty) return;

    // Select the first point feature found.
    final feature = pointFeatures.first;
    await selectFeature(feature);
  }

  // Clear any existing selection.
  void clearSelection() {
    if (_selectedFeature == null) return;

    final featureLayer = _selectedFeature!.featureTable?.layer as FeatureLayer?;
    if (featureLayer == null) return;

    featureLayer.clearSelection();
    featureLayer.resetFeaturesVisible();

    setState(() {
      _selectedFeature = null;
      _selectedElement = null;
    });
  }

  // Select a feature and start editing its geometry.
  Future<void> selectFeature(ArcGISFeature feature) async {
    if (!_ready) return;

    clearSelection();

    final featureLayer = feature.featureTable?.layer as FeatureLayer?;
    if (featureLayer == null) return;

    // Select this feature in its layer and hide it.
    featureLayer.selectFeature(feature);
    featureLayer.setFeatureVisible(feature: feature, visible: false);

    // Start editing this feature in the Geometry Editor.
    final geometryEditor = _mapViewController.geometryEditor!;
    final utilityElement = _utilityNetwork.createElement(
      arcGISFeature: feature,
    );
    final geometry = feature.geometry!;
    geometryEditor.startWithGeometry(geometry);
    geometryEditor.selectVertex(partIndex: 0, vertexIndex: 0);

    // Use the feature's symbol for the editor's symbols.
    final symbol = (feature.featureTable as GeodatabaseFeatureTable?)
        ?.layerInfo
        ?.drawingInfo
        ?.renderer
        ?.symbolForFeature(feature: feature);
    geometryEditor.tool.style
      ..vertexSymbol = symbol
      ..feedbackVertexSymbol = symbol
      ..selectedVertexSymbol = symbol;

    // Center the map on the feature.
    _mapViewController.setViewpointCenter(geometry.extent.center).ignore();

    // Get the snapping rules for this asset type.
    final snapRules = await SnapRules.createFromAssetType(
      utilityNetwork: _utilityNetwork,
      assetType: utilityElement.assetType,
    );

    // Configure the Geometry Editor's snapping settings to use these rules.
    geometryEditor.snapSettings.syncSourceSettingsUsingRules(
      snapRules,
      snapSourceEnablingBehavior: SnapSourceEnablingBehavior.setFromRules,
    );
    // Additionally, enable snapping to the graphics overlay.
    geometryEditor.snapSettings.sourceSettings
        .where((settings) => settings.source is GraphicsOverlay)
        .forEach((settings) => settings.isEnabled = true);

    //fixme set renderers

    // Mark this feature as selected.
    setState(() {
      _selectedFeature = feature;
      _selectedElement = utilityElement;
    });
  }

  // Stop the Geometry Editor and discard any changes made to the geometry.
  void discardEdits() {
    if (!_ready) return;

    _mapViewController.geometryEditor!.stop();

    clearSelection();
  }

  // Save the edits made to the geometry and stop the Geometry Editor.
  void saveEdits() {
    if (!_ready) return;

    final geometry = _mapViewController.geometryEditor!.stop()!;
    _selectedFeature!.geometry = geometry;
    _selectedFeature!.featureTable!.updateFeature(_selectedFeature!);

    clearSelection();
  }
}
