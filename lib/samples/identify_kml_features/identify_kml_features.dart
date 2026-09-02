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
import 'package:simple_html_css/simple_html_css.dart';

class IdentifyKmlFeatures extends StatefulWidget {
  const IdentifyKmlFeatures({super.key});

  @override
  State<IdentifyKmlFeatures> createState() => _IdentifyKmlFeaturesState();
}

class _IdentifyKmlFeaturesState extends State<IdentifyKmlFeatures>
    with SampleStateSupport {
  // Create a map with a dark gray basemap style.
  final _map = ArcGISMap.withBasemapStyle(.arcGISDarkGrayBase);

  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create a KML layer from the online weather forecast dataset.
  final _forecastLayer = KmlLayer(
    KmlDataset(
      Uri.parse(
        'https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx_latest.kml',
      ),
    ),
  );

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add a map view to the widget tree and set a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: _onMapViewReady,
            onTap: _onTap,
          ),
          // Prompt the user to identify a KML feature.
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Tap a weather feature to view its details.'),
                ),
              ),
            ),
          ),
          // Display a progress indicator and prevent interaction until the layer is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> _onMapViewReady() async {
    // Set the map and add the KML layer to its operational layers.
    _mapViewController.arcGISMap = _map;
    _map.operationalLayers.add(_forecastLayer);

    try {
      // Load the KML layer before enabling identify operations.
      await _forecastLayer.load();

      // Zoom to the full extent of the weather forecast.
      final fullExtent = _forecastLayer.fullExtent;
      if (fullExtent != null) {
        await _mapViewController.setViewpointGeometry(
          fullExtent,
          paddingInDiPs: 25,
        );
      }
    } on Exception catch (exception) {
      // Report a KML layer loading failure to the user.
      showExceptionDialog('Failed to load KML layer', exception);
    } finally {
      // Hide the loading indicator after the layer finishes loading.
      if (mounted) setState(() => _ready = true);
    }
  }

  Future<void> _onTap(Offset screenPoint) async {
    if (!_ready) return;

    // Dismiss any callout from a previous identify operation.
    _mapViewController.callout.dismiss(animated: false);

    try {
      // Identify the topmost geo element near the tapped screen point.
      final identifyResult = await _mapViewController.identifyLayer(
        _forecastLayer,
        screenPoint: screenPoint,
        tolerance: 22,
      );
      if (!mounted || identifyResult.error != null) return;

      // Get the first identified geo element that is a KML placemark.
      final placemark = identifyResult.geoElements
          .whereType<KmlPlacemark>()
          .firstOrNull;
      if (placemark == null) return;

      // Convert the tapped screen point to a map location for the callout anchor.
      final tapLocation = _mapViewController.screenToLocation(
        screen: screenPoint,
      );
      if (tapLocation == null) return;

      // Supply fallback text when the placemark omits its description.
      if (placemark.description.isEmpty) {
        placemark.description = 'Weather condition';
      }

      // Show the placemark's formatted balloon content in a callout.
      _mapViewController.callout.showAt(
        tapLocation,
        animated: false,
        style: ThemedCalloutStyle.themed(context),
        contentBuilder: (context, _) =>
            _buildBalloonContent(context, placemark.balloonContent),
      );
    } on Exception catch (exception) {
      // Report an identify failure to the user.
      showExceptionDialog('Failed to identify KML feature', exception);
    }
  }

  Widget _buildBalloonContent(BuildContext context, String htmlContent) {
    // Create theme-aware styles for the KML balloon's HTML content.
    final colorScheme = Theme.of(context).colorScheme;
    final defaultTextStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(color: colorScheme.onSurface);
    final overrideStyle = {
      for (final tag in const ['body', 'p', 'div', 'span', 'table', 'tr', 'td'])
        tag: TextStyle(color: colorScheme.onSurface),
      'a': TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    };

    // Convert the balloon HTML to styled Flutter text.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: SingleChildScrollView(
        child: RichText(
          text: HTML.toTextSpan(
            context,
            htmlContent,
            defaultTextStyle: defaultTextStyle,
            overrideStyle: overrideStyle,
          ),
        ),
      ),
    );
  }
}
