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
import 'package:path/path.dart' as path;

class ConfigureElectronicNavigationalCharts extends StatefulWidget {
  const ConfigureElectronicNavigationalCharts({super.key});

  @override
  State<ConfigureElectronicNavigationalCharts> createState() =>
      _ConfigureElectronicNavigationalChartsState();
}

class _ConfigureElectronicNavigationalChartsState
    extends State<ConfigureElectronicNavigationalCharts>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // The ENC layers displayed in the map.
  final _encLayers = <EncLayer>[];
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A temporary directory for generated SENC data.
  Directory? _sencDataDirectory;
  // The current ENC mariner display setting values.
  var _colorScheme = EncColorScheme.day;
  var _areaSymbolizationType = EncAreaSymbolizationType.symbolized;
  var _pointSymbolizationType = EncPointSymbolizationType.paperChart;

  @override
  void dispose() {
    final environmentSettings = EncLayer.getEnvironmentSettings();

    // Reset global ENC environment paths and display settings when leaving the sample.
    environmentSettings.resourceUri = null;
    environmentSettings.sencDataUri = null;
    environmentSettings.displaySettings.marinerSettings.resetToDefaults();
    environmentSettings.displaySettings.textGroupVisibilitySettings
        .resetToDefaults();
    environmentSettings.displaySettings.viewingGroupSettings.resetToDefaults();

    // Remove the temporary SENC files created while loading ENC content.
    _sencDataDirectory?.deleteSync(recursive: true);
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
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: onTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  // A button to view the settings sheet.
                  child: ElevatedButton(
                    onPressed: _ready && _encLayers.isNotEmpty
                        ? showDisplaySettings
                        : null,
                    child: const Text('Display Settings'),
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

  Future<void> onMapViewReady() async {
    try {
      final downloadPaths = GoRouter.of(context).state.extra! as List<String>;
      final hydrographyDirectory = Directory(
        path.join(downloadPaths[0], 'hydrography'),
      );
      final exchangeSetFile = File(
        path.join(
          downloadPaths[1],
          'ExchangeSetwithoutUpdates',
          'ENC_ROOT',
          'CATALOG.031',
        ),
      );

      // Configure the ENC resource directory to point to the downloaded hydrography data, and prepare a temp directory.
      final environmentSettings = EncLayer.getEnvironmentSettings();
      _sencDataDirectory = Directory.systemTemp.createTempSync('enc_senc_');
      environmentSettings.resourceUri = hydrographyDirectory.uri;
      environmentSettings.sencDataUri = _sencDataDirectory!.uri;

      // Configure the ENC display settings before creating the ENC layers.
      configureEncDisplaySettings();

      // Create a map with an oceans basemap style.
      final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISOceans);
      map.initialViewpoint = Viewpoint.fromCenter(
        ArcGISPoint(
          x: 60.95,
          y: -32.5,
          spatialReference: SpatialReference.wgs84,
        ),
        scale: 67000,
      );
      // Set the map to the map view controller.
      _mapViewController.arcGISMap = map;

      // Create layers from the exchange set's datasets and add them to the map.
      final exchangeSet = EncExchangeSet(fileUris: [exchangeSetFile.uri]);
      await exchangeSet.load();
      _encLayers.addAll(
        exchangeSet.datasets.map((dataset) {
          final cell = EncCell.withDataset(dataset);
          return EncLayer(cell: cell);
        }),
      );
      map.operationalLayers.addAll(_encLayers);
    } on Exception catch (e) {
      showExceptionDialog('Failed to load electronic navigational charts', e);
    } finally {
      // Set the ready state variable to true to hide the loading indicator.
      setState(() => _ready = true);
    }
  }

  Future<void> onTap(Offset localPosition) async {
    if (!_ready) return;

    final tapLocation = _mapViewController.screenToLocation(
      screen: localPosition,
    );
    if (tapLocation == null) return;

    // Normalize the tap location before using it to anchor the callout.
    final normalizedTapLocation = GeometryEngine.normalizeCentralMeridian(
      tapLocation,
    );
    if (normalizedTapLocation is! ArcGISPoint) return;

    // Dismiss the previous callout and clear any previously selected ENC feature.
    _mapViewController.callout.dismiss();
    for (final encLayer in _encLayers) {
      encLayer.clearSelection();
    }

    // Identify ENC features near the tapped screen position.
    final identifyLayerResults = await _mapViewController.identifyLayers(
      screenPoint: localPosition,
      tolerance: 10,
    );
    if (!mounted) return;

    // Select the first identified ENC feature and show its acronym and description.
    final identifiedFeature = findFirstEncFeature(identifyLayerResults);
    if (identifiedFeature == null) return;

    identifiedFeature.layer.selectFeature(identifiedFeature.feature);
    final title = identifiedFeature.feature.acronym;
    final detail = identifiedFeature.feature.description;

    // Anchor the callout at the tap location instead of the ENC feature geometry.
    // Some ENC feature geometries include vertical coordinate system metadata
    // that can prevent geo-element callout anchoring from resolving correctly.
    _mapViewController.callout.showAt(
      normalizedTapLocation,
      title: title,
      detail: detail,
      style: ThemedCalloutStyle.themed(context),
    );
  }

  // Find the first ENC feature in the identify result list, including nested
  // sublayer results.
  ({EncLayer layer, EncFeature feature})? findFirstEncFeature(
    // Results returned from identifyLayers, which may include nested sublayer results.
    List<IdentifyLayerResult> identifyLayerResults,
  ) {
    for (final identifyLayerResult in identifyLayerResults) {
      final layerContent = identifyLayerResult.layerContent;

      // Find the first ENC feature identified directly on an ENC layer.
      if (layerContent is EncLayer) {
        for (final geoElement in identifyLayerResult.geoElements) {
          if (geoElement is EncFeature) {
            return (layer: layerContent, feature: geoElement);
          }
        }
      }

      // Check sublayer results because identify results can be nested.
      final sublayerFeature = findFirstEncFeature(
        identifyLayerResult.sublayerResults,
      );
      if (sublayerFeature != null) return sublayerFeature;
    }

    return null;
  }

  // Configure the initial ENC display settings for the sample.
  void configureEncDisplaySettings() {
    final displaySettings = EncLayer.getEnvironmentSettings().displaySettings;

    // Hide text groups that can make the chart display too dense for this view.
    final textGroupVisibilitySettings =
        displaySettings.textGroupVisibilitySettings;
    textGroupVisibilitySettings.geographicNames = false;
    textGroupVisibilitySettings.natureOfSeabed = false;

    // Hide selected viewing groups so the main chart symbology is easier to see.
    final viewingGroupSettings = displaySettings.viewingGroupSettings;
    viewingGroupSettings.depthContours = false;
    viewingGroupSettings.lights = false;
    viewingGroupSettings.spotSoundings = false;

    // Store the current mariner settings so the settings sheet reflects the
    // environment's initial display values.
    final marinerSettings = displaySettings.marinerSettings;
    _colorScheme = marinerSettings.colorScheme;
    _areaSymbolizationType = marinerSettings.areaSymbolizationType;
    _pointSymbolizationType = marinerSettings.pointSymbolizationType;
  }

  // Show controls for changing ENC mariner display settings.
  Future<void> showDisplaySettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Use the shared ENC mariner settings so changes apply to all ENC layers.
            final marinerSettings = EncLayer.getEnvironmentSettings()
                .displaySettings
                .marinerSettings;

            // Update both the shared ENC setting and the local sheet selection state.
            void updateSetting(VoidCallback update) {
              setState(update);
              setSheetState(() {});
            }

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                children: [
                  Text(
                    'Display Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Color Scheme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Change the S-52 color scheme for day, dusk, or night display.
                  SegmentedButton<EncColorScheme>(
                    segments: const [
                      ButtonSegment(
                        value: EncColorScheme.day,
                        label: Text('Day'),
                      ),
                      ButtonSegment(
                        value: EncColorScheme.dusk,
                        label: Text('Dusk'),
                      ),
                      ButtonSegment(
                        value: EncColorScheme.night,
                        label: Text('Night'),
                      ),
                    ],
                    selected: {_colorScheme},
                    onSelectionChanged: (selection) {
                      updateSetting(() {
                        _colorScheme = selection.first;
                        marinerSettings.colorScheme = _colorScheme;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Area Symbolization Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Switch between plain and symbolized area fills.
                  SegmentedButton<EncAreaSymbolizationType>(
                    segments: const [
                      ButtonSegment(
                        value: EncAreaSymbolizationType.plain,
                        label: Text('Plain'),
                      ),
                      ButtonSegment(
                        value: EncAreaSymbolizationType.symbolized,
                        label: Text('Symbolized'),
                      ),
                    ],
                    selected: {_areaSymbolizationType},
                    onSelectionChanged: (selection) {
                      updateSetting(() {
                        _areaSymbolizationType = selection.first;
                        marinerSettings.areaSymbolizationType =
                            _areaSymbolizationType;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Point Symbolization Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Switch between paper chart and simplified point symbols.
                  SegmentedButton<EncPointSymbolizationType>(
                    segments: const [
                      ButtonSegment(
                        value: EncPointSymbolizationType.paperChart,
                        label: Text('Paper Chart'),
                      ),
                      ButtonSegment(
                        value: EncPointSymbolizationType.simplified,
                        label: Text('Simplified'),
                      ),
                    ],
                    selected: {_pointSymbolizationType},
                    onSelectionChanged: (selection) {
                      updateSetting(() {
                        _pointSymbolizationType = selection.first;
                        marinerSettings.pointSymbolizationType =
                            _pointSymbolizationType;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
