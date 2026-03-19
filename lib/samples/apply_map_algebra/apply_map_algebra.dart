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
import 'package:path_provider/path_provider.dart';

class ApplyMapAlgebra extends StatefulWidget {
  const ApplyMapAlgebra({super.key});

  @override
  State<ApplyMapAlgebra> createState() => _ApplyMapAlgebraState();
}

class _ApplyMapAlgebraState extends State<ApplyMapAlgebra>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The elevation file used in the analysis.
  late File _elevationFile;

  // Raster layers to represent the original elevation raster and the results of the analysis.
  RasterLayer? _originalElevationRasterLayer;
  RasterLayer? _resultsRasterLayer;

  // A variable to manage the active raster layer.
  RasterLayer? _selectedRasterLayer;

  // Variables to manage the UI.
  var _isPerformingAnalysis = false;
  var _hasAnalysisResults = false;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    // Get the elevation data used in the sample.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    _elevationFile = File(listPaths.first);
    super.initState();
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
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                // A button to start performing the analysis.
                Visibility(
                  visible: !_hasAnalysisResults,
                  child: ElevatedButton(
                    onPressed: _isPerformingAnalysis ? null : performAnalysis,
                    child: _isPerformingAnalysis
                        ? const Text('Map algebra computing...')
                        : const Text('Categorize'),
                  ),
                ),
                // Controls for toggling the active raster layer in the map.
                Visibility(
                  visible: _hasAnalysisResults,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              // Sets the original elevation raster layer as active.
                              child: ListTile(
                                leading: Icon(
                                  _selectedRasterLayer ==
                                          _originalElevationRasterLayer
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: Colors.grey,
                                ),
                                title: const Text('Original elevation raster'),
                                dense: true,
                                onTap: () => selectRasterLayer(
                                  _originalElevationRasterLayer!,
                                ),
                              ),
                            ),
                            Expanded(
                              // Sets the results raster layer as active.
                              child: ListTile(
                                leading: Icon(
                                  _selectedRasterLayer == _resultsRasterLayer
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: Colors.grey,
                                ),
                                title: const Text('Map algebra results raster'),
                                dense: true,
                                onTap: () =>
                                    selectRasterLayer(_resultsRasterLayer!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Raster data Copyright Scottish Government and SEPA (2014)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

  Future<void> onMapViewReady() async {
    // Create a map with the hillshade dark basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISHillshadeDark);
    // Set an initial viewpoint over the Isle of Arran, Scotland.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 55.584612,
      longitude: -5.234218,
      scale: 500000,
    );

    // Create a raster from a raster elevation file.
    final raster = Raster.withFileUri(_elevationFile.uri);
    // Create a raster layer from the raster.
    _originalElevationRasterLayer = RasterLayer.withRaster(raster);

    // Create a stretch renderer to visualize the elevation raster layer using the surface preset color ramp.

    // Set up stretch parameters with min and max values of elevation data.
    final stretchParams = MinMaxStretchParameters(
      minValues: [0, 0],
      maxValues: [874.0],
    );

    // Create a color ramp with the surface type and define a size.
    final colorRamp = ColorRamp(type: PresetColorRampType.surface, size: 256);
    // Define the renderer using the parameters and color ramp.
    final stretchRenderer = StretchRenderer(
      stretchParameters: stretchParams,
      gammas: [1.0],
      estimateStatistics: false,
      colorRamp: colorRamp,
    );

    // Apply the renderer to the raster layer and apply an opacity.
    _originalElevationRasterLayer!.renderer = stretchRenderer;
    _originalElevationRasterLayer!.opacity = 0.5;
    // Add the raster layer to the map.
    map.operationalLayers.add(_originalElevationRasterLayer!);

    // Set the map to the controller.
    _mapViewController.arcGISMap = map;

    setState(() {
      // Set the elevation raster layer as the selected raster layer.
      _selectedRasterLayer = _originalElevationRasterLayer;
      // Set the ready state variable to true to enable the sample UI.
      _ready = true;
    });
  }

  // Applies the map algebra to the elevation raster and creates a new raster layer with the results.
  Future<void> performAnalysis() async {
    setState(() => _isPerformingAnalysis = true);

    // Create a continuous field from the elevation raster file.
    final elevationField = await ContinuousField.createFromFiles(
      filePaths: [_elevationFile.uri],
      band: 0,
    );

    // Create a continuous field function from the elevation field.
    final continuousFieldFunction = ContinuousFieldFunction.create(
      elevationField,
    );

    // Mask out values below sea level to categorize only land.
    final elevationFieldFunction = continuousFieldFunction.mask(
      continuousFieldFunction.isGreaterThanOrEqualToValue(0),
    );

    // Round elevation values down to the lower 10m interval, then convert to a discrete field function.
    final tenMeterBinField = ((elevationFieldFunction / 10).floor() * 10)
        .toDiscreteFieldFunction();

    // Create boolean fields for each geomorphic category based on the nearest 10m interval field.

    // Category: Raised shore line areas.
    final isRaisedShoreline = tenMeterBinField
        .isGreaterThanOrEqualToValue(0)
        .logicalAnd(tenMeterBinField.isLessThanValue(10));

    // Category: Ice covered areas.
    // Note: Operator overloads are available on some operators (e.g. /, *, +, -) to allow for more concise syntax when
    // chaining operations. Instead of using logicalAnd, & can also be used to combine boolean fields, as shown below.
    final isIceCovered =
        tenMeterBinField.isGreaterThanOrEqualToValue(10) &
        tenMeterBinField.isLessThanValue(600);

    // Category: Ice free high ground.
    final isIceFreeHighGround = tenMeterBinField.isGreaterThanOrEqualToValue(
      600,
    );

    // Assign values to the geomorphic categories and evaluate.
    // Raised shoreline=1, ice covered=2, ice-free high ground=3.
    final geomorphicCategoryField = tenMeterBinField
        .replaceWithValueIf(selection: isRaisedShoreline, value: 1)
        .replaceWithValueIf(selection: isIceCovered, value: 2)
        .replaceWithValueIf(selection: isIceFreeHighGround, value: 3);
    await geomorphicCategoryField.evaluate();

    try {
      // Export the disrete field to files in geoTIFF format.
      final tempDir = await getTemporaryDirectory();
      final dataDir = Directory('${tempDir.path}/geomorphic');
      // Clean up if the directory already exists to make the sample reusable.
      if (dataDir.existsSync()) {
        dataDir.deleteSync(recursive: true);
      }
      dataDir.createSync(recursive: true);

      final exportedFiles = await geomorphicCategoryField.exportToFiles(
        outputDirectory: dataDir.uri,
        filenamesPrefix: 'geomorphicCategorization',
      );

      if (exportedFiles.isEmpty) {
        setState(() => _isPerformingAnalysis = false);
        return;
      }

      // Use the exported raster file to create a new raster with the geomorphic categorization.
      final geomorphicCategorizationRaster = Raster.withFileUri(
        exportedFiles.first,
      );
      // Use the raster to create a raster layer for displaying the results on the map.
      _resultsRasterLayer = RasterLayer.withRaster(
        geomorphicCategorizationRaster,
      );

      // Define a renderer for the different geomorphic categories.
      final colors = <int, Color>{
        1: Colors.blue.shade600, // raised shoreline
        2: Colors.teal.shade200, // ice covered
        3: Colors.brown, // ice-free high ground
      };

      // Create a colormap renderer using the defined categories.
      final colormap = Colormap.fromValuesAndColors(colors);
      final colormapRenderer = ColormapRenderer.withColormap(colormap);

      // Set the colormap renderer to the results raster layer and apply an opacity.
      _resultsRasterLayer!.renderer = colormapRenderer;
      _resultsRasterLayer!.opacity = 0.5;
      // Add the results raster layer to the map.
      _mapViewController.arcGISMap!.operationalLayers.add(_resultsRasterLayer!);
      // Set the results raster layer as the active raster layer.
      selectRasterLayer(_resultsRasterLayer!);

      setState(() {
        // Update the sample UI.
        _isPerformingAnalysis = false;
        _hasAnalysisResults = true;
      });
    } on Exception catch (_) {
      setState(() => _isPerformingAnalysis = false);
      if (mounted) {
        await showAlertDialog(context, 'Error configuring raster file.');
      }
    }
  }

  // Sets the provided raster layer as the selected raster.
  void selectRasterLayer(RasterLayer selectedRaster) {
    // Ensure the selected raster is visible and the alternate raster is not visible.
    _originalElevationRasterLayer!.isVisible =
        selectedRaster == _originalElevationRasterLayer;
    _resultsRasterLayer!.isVisible = selectedRaster == _resultsRasterLayer;
    // Update the state with the newly selected raster.
    setState(() => _selectedRasterLayer = selectedRaster);
  }
}
