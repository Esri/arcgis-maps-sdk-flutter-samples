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
import 'package:go_router/go_router.dart';

class AnalyzeTerrainSuitabilityWithSlopeAndAspect extends StatefulWidget {
  const AnalyzeTerrainSuitabilityWithSlopeAndAspect({super.key});

  @override
  State<AnalyzeTerrainSuitabilityWithSlopeAndAspect> createState() =>
      _AnalyzeTerrainSuitabilityWithSlopeAndAspectState();
}

class _AnalyzeTerrainSuitabilityWithSlopeAndAspectState
    extends State<AnalyzeTerrainSuitabilityWithSlopeAndAspect>
    with SampleStateSupport {
  // Store the elevation file used to create the continuous field.
  late final File _elevationFile;

  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Track whether the settings bottom sheet is visible.
  var _settingsVisible = false;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Track whether the sample is initializing.
  var _initializing = true;

  // Track whether the active analysis is updating.
  var _showAnalysisSpinner = false;

  // Track whether the current analysis error has been reported.
  var _analysisErrorReported = false;

  // Store the selected terrain suitability scenario.
  var _selectedScenario = _SiteScenario.sheltered;

  // Store the field functions used to compose each scenario.
  late final ContinuousFieldFunction _elevationFunction;
  late final ContinuousFieldFunction _slopeFunction;
  late final ContinuousFieldFunction _aspectFunction;
  late final BooleanFieldFunction _aboveSeaLevelSelection;

  // Store the overlay and analyses used to display the results.
  late final AnalysisOverlay _analysisOverlay;
  late final FieldAnalysis _shelteredSlopesAnalysis;
  late final FieldAnalysis _exposedSlopesAnalysis;

  // Listen for changes to the analyses displayed in the map view.
  StreamSubscription<({Analysis analysis, AnalysisViewState viewState})>?
  _analysisViewStateSubscription;

  @override
  void initState() {
    // Get the downloaded elevation data provided by the sample route.
    final filePaths = GoRouter.of(context).state.extra! as List<String>;
    _elevationFile = File(filePaths.first);

    super.initState();
  }

  @override
  void dispose() {
    _analysisViewStateSubscription?.cancel().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the map, controls, attribution, and loading state.
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Show the settings bottom sheet when the button is pressed.
                    ElevatedButton(
                      onPressed: _ready
                          ? () => setState(() => _settingsVisible = true)
                          : null,
                      child: const Text('Settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Raster data Copyright Scottish Government and SEPA (2014)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            // Display a progress indicator while initialization or analysis is in progress.
            LoadingIndicator(visible: _initializing || _showAnalysisSpinner),
          ],
        ),
      ),
      bottomSheet: _settingsVisible ? _buildSettings(context) : null,
    );
  }

  Future<void> onMapViewReady() async {
    try {
      // Create a blank map in the conformal UTM30N spatial reference.
      final utm30N = SpatialReference(wkid: 32630);
      final map = ArcGISMap(spatialReference: utm30N);
      _mapViewController.arcGISMap = map;

      // Create a continuous field and project the elevation raster to UTM30N.
      final elevationField = await ContinuousField.createFromFiles(
        filePaths: [_elevationFile.uri],
        band: 0,
        spatialReference: utm30N,
      );
      if (!mounted) return;

      // Derive elevation, slope, and aspect field functions from the raster.
      _elevationFunction = ContinuousFieldFunction.create(elevationField);
      _slopeFunction = _elevationFunction.slope();
      _aspectFunction = _elevationFunction.aspect();

      // Select only land at or above sea level.
      _aboveSeaLevelSelection = _elevationFunction.isGreaterThanOrEqualToValue(
        0,
      );

      // Add an analysis overlay to display the scenario results.
      _analysisOverlay = AnalysisOverlay();
      _mapViewController.analysisOverlays.add(_analysisOverlay);

      // Create both scenario analyses once during initialization.
      _shelteredSlopesAnalysis = _createScenarioAnalysis(
        slopeMin: 0,
        slopeMax: 20,
        aspectStart: 112.5,
        aspectEnd: 247.5,
        elevationMin: 0,
        elevationMax: 300,
        color: Colors.green,
      );
      _exposedSlopesAnalysis = _createScenarioAnalysis(
        slopeMin: 20,
        slopeMax: 80,
        aspectStart: 202.5,
        aspectEnd: 67.5,
        elevationMin: 300,
        elevationMax: 850,
        color: Colors.purple,
      );

      // Listen for updates to the active analysis.
      _analysisViewStateSubscription = _mapViewController
          .onAnalysisViewStateChanged
          .listen((event) {
            if (event.analysis != _activeScenarioAnalysis || !mounted) return;

            final status = event.viewState.status;
            if (status == AnalysisViewStatus.updating) {
              _analysisErrorReported = false;
            }

            setState(() {
              _showAnalysisSpinner = status == AnalysisViewStatus.updating;
            });

            if (status == AnalysisViewStatus.error && !_analysisErrorReported) {
              _analysisErrorReported = true;
              final error = event.viewState.error;
              if (error != null) {
                showExceptionDialog(
                  'Failed to display terrain analysis',
                  error,
                );
              } else {
                showMessageDialog(
                  'Failed to display terrain analysis.',
                  title: 'Error',
                );
              }
            }
          });

      // Center the map on the projected elevation data.
      await _mapViewController.setViewpointCenter(
        elevationField.extent.center,
        scale: 200000,
      );
      if (!mounted) return;

      // Build the analyses and show the default scenario at the initial viewpoint.
      _applyScenarioVisibility();

      // Enable the sample UI and dismiss the loading indicator.
      setState(() {
        _ready = true;
        _initializing = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;

      _analysisViewStateSubscription?.cancel().ignore();
      _analysisViewStateSubscription = null;

      // Dismiss the loading indicator without enabling controls.
      setState(() {
        _initializing = false;
        _showAnalysisSpinner = false;
      });
      showExceptionDialog('Failed to initialize terrain analysis', e);
    }
  }

  // Return the analysis for the selected scenario.
  FieldAnalysis get _activeScenarioAnalysis {
    return switch (_selectedScenario) {
      _SiteScenario.sheltered => _shelteredSlopesAnalysis,
      _SiteScenario.exposed => _exposedSlopesAnalysis,
    };
  }

  void _selectScenario(_SiteScenario scenario) {
    // Update the selected scenario and show its analysis.
    setState(() {
      _selectedScenario = scenario;
      _showAnalysisSpinner = false;
      _analysisErrorReported = false;
    });
    _applyScenarioVisibility();
  }

  void _applyScenarioVisibility() {
    // Keep only the selected scenario visible.
    _shelteredSlopesAnalysis.isVisible =
        _selectedScenario == _SiteScenario.sheltered;
    _exposedSlopesAnalysis.isVisible =
        _selectedScenario == _SiteScenario.exposed;
  }

  FieldAnalysis _createScenarioAnalysis({
    required double slopeMin,
    required double slopeMax,
    required double aspectStart,
    required double aspectEnd,
    required double elevationMin,
    required double elevationMax,
    required Color color,
  }) {
    // Compose the boolean field function for the scenario ranges.
    final scenarioFunction = _createScenarioFieldFunction(
      slopeMin: slopeMin,
      slopeMax: slopeMax,
      aspectStart: aspectStart,
      aspectEnd: aspectEnd,
      elevationMin: elevationMin,
      elevationMax: elevationMax,
    );

    // Render nonmatching areas in white and matching areas in the scenario color.
    final renderer = ColormapRenderer.withColormap(
      Colormap([Colors.white, color]),
    );
    final analysis = FieldAnalysis.withBooleanFieldFunction(
      function: scenarioFunction,
      renderer: renderer,
    )..isVisible = false;

    // Add the analysis to the overlay for display.
    _analysisOverlay.analyses.add(analysis);
    return analysis;
  }

  BooleanFieldFunction _createScenarioFieldFunction({
    required double slopeMin,
    required double slopeMax,
    required double aspectStart,
    required double aspectEnd,
    required double elevationMin,
    required double elevationMax,
  }) {
    // Select slopes within the scenario range with explicit field methods.
    final slopeRangeMask = _slopeFunction
        .isGreaterThanOrEqualToValue(slopeMin)
        .logicalAnd(_slopeFunction.isLessThanOrEqualToValue(slopeMax));

    // Select aspects while accounting for ranges that cross north at zero degrees.
    // Use operator overloads to demonstrate concise map algebra composition.
    final aspectRangeMask = aspectStart <= aspectEnd
        ? (_aspectFunction >= aspectStart) & (_aspectFunction <= aspectEnd)
        : ((_aspectFunction >= aspectStart) & (_aspectFunction < 360)) |
              ((_aspectFunction >= 0) & (_aspectFunction <= aspectEnd));

    // Select elevations within the scenario range with operator overloads.
    final elevationRangeMask =
        (_elevationFunction >= elevationMin) &
        (_elevationFunction <= elevationMax);

    // Combine every range and mask out areas below sea level.
    return slopeRangeMask
        .logicalAnd(aspectRangeMask)
        .logicalAnd(elevationRangeMask)
        .mask(_aboveSeaLevelSelection);
  }

  Widget _buildSettings(BuildContext context) {
    // Build controls for choosing the visible terrain suitability scenario.
    return BottomSheetSettings(
      title: 'Terrain suitability',
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        RadioGroup<_SiteScenario>(
          groupValue: _selectedScenario,
          onChanged: (scenario) {
            if (scenario != null) _selectScenario(scenario);
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<_SiteScenario>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('Gentle, lowland south-facing slopes'),
                value: _SiteScenario.sheltered,
              ),
              RadioListTile<_SiteScenario>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('Steep, upland slopes facing west through north'),
                value: _SiteScenario.exposed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SiteScenario { sheltered, exposed }
