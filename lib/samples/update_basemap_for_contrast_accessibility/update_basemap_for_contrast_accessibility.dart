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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

enum ContrastMode { automatic, manual }

enum ContrastAppearance { light, highContrastLight, dark, highContrastDark }

class UpdateBasemapForContrastAccessibility extends StatefulWidget {
  const UpdateBasemapForContrastAccessibility({super.key});

  @override
  State<UpdateBasemapForContrastAccessibility> createState() =>
      _UpdateBasemapForContrastAccessibilityState();
}

class _UpdateBasemapForContrastAccessibilityState
    extends State<UpdateBasemapForContrastAccessibility>
    with SampleStateSupport, WidgetsBindingObserver {
  // Create a controller for the map view and a Web Mercator map.
  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap(spatialReference: SpatialReference.webMercator)
    ..initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 34.05,
      longitude: -117.19,
      scale: 2000000,
    );

  // Store the current contrast mode, appearance, and reference layer setting.
  var _contrastMode = ContrastMode.automatic;
  var _contrastAppearance = ContrastAppearance.light;
  var _referenceLayersVisible = true;

  // Track when the map is ready for interaction.
  var _ready = false;
  var _mapViewReady = false;

  @override
  void initState() {
    super.initState();

    // Observe platform brightness and accessibility feature changes.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Stop observing platform changes when the sample closes.
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-resolve automatic contrast when inherited media settings change.
    _syncAutomaticContrast();
  }

  @override
  void didChangePlatformBrightness() {
    // Re-resolve automatic contrast when the platform brightness changes.
    _syncAutomaticContrast();
  }

  @override
  void didChangeAccessibilityFeatures() {
    // Re-resolve automatic contrast when accessibility features change.
    _syncAutomaticContrast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add a map view to display the contrast-specific basemap.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          // Add controls for contrast mode, manual appearance, and reference layers.
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildControls(context),
            ),
          ),
          // Display a progress indicator while the selected basemap is loading.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Assign the map to the map view controller.
    _mapViewController.arcGISMap = _arcGISMap;
    _mapViewReady = true;

    // Apply the contrast appearance that matches the current device settings.
    await _setContrastAppearance(_automaticContrastAppearance());
  }

  Widget _buildControls(BuildContext context) {
    // Build an adaptive control panel using the current app theme.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle reference layers for the active basemap.
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reference layers'),
                value: _referenceLayersVisible,
                onChanged: _ready ? _setReferenceLayersVisible : null,
              ),
              const SizedBox(height: 12),
              // Choose whether contrast follows the device or manual controls.
              SegmentedButton<ContrastMode>(
                segments: const [
                  ButtonSegment(
                    value: ContrastMode.automatic,
                    label: Text('Automatic'),
                  ),
                  ButtonSegment(
                    value: ContrastMode.manual,
                    label: Text('Manual'),
                  ),
                ],
                selected: {_contrastMode},
                onSelectionChanged: _ready
                    ? (selection) => _setContrastMode(selection.first)
                    : null,
              ),
              if (_contrastMode == ContrastMode.manual) ...[
                const SizedBox(height: 12),
                // Choose a contrast appearance directly in manual mode.
                DropdownMenu<ContrastAppearance>(
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: _contrastAppearance,
                  label: const Text('Appearance'),
                  dropdownMenuEntries: ContrastAppearance.values
                      .map(
                        (appearance) => DropdownMenuEntry(
                          value: appearance,
                          label: appearance.label,
                        ),
                      )
                      .toList(),
                  onSelected: _ready
                      ? (appearance) {
                          if (appearance != null) {
                            _setContrastAppearance(appearance).ignore();
                          }
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setContrastMode(ContrastMode mode) {
    // Store the selected mode and resolve the effective appearance.
    setState(() => _contrastMode = mode);

    // Apply the device-driven appearance when automatic mode is selected.
    if (mode == ContrastMode.automatic) {
      _setContrastAppearance(_automaticContrastAppearance()).ignore();
    }
  }

  Future<void> _setContrastAppearance(ContrastAppearance appearance) async {
    // Avoid reloading the same basemap once the map is ready.
    if (_mapViewReady && _ready && appearance == _contrastAppearance) return;

    // Disable controls while the next basemap is loading.
    setState(() => _ready = false);

    try {
      // Create and load the basemap for the selected appearance.
      final basemap = _basemapForContrastAppearance(appearance);
      await basemap.load();

      // Apply the loaded basemap and restore the reference layer visibility.
      _arcGISMap.basemap = basemap;
      _applyReferenceLayerVisibility();

      // Store the active appearance and enable controls.
      setState(() {
        _contrastAppearance = appearance;
        _ready = true;
      });
    } on ArcGISException catch (error) {
      // Show ArcGIS load failures in the shared sample dialog.
      showMessageDialog(error.message, title: 'Error', showOK: true);
      setState(() => _ready = true);
    }
  }

  void _setReferenceLayersVisible(bool visible) {
    // Store and apply the reference layer visibility choice.
    setState(() => _referenceLayersVisible = visible);
    _applyReferenceLayerVisibility();
  }

  void _applyReferenceLayerVisibility() {
    // Update every reference layer in the current basemap.
    for (final layer in _arcGISMap.basemap?.referenceLayers ?? <Layer>[]) {
      layer.isVisible = _referenceLayersVisible;
    }
  }

  void _syncAutomaticContrast() {
    // Only synchronize automatically after the map view is ready.
    if (!_mapViewReady || _contrastMode != ContrastMode.automatic) return;

    // Apply the resolved appearance when it differs from the current one.
    final appearance = _automaticContrastAppearance();
    if (appearance != _contrastAppearance) {
      _setContrastAppearance(appearance).ignore();
    }
  }

  ContrastAppearance _automaticContrastAppearance() {
    // Read Flutter's current brightness and high-contrast settings.
    final mediaQuery = MediaQuery.of(context);
    final darkTheme = mediaQuery.platformBrightness == Brightness.dark;
    final highContrast = mediaQuery.highContrast;

    // Map device settings to the four contrast appearances.
    return switch ((darkTheme, highContrast)) {
      (true, true) => ContrastAppearance.highContrastDark,
      (true, false) => ContrastAppearance.dark,
      (false, true) => ContrastAppearance.highContrastLight,
      (false, false) => ContrastAppearance.light,
    };
  }

  Basemap _basemapForContrastAppearance(ContrastAppearance appearance) {
    // Return an authored basemap for the selected contrast appearance.
    return switch (appearance) {
      ContrastAppearance.light => Basemap.withStyle(
        BasemapStyle.arcGISLightGray,
      ),
      ContrastAppearance.dark => Basemap.withStyle(BasemapStyle.arcGISDarkGray),
      ContrastAppearance.highContrastLight => Basemap.withUri(
        Uri.parse(
          'https://www.arcgis.com/home/item.html?id=084291b0ecad4588b8c8853898d72445',
        ),
      )!,
      ContrastAppearance.highContrastDark => Basemap.withUri(
        Uri.parse(
          'https://www.arcgis.com/home/item.html?id=3e23478909194c54992eaaee78b5f754',
        ),
      )!,
    };
  }
}

extension on ContrastAppearance {
  String get label {
    // Provide a concise label for the manual appearance picker.
    return switch (this) {
      ContrastAppearance.light => 'Light',
      ContrastAppearance.highContrastLight => 'High contrast light',
      ContrastAppearance.dark => 'Dark',
      ContrastAppearance.highContrastDark => 'High contrast dark',
    };
  }
}
