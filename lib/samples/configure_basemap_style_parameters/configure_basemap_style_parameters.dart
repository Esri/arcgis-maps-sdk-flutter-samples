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

class ConfigureBasemapStyleParameters extends StatefulWidget {
  const ConfigureBasemapStyleParameters({super.key});

  @override
  State<ConfigureBasemapStyleParameters> createState() =>
      _ConfigureBasemapStyleParametersState();
}

// Represents a basemap language strategy option displayed in the UI.
class Strategy {
  const Strategy({required this.label, required this.languageStrategy});

  final String label;
  final BasemapStyleLanguageStrategy languageStrategy;
}

// Represents a specific basemap language option displayed in the UI.
class Language {
  const Language({required this.label, required this.specificLanguage});

  final String label;
  final String specificLanguage;
}

class _ConfigureBasemapStyleParametersState
    extends State<ConfigureBasemapStyleParameters>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The current selected basemap language strategy.
  var _selectedLanguageStrategy = BasemapStyleLanguageStrategy.local;

  // The selected specific language code, or an empty string to use the selected strategy.
  var _selectedSpecificLanguage = '';

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Create basemap style parameters for the selected language setting.
  final parameters = BasemapStyleParameters();

  // Available basemap language strategy options displayed in the Strategic section.
  final _strategies = [
    const Strategy(
      label: 'Default Language',
      languageStrategy: BasemapStyleLanguageStrategy.default_,
    ),
    const Strategy(
      label: 'Global',
      languageStrategy: BasemapStyleLanguageStrategy.global,
    ),
    const Strategy(
      label: 'Local',
      languageStrategy: BasemapStyleLanguageStrategy.local,
    ),
    const Strategy(
      label: 'System Locale',
      languageStrategy: BasemapStyleLanguageStrategy.applicationLocale,
    ),
  ];

  // Available specific language options that can override the selected language strategy.
  final _languages = [
    const Language(label: '🇧🇬 Bulgarian', specificLanguage: 'bg'),
    const Language(label: '🇬🇷 Greek', specificLanguage: 'el'),
    const Language(label: '🇹🇷 Turkish', specificLanguage: 'tr'),
  ];

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
                // Build the language settings menu.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _showLanguageSettings,
                    child: const Text('Language Settings'),
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

  // Creates the map and applies the initial language setting.
  void onMapViewReady() {
    // Apply the initial language settings to the basemap.
    _setBasemapLanguage();

    // Create a map with a light gray basemap style and the configured language settings.
    final map = ArcGISMap.withBasemap(
      Basemap.withStyle(BasemapStyle.arcGISLightGray, parameters: parameters),
    );

    // Start with a viewpoint around Bulgaria, Greece, and Turkey.
    map.initialViewpoint = Viewpoint.fromCenter(
      ArcGISPoint(
        x: 2640000,
        y: 4570000,
        spatialReference: SpatialReference.webMercator,
      ),
      scale: 288895.277144,
    );

    // Assign the map to the map view controller.
    _mapViewController.arcGISMap = map;

    // Enable the sample UI.
    setState(() => _ready = true);
  }

  // Applies the selected language setting to the basemap style.
  void _setBasemapLanguage() {
    // Configure the basemap style parameters using the selected language settings.
    parameters.specificLanguage = _selectedSpecificLanguage;
    if (_selectedSpecificLanguage.isEmpty) {
      parameters.languageStrategy = _selectedLanguageStrategy;
    }

    // Create and apply a new basemap using the configured parameters.
    _mapViewController.arcGISMap?.basemap = Basemap.withStyle(
      BasemapStyle.arcGISLightGray,
      parameters: parameters,
    );
  }

  // Displays a bottom sheet for selecting a language strategy or a specific language.
  Future<void> _showLanguageSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title displayed at the top of the settings panel.
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Language Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Displays the available language strategy options.
                ExpansionTile(
                  title: const Text('Strategic'),
                  children: _strategies.map((languageStrategy) {
                    // Check whether this strategy is currently selected.
                    final isSelected =
                        _selectedSpecificLanguage.isEmpty &&
                        _selectedLanguageStrategy ==
                            languageStrategy.languageStrategy;
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(languageStrategy.label),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) {
                        setState(() {
                          // Update the selected strategy and clear any specific language.
                          _selectedLanguageStrategy =
                              languageStrategy.languageStrategy;
                          _selectedSpecificLanguage = '';
                        });
                        // Apply the updated language setting.
                        _setBasemapLanguage();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),

                // Displays the available specific language options.
                ExpansionTile(
                  title: const Text('Specific'),
                  children: _languages.map((language) {
                    // Check whether this specific language is currently selected.
                    final isSelected =
                        _selectedSpecificLanguage == language.specificLanguage;
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(language.label),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) {
                        // Update the selected specific language.
                        setState(
                          () => _selectedSpecificLanguage =
                              language.specificLanguage,
                        );
                        // Apply the updated language setting.
                        _setBasemapLanguage();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
