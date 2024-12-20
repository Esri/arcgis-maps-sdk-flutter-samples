// Copyright 2024 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IdentifyFeaturesInWmsLayer extends StatefulWidget {
  const IdentifyFeaturesInWmsLayer({super.key});

  @override
  State<IdentifyFeaturesInWmsLayer> createState() =>
      _IdentifyFeaturesInWmsLayerState();
}

class _IdentifyFeaturesInWmsLayerState extends State<IdentifyFeaturesInWmsLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a WMS Layer.
  late WmsLayer _wmsLayer;
  // Create a web view controller for holding HTML content.
  final _webViewController = WebViewController();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

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
              ],
            ),
            // Display a banner with instructions.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withOpacity(0.7),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap on the map to identify features in the WMS layer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() async {
    // Create a map with a basemap and set to the map view controller.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISDarkGrayBase);
    _mapViewController.arcGISMap = map;

    // Create a URI to a WMS service showing EPA water info.
    final wmsServiceUri = Uri.parse(
      'https://watersgeo.epa.gov/arcgis/services/OWPROGRAM/SDWIS_WMERC/MapServer/WMSServer?request=GetCapabilities&service=WMS',
    );
    // Create a list of WMS layer names to display.
    final layerNames = ['4'];
    // Create a WMS Layer using the service URI and layer names, and load.
    _wmsLayer = WmsLayer.withUriAndLayerNames(
      uri: wmsServiceUri,
      layerNames: layerNames,
    );
    await _wmsLayer.load();
    // Once loaded get the extent of the layer.
    final layerExtent = _wmsLayer.fullExtent;
    // Set the viewpoint to the extent of the layer.
    if (layerExtent != null) {
      _mapViewController.setViewpoint(Viewpoint.fromTargetExtent(layerExtent));
    }
    // Add the WMS Layer to the map's operational layers.
    map.operationalLayers.add(_wmsLayer);
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset localPosition) async {
    // Prevent addtional taps until the identify operation is complete.
    setState(() => _ready = false);

    // When the map view is tapped, perform an identify operation on the WMS layer.
    final identifyLayerResult = await _mapViewController.identifyLayer(
      _wmsLayer,
      screenPoint: localPosition,
      tolerance: 12.0,
    );

    // Check if there are any features identified.
    final features =
        identifyLayerResult.geoElements.whereType<WmsFeature>().toList();
    if (features.isNotEmpty) {
      // Get the identified WMS feature.
      final identifiedWmsFeature = features.first;
      // Retrieve the feature's HTML content.
      final htmlContent = identifiedWmsFeature.attributes['HTML'] as String;
      // This particular server will produce an identify result with an empty table when there is no identified feature.
      // This sample checks for the presence of OBJECTID in the HTML, and doesn't display the result if it is missing.
      if (htmlContent.contains('OBJECTID')) {
        // Zoom into the HTML content to make it more readable.
        final zoomedHtmlContent = updateHtmlInitialScale(htmlContent);
        // Load the HTML content via the web view controller.
        await _webViewController.loadHtmlString(zoomedHtmlContent);
        // Configure a dialog that will display the results.
        showResultsDialog();
      }
    }

    // Allow additional taps.
    setState(() => _ready = true);
  }

  void showResultsDialog() {
    // Show a dialog containing a web view widget.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Identify Result',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: SizedBox(
          height: 150,
          width: MediaQuery.of(context).size.width * 0.75,
          // Create a web view widget and set the controller to provide the content.
          child: WebViewWidget(
            controller: _webViewController,
          ),
        ),
      ),
    );
  }

  // A helper method to update the initial scale of the provided HTML content to improve readability.
  String updateHtmlInitialScale(String htmlContent) {
    // Define a meta tag to set the scale.
    const metaTag = '<meta name="viewport" content="initial-scale=1"></meta>';
    // Locate the head tag.
    const headTag = '<head>';
    final index = htmlContent.indexOf(headTag);
    if (index != -1) {
      // Insert the meta tag after the head tag.
      return htmlContent.substring(0, index + headTag.length) +
          metaTag +
          htmlContent.substring(index + headTag.length);
    } else {
      // If no valid head tag found, return the original HTML.
      return htmlContent;
    }
  }
}
