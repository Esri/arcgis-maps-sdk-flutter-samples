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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class CreateSymbolStylesFromWebStyles extends StatefulWidget {
  const CreateSymbolStylesFromWebStyles({super.key});

  @override
  State<CreateSymbolStylesFromWebStyles> createState() =>
      _CreateSymbolStylesFromWebStylesState();
}

class _CreateSymbolStylesFromWebStylesState
    extends State<CreateSymbolStylesFromWebStyles>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A feature layer with the LA County points of interest service.
  late final FeatureLayer _featureLayer;

  // The list of legend items shown in the legend sheet.
  final _legendItems = <_LegendItem>[];

  // A subscription used to react to map scale changes.
  StreamSubscription<double>? _scaleChangedSubscription;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // A flag for when the legend bottom sheet is visible.
  var _legendVisible = false;

  @override
  void dispose() {
    _scaleChangedSubscription?.cancel().ignore();
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
                  ),
                ),
                Row(
                  mainAxisAlignment: .spaceEvenly,
                  children: [
                    // Show a legend sheet listing the symbol swatches and names.
                    ElevatedButton(
                      onPressed: () => setState(() => _legendVisible = true),
                      child: const Text('Legend'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // Show the legend as a bottom sheet when the legend button is pressed.
      bottomSheet: _legendVisible ? _buildLegendSheet(context) : null,
    );
  }

  Widget _buildLegendSheet(BuildContext context) {
    return BottomSheetSettings(
      title: 'Symbol Styles',
      onCloseIconPressed: () => setState(() => _legendVisible = false),
      settingsWidgets: (context) => [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _legendItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _legendItems[index];
              return ListTile(
                leading: SwatchImage(
                  symbol: item.symbol,
                  width: 24,
                  height: 24,
                ),
                title: Text(item.name),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a light gray basemap and a fixed reference scale.
    final map = ArcGISMap.withBasemapStyle(.arcGISLightGray)
      ..referenceScale = 1e5
      ..initialViewpoint = Viewpoint.withLatLongScale(
        latitude: 34.28301,
        longitude: -118.44186,
        scale: 10000,
      );

    // Add the LA County Points of Interest feature layer to the map.
    _featureLayer = FeatureLayer.withFeatureTable(
      ServiceFeatureTable.withUri(
        Uri.parse(
          'https://services.arcgis.com/V6ZHFr6zdgNZuVG0/arcgis/rest/services/LA_County_Points_of_Interest/FeatureServer/0',
        ),
      ),
    );
    map.operationalLayers.add(_featureLayer);
    _mapViewController.arcGISMap = map;

    // Prevent symbols from scaling when zoomed out too far.
    _scaleChangedSubscription = _mapViewController.onScaleChanged.listen((
      scale,
    ) {
      _featureLayer.scaleSymbols = scale >= 8e4;
    });

    // Load the legend information.
    await _loadLegend();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> _loadLegend() async {
    try {
      // Load the "Esri2DPointSymbolsStyle" web style from ArcGIS Online.
      final symbolStyle = SymbolStyle.withStyleName('Esri2DPointSymbolsStyle');

      // For each symbol type, prepare the symbol and associated category names.
      final symbolDetails = await Future.wait(
        _SymbolType.values.map((type) async {
          final symbol = await symbolStyle.getSymbol([type.symbolName]);
          return _SymbolDetail(
            name: type.symbolName,
            categoryNames: type.categoryNames,
            symbol: symbol,
          );
        }),
      );

      // Create a unique value renderer to render the symbols.
      final uniqueValues = <UniqueValue>[];
      for (final detail in symbolDetails) {
        for (final category in detail.categoryNames) {
          uniqueValues.add(
            UniqueValue(
              label: detail.name,
              symbol: detail.symbol,
              values: [category],
            ),
          );
        }
      }
      final renderer = UniqueValueRenderer(
        fieldNames: const ['cat2'],
        uniqueValues: uniqueValues,
      );

      // Set the renderer on the feature layer to apply the symbols to the map.
      _featureLayer.renderer = renderer;

      // Create legend items of each symbol for display in the legend sheet.
      final legendItems = symbolDetails
          .map(
            (symbolDetail) => _LegendItem(
              name: symbolDetail.name,
              symbol: symbolDetail.symbol,
            ),
          )
          .toList();
      legendItems.sort((a, b) => a.name.compareTo(b.name));
      _legendItems.addAll(legendItems);
    } on Exception catch (e) {
      showExceptionDialog('Error updating symbols', e);
    }
  }
}

// A class containing a symbol and associated category mappings.
final class _SymbolDetail {
  const _SymbolDetail({
    required this.name,
    required this.categoryNames,
    required this.symbol,
  });

  final String name;
  final List<String> categoryNames;
  final ArcGISSymbol symbol;
}

// A class describing an item shown in the legend list.
final class _LegendItem {
  const _LegendItem({required this.name, required this.symbol});

  final String name;
  final ArcGISSymbol symbol;
}

// The symbol categories represented in the points of interest dataset.
enum _SymbolType {
  atm(symbolName: 'atm', categoryNames: ['Banking and Finance']),
  beach(symbolName: 'beach', categoryNames: ['Beaches and Marinas']),
  campground(symbolName: 'campground', categoryNames: ['Campgrounds']),
  cityHall(
    symbolName: 'city-hall',
    categoryNames: ['City Halls', 'Government Offices'],
  ),
  hospital(
    symbolName: 'hospital',
    categoryNames: [
      'Hospitals and Medical Centers',
      'Health Screening and Testing',
      'Health Centers',
      'Mental Health Centers',
    ],
  ),
  library(symbolName: 'library', categoryNames: ['Libraries']),
  park(symbolName: 'park', categoryNames: ['Parks and Gardens']),
  placeOfWorship(symbolName: 'place-of-worship', categoryNames: ['Churches']),
  policeStation(
    symbolName: 'police-station',
    categoryNames: ['Sheriff and Police Stations'],
  ),
  postOffice(
    symbolName: 'post-office',
    categoryNames: ['DHL Locations', 'Federal Express Locations'],
  ),
  school(
    symbolName: 'school',
    categoryNames: [
      'Public High Schools',
      'Public Elementary Schools',
      'Private and Charter Schools',
    ],
  ),
  trail(symbolName: 'trail', categoryNames: ['Trails']);

  const _SymbolType({required this.symbolName, required this.categoryNames});

  final String symbolName;
  final List<String> categoryNames;
}
