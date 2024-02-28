//
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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:async/async.dart';

class SuggestAddressSample extends StatefulWidget {
  const SuggestAddressSample({
    super.key,
    required this.title,
  });
  final String title;

  @override
  SuggestAddressSampleState createState() => SuggestAddressSampleState();
}

class SuggestAddressSampleState extends State<SuggestAddressSample> {
  final _mapViewController = ArcGISMapView.createController()
    ..arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);

  final _graphicsOverlay = GraphicsOverlay();
  final _graphic = Graphic();

  final _textEditingController = TextEditingController();
  final _locatorTask = LocatorTask.withUri(Uri.parse(
      'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer'));
  final _suggestParameters = SuggestParameters()..maxResults = 8;
  CancelableOperation<List<SuggestResult>>? _suggestOperation;
  String? _suggestAgain;
  var _suggestResults = <SuggestResult>[];

  @override
  void initState() {
    super.initState();

    ArcGISImage.fromAsset('assets/samples/pin_circle_red.png').then((image) {
      final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image);
      pictureMarkerSymbol.width = 35;
      pictureMarkerSymbol.height = 35;
      pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
      _graphicsOverlay.renderer = SimpleRenderer(symbol: pictureMarkerSymbol);
      _graphicsOverlay.graphics.add(_graphic);
      _mapViewController.graphicsOverlays.add(_graphicsOverlay);
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onTap: onTap,
          ),
          SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white,
                  child: TextField(
                    controller: _textEditingController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                    ),
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                  ),
                ),
                Visibility(
                  visible: _suggestResults.isNotEmpty,
                  child: Flexible(
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestResults.length,
                        itemBuilder: (context, index) {
                          return TextButton(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              onSuggestSelected(_suggestResults[index]);
                            },
                            style: const ButtonStyle(
                              alignment: Alignment.centerLeft,
                            ),
                            child: Text(
                              _suggestResults[index].label,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onTap(Offset localPosition) async {
    final identifyGraphicsOverlayResult =
        await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 5,
    );

    if (identifyGraphicsOverlayResult.graphics.isEmpty) return;

    if (mounted) {
      final graphic = identifyGraphicsOverlayResult.graphics.first;
      final center = graphic.geometry!.extent.center;
      final x = center.x.toStringAsFixed(3);
      final y = center.y.toStringAsFixed(3);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: Text('$x, $y'));
        },
      );
    }
  }

  void onSearchChanged(String searchText) async {
    if (searchText.isEmpty) {
      clearSuggestions();
      return;
    }

    if (_suggestOperation != null) {
      // already in progress -- remember to start another query after this one completes
      _suggestAgain = searchText;
      return;
    }

    _suggestOperation = _locatorTask.suggestCancelable(
      searchText: searchText,
      parameters: _suggestParameters,
    );

    final suggestResults = await _suggestOperation!.value;
    _suggestOperation = null;

    setState(() => _suggestResults = List.from(suggestResults));

    if (_suggestAgain != null) {
      // start again with the latest input value
      onSearchChanged(_suggestAgain!);
      _suggestAgain = null;
    }
  }

  void onSuggestSelected(SuggestResult suggestResult) async {
    clearSuggestions();

    _textEditingController.text = suggestResult.label;

    final geocodeResults =
        await _locatorTask.geocodeWithSuggestResult(suggestResult);

    if (geocodeResults.isEmpty) return;

    final geocodeResult = geocodeResults.first;
    if (geocodeResult.displayLocation != null) {
      _graphic.geometry = geocodeResult.displayLocation!;
    }
    if (geocodeResult.extent != null) {
      _mapViewController.setViewpointAnimated(
        Viewpoint.fromTargetExtent(geocodeResult.extent!),
      );
    }
  }

  void onSearchSubmitted(String searchText) async {
    // catch up with any ongoing operation
    if (_suggestAgain != null) {
      if (_suggestOperation != null) {
        _suggestOperation!.cancel();
        _suggestOperation = null;
      }
      onSearchChanged(_suggestAgain!);
      _suggestAgain = null;
    }
    await _suggestOperation?.value;

    // select the top result
    if (_suggestResults.isNotEmpty) {
      onSuggestSelected(_suggestResults.first);
    }
  }

  void clearSuggestions() {
    _suggestAgain = null;
    if (_suggestOperation != null) {
      _suggestOperation!.cancel();
      _suggestOperation = null;
    }

    setState(() {
      _suggestResults.clear();
    });
  }
}
