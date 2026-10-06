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

import 'package:app_settings/app_settings.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:material_ui/material_ui.dart';

class UpdateLabelsAndSymbolsToScaleForVisualAccessibility
    extends StatefulWidget {
  const UpdateLabelsAndSymbolsToScaleForVisualAccessibility({super.key});

  @override
  State<UpdateLabelsAndSymbolsToScaleForVisualAccessibility> createState() =>
      _UpdateLabelsAndSymbolsToScaleForVisualAccessibilityState();
}

class _UpdateLabelsAndSymbolsToScaleForVisualAccessibilityState
    extends State<UpdateLabelsAndSymbolsToScaleForVisualAccessibility>
    with SampleStateSupport {
  // Set the unscaled restaurant symbol size in device-independent pixels.
  static const _baseSymbolSize = 24.0;

  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Store the layer and symbol used for restaurant rendering and interaction.
  FeatureLayer? _restaurantLayer;
  MultilayerPointSymbol? _restaurantSymbol;

  // Track the current symbol size and label scaling preference.
  var _symbolSize = _baseSymbolSize;
  var _applyTextScaleToLabels = true;

  // Track the loading and settings panel visibility states.
  var _loading = true;
  var _settingsVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Read the current system text scale and calculate the scaled symbol size.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final symbolSize = _baseSymbolSize * textScale;

    // Avoid updating the symbol when the calculated size has not changed.
    if (symbolSize == _symbolSize) return;

    // Store the size and apply it to the loaded restaurant symbol.
    _symbolSize = symbolSize;
    _restaurantSymbol?.size = symbolSize;
  }

  @override
  Widget build(BuildContext context) {
    // Build the map, accessibility options button, and loading indicator.
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
                    onMapViewReady: _onMapViewReady,
                    onTap: _onTap,
                  ),
                ),
                // Open the panel containing the scaling controls and values.
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _settingsVisible = true),
                  child: const Text('Accessibility Options'),
                ),
              ],
            ),
            // Display a progress indicator while the layer and symbol load.
            LoadingIndicator(visible: _loading),
          ],
        ),
      ),
      // Show the accessibility controls in a bottom sheet.
      bottomSheet: _settingsVisible ? _buildSettings(context) : null,
    );
  }

  Widget _buildSettings(BuildContext context) {
    // Get the loaded symbol and calculate values for the scaling summary.
    final symbol = _restaurantSymbol;
    final symbolScale = _symbolSize / _baseSymbolSize;
    final percent = (symbolScale * 100).round();

    // Build the legend, controls, and current scaling values.
    return BottomSheetSettings(
      title: 'Accessibility Options',
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Explain how to exercise the sample.
                const Text(
                  'Change the system text size to scale restaurant labels and symbols, then tap a restaurant to view its name and coordinates.',
                ),
                const Divider(height: 24),
                // Show which mechanism scales labels and symbols.
                Text(
                  'Scaling source',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    'Aa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text('Labels: GeoView API'),
                ),
                if (symbol != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox.square(
                      dimension: _symbolSize,
                      child: SwatchImage(
                        key: ValueKey(_symbolSize),
                        symbol: symbol,
                        width: _symbolSize,
                        height: _symbolSize,
                      ),
                    ),
                    title: const Text('Symbols: system text size'),
                  ),
                const Divider(height: 24),
                // Toggle GeoView system text scaling for feature labels.
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apply system text size to labels'),
                  value: _applyTextScaleToLabels,
                  onChanged: (value) {
                    if (value != null) _setLabelTextScale(value);
                  },
                ),
                // Open Android accessibility settings or show the iOS path.
                if (Platform.isAndroid)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.settings_accessibility),
                    label: const Text('Open system text-size settings'),
                    onPressed: () => AppSettings.openAppSettings(
                      type: AppSettingsType.accessibility,
                    ),
                  )
                else if (Platform.isIOS)
                  const Text(
                    'On iOS, open Settings > Accessibility > Display & Text Size > Larger Text.',
                  ),
                const Divider(height: 24),
                // Display the effective text scale and resulting symbol size.
                Text(
                  'Current values',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('System text size: $percent%'),
                Text(
                  _applyTextScaleToLabels
                      ? 'Labels: scaled by GeoView.useSystemTextScale'
                      : 'Labels: system text scaling is disabled',
                ),
                Text(
                  'Symbols: ${_baseSymbolSize.toStringAsFixed(0)} DIPs x $percent% = ${_symbolSize.toStringAsFixed(1)} DIPs',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onMapViewReady() async {
    // Create a map centered on the restaurants in Redlands, California.
    final map = ArcGISMap.withBasemapStyle(.arcGISLightGray)
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 34.0556,
        longitude: -117.1793,
        scale: 2500,
      );
    _mapViewController.arcGISMap = map;

    // Enable system text scaling for feature labels.
    _mapViewController.useSystemTextScale = _applyTextScaleToLabels;

    try {
      // Load the restaurant symbol from Esri's 2D point symbol web style.
      final symbolStyle = SymbolStyle.withStyleName('Esri2DPointSymbolsStyle');
      final restaurantSymbol =
          await symbolStyle.getSymbol(['restaurant']) as MultilayerPointSymbol;

      // Apply the current system text scale and retain the symbol for updates.
      restaurantSymbol.size = _symbolSize;
      _restaurantSymbol = restaurantSymbol;

      // Create a feature table from the Redlands restaurants service.
      final featureTable = ServiceFeatureTable.withUri(
        Uri.parse(
          'https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/redlands_food/FeatureServer/0',
        ),
      );

      // Create the restaurant layer and apply the symbol with a renderer.
      final restaurantLayer = FeatureLayer.withFeatureTable(featureTable)
        ..renderer = SimpleRenderer(symbol: restaurantSymbol);
      _restaurantLayer = restaurantLayer;

      // Add the restaurant layer to the map.
      map.operationalLayers.add(restaurantLayer);

      // Load the layer before configuring its labels.
      await restaurantLayer.load();

      // Create a text symbol that remains legible over the basemap.
      final textSymbol =
          TextSymbol(color: const Color.fromARGB(255, 31, 35, 40), size: 12)
            ..haloColor = Colors.white
            ..haloWidth = 2;

      // Label every restaurant with its name above the point symbol.
      final labelDefinition =
          LabelDefinition(
              labelExpression: SimpleLabelExpression(
                simpleExpression: '[name]',
              ),
              textSymbol: textSymbol,
            )
            ..deconflictionStrategy = LabelDeconflictionStrategy.none
            ..placement = LabelingPlacement.pointAboveCenter;

      // Add the label definition and enable restaurant labels.
      restaurantLayer.labelDefinitions.add(labelDefinition);
      restaurantLayer.labelsEnabled = true;
    } on Exception catch (exception) {
      // Report failures while loading the layer or web-style symbol.
      if (mounted) {
        showExceptionDialog('Error loading restaurant sample', exception);
      }
    } finally {
      // Hide the loading indicator after initialization completes.
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setLabelTextScale(bool value) {
    // Toggle system text scaling for labels without changing symbol scaling.
    _mapViewController.useSystemTextScale = value;
    setState(() => _applyTextScaleToLabels = value);
  }

  Future<void> _onTap(Offset screenPoint) async {
    // Stop when the restaurant layer is not ready for identify operations.
    final restaurantLayer = _restaurantLayer;
    if (_loading || restaurantLayer == null) return;

    // Clear the previous selection and callout before identifying a restaurant.
    restaurantLayer.clearSelection();
    _mapViewController.callout.dismiss(animated: false);

    try {
      // Identify at most one restaurant near the tapped screen position.
      final identifyResult = await _mapViewController.identifyLayer(
        restaurantLayer,
        screenPoint: screenPoint,
        tolerance: 12,
      );
      if (!mounted || identifyResult.error != null) return;

      // Get the first identified restaurant and its point geometry.
      final restaurant = identifyResult.geoElements
          .whereType<ArcGISFeature>()
          .firstOrNull;
      final restaurantLocation = restaurant?.geometry;
      if (restaurant == null || restaurantLocation is! ArcGISPoint) return;

      // Project the restaurant location to WGS 84 for the callout coordinates.
      final wgs84Location = GeometryEngine.project(
        restaurantLocation,
        outputSpatialReference: SpatialReference.wgs84,
      ) as ArcGISPoint;

      // Read the restaurant name and format its WGS 84 coordinates.
      final restaurantName = restaurant.attributes['name']?.toString().trim();
      final detail =
          'Latitude: ${wgs84Location.y.toStringAsFixed(5)}\n'
          'Longitude: ${wgs84Location.x.toStringAsFixed(5)}';

      // Select the restaurant and display its name and coordinates.
      restaurantLayer.selectFeature(restaurant);
      _mapViewController.callout.showAt(
        restaurantLocation,
        title: (restaurantName?.isNotEmpty ?? false)
            ? restaurantName!
            : 'Restaurant',
        detail: detail,
        style: ThemedCalloutStyle.themed(context),
      );
    } on Exception catch (exception) {
      // Report identify failures in the shared sample dialog.
      if (mounted) {
        showExceptionDialog('Error identifying restaurant', exception);
      }
    }
  }
}
