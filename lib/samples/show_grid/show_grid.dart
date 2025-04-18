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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class ShowGrid extends StatefulWidget {
  const ShowGrid({super.key});

  @override
  State<ShowGrid> createState() => _ShowGridState();
}

class _ShowGridState extends State<ShowGrid> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  final _center = ArcGISPoint(
    x: -7702852.905619,
    y: 6217972.345771,
    spatialReference: SpatialReference.webMercator,
  );

  var _gridType = GridType.latitudeLongitude;
  var _gridColorType = GridColorType.red;
  var _gridLabelColorType = GridColorType.red;
  var _labelPositionType = GridLabelPositionType.allSides;
  var _labelFormatType = LatLongLabelFormatType.decimalDegrees;
  var _labelVisibility = true;

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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _showGridOptions,
                      child: const Text('Change Grid'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onMapViewReady() {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
    _mapViewController.arcGISMap = map;

    // Set the initial grid.
    _onGridChanged(_gridType);
    _onGridColorChanged(_gridColorType);
    _onLabelColorChanged(_gridLabelColorType);
    _onLabelPositionChanged(_labelPositionType);
    _onLabelVisibilityChanged(_labelVisibility);
  }

  // Change the grid based on the given value.
  void _onGridChanged(GridType gridType) {
    _gridType = gridType;

    final grid = gridType.value;
    _mapViewController.grid = grid;
    if (grid is LatitudeLongitudeGrid) {
      grid.labelFormat = LatitudeLongitudeGridLabelFormat.decimalDegrees;
      _mapViewController.setViewpointCenter(_center, scale: 23227);
    } else if (grid is UtmGrid) {
      _mapViewController.setViewpointCenter(_center, scale: 10000000);
    } else if (grid is UsngGrid || grid is MgrsGrid) {
      _mapViewController.setViewpointCenter(_center, scale: 23227);
    }
  }

  // Change the grid color based on the given value.
  void _onGridColorChanged(GridColorType colorType) {
    _gridColorType = colorType;
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      for (var i = 0; i < grid.levelCount; i++) {
        final lineSymbol = SimpleLineSymbol(color: colorType.value);
        grid.setLineSymbol(level: i, lineSymbol: lineSymbol);
      }
    }
  }

  // Change the label visibility based on the given value.
  void _onLabelVisibilityChanged(bool value) {
    _labelVisibility = value;
    if (_mapViewController.grid != null) {
      _mapViewController.grid!.labelVisibility = value;
    }
  }

  // Change the label color based on the given value.
  void _onLabelColorChanged(GridColorType colorType) {
    _gridLabelColorType = colorType;
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      for (var i = 0; i < grid.levelCount; i++) {
        final textSymbol =
            TextSymbol(
                color: colorType.value,
                size: 14,
                horizontalAlignment: HorizontalAlignment.left,
                verticalAlignment: VerticalAlignment.bottom,
              )
              ..haloColor = Colors.black
              ..haloWidth = 5.0;
        grid.setTextSymbol(level: i, textSymbol: textSymbol);
      }
    }
  }

  // Change the label format if the grid is LatitudeLongitudeGrid.
  void _onLabelFormatChanged(LatLongLabelFormatType labelFormatType) {
    _labelFormatType = labelFormatType;
    if (_mapViewController.grid is LatitudeLongitudeGrid) {
      final grid = _mapViewController.grid! as LatitudeLongitudeGrid;
      grid.labelFormat = labelFormatType.value;
    }
  }

  // Change the label position based on the given value.
  void _onLabelPositionChanged(GridLabelPositionType labelPositionType) {
    _labelPositionType = labelPositionType;
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      grid.labelPosition = labelPositionType.value;
    }
  }

  /// Show the grid options dialog.
  Future<void> _showGridOptions() async {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Grid Options'),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  GridOptions(
                    grids: MapViewGrids(
                      gridType: _gridType,
                      gridColorType: _gridColorType,
                      labelColorType: _gridLabelColorType,
                      labelPositionType: _labelPositionType,
                      labelFormatType: _labelFormatType,
                      labelVisible: _labelVisibility,
                    ),
                    onGridChanged: _onGridChanged,
                    onGridColorChanged: _onGridColorChanged,
                    onLabelColorChanged: _onLabelColorChanged,
                    onLabelPositionChanged: _onLabelPositionChanged,
                    onLabelFormatChanged: _onLabelFormatChanged,
                    onLabelVisibilityChanged: _onLabelVisibilityChanged,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

///
/// A widget that displays grid options.
///
class GridOptions extends StatefulWidget {
  const GridOptions({
    required this.grids,
    required this.onGridChanged,
    required this.onGridColorChanged,
    required this.onLabelColorChanged,
    required this.onLabelPositionChanged,
    required this.onLabelFormatChanged,
    required this.onLabelVisibilityChanged,
    super.key,
  });

  final Function(GridType) onGridChanged;
  final Function(GridColorType) onGridColorChanged;
  final Function(GridColorType) onLabelColorChanged;
  final Function(GridLabelPositionType) onLabelPositionChanged;
  final Function(LatLongLabelFormatType) onLabelFormatChanged;
  final Function(bool) onLabelVisibilityChanged;
  final MapViewGrids grids;

  @override
  State<GridOptions> createState() => _GridOptionsState();
}

class _GridOptionsState extends State<GridOptions> with SampleStateSupport {
  // Stateful variables.
  late GridType gridType;
  late GridColorType gridColorType;
  late GridColorType gridLabelColorType;
  late GridLabelPositionType labelPositionType;
  late LatLongLabelFormatType labelFormatType;

  late bool labelVisible;
  late bool isLabelFormatVisible;

  @override
  void initState() {
    super.initState();
    gridType = widget.grids.gridType;
    gridColorType = widget.grids.gridColorType;
    gridLabelColorType = widget.grids.labelColorType;
    labelPositionType = widget.grids.labelPositionType;
    labelFormatType = widget.grids.labelFormatType;
    labelVisible = widget.grids.labelVisible;
    isLabelFormatVisible = _shouldShowLabelFormat(gridType);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListBody(
        children: [
          _buildGridDropdown(),
          if (isLabelFormatVisible)
            _buildLatLongLabelFormatDropdown()
          else
            Container(),
          _buildGridColorDropdown(),
          _buildLabelColorDropdown(),
          _buildLabelPositionDropdown(),
          _buildLabelVisibilityCheckbox(),
        ],
      ),
    );
  }

  // Create a DropdownMenu widget.
  static DropdownMenu _createDropdownMenu<T>({
    required T value,
    required String labelText,
    required List<T> items,
    required Function(T) onChanged,
  }) {
    return DropdownMenu(
      width: double.infinity,
      initialSelection: value,
      onSelected: (newValue) {
        onChanged(newValue!);
      },
      label: Text(labelText),
      dropdownMenuEntries:
          items.map((value) {
            return DropdownMenuEntry(value: value, label: value.toString());
          }).toList(),
    );
  }

  DropdownMenu _buildGridDropdown() {
    return _createDropdownMenu(
      value: gridType,
      labelText: 'Grid Type',
      items: GridType.values,
      onChanged: (newGrid) {
        _changeGrid(newGrid);
        setState(() {
          gridType = newGrid;
          isLabelFormatVisible = _shouldShowLabelFormat(newGrid);
        });
      },
    );
  }

  DropdownMenu _buildLatLongLabelFormatDropdown() {
    final formField = _createDropdownMenu(
      value: labelFormatType,
      labelText: 'Label Format',
      items: LatLongLabelFormatType.values,
      onChanged: (newFormat) {
        widget.onLabelFormatChanged(newFormat);
        setState(() => labelFormatType = newFormat);
      },
    );
    return formField;
  }

  DropdownMenu _buildGridColorDropdown() {
    return _createDropdownMenu(
      value: gridColorType,
      labelText: 'Grid Color',
      items: GridColorType.values,
      onChanged: (newColor) {
        widget.onGridColorChanged(newColor);
        setState(() => gridColorType = newColor);
      },
    );
  }

  DropdownMenu _buildLabelColorDropdown() {
    return _createDropdownMenu(
      value: gridLabelColorType,
      labelText: 'Label Color',
      items: GridColorType.values,
      onChanged: (newColor) {
        widget.onLabelColorChanged(newColor);
        setState(() => gridLabelColorType = newColor);
      },
    );
  }

  DropdownMenu _buildLabelPositionDropdown() {
    return _createDropdownMenu(
      value: labelPositionType,
      labelText: 'Label Position',
      items: GridLabelPositionType.values,
      onChanged: (newLabelPosition) {
        widget.onLabelPositionChanged(newLabelPosition);
        setState(() => labelPositionType = newLabelPosition);
      },
    );
  }

  Widget _buildLabelVisibilityCheckbox() {
    return Center(
      child: CheckboxListTile(
        title: const Text('Label Visible'),
        value: labelVisible,
        onChanged: (newVisible) {
          widget.onLabelVisibilityChanged(newVisible!);
          setState(() => labelVisible = newVisible);
        },
      ),
    );
  }

  // Change the Grid and apply the current settings.
  void _changeGrid(GridType gridType) {
    widget.onGridChanged(gridType);
    widget.onLabelFormatChanged(labelFormatType);
    widget.onGridColorChanged(gridColorType);
    widget.onLabelColorChanged(gridLabelColorType);
    widget.onLabelPositionChanged(labelPositionType);
    widget.onLabelVisibilityChanged(labelVisible);
  }

  // Set the visibility of the label format dropdown based on the grid type.
  bool _shouldShowLabelFormat(GridType grid) =>
      grid == GridType.latitudeLongitude;
}

//
// A data class that holds the grid options.
//
class MapViewGrids {
  MapViewGrids({
    required this.gridType,
    required this.gridColorType,
    required this.labelColorType,
    required this.labelPositionType,
    required this.labelFormatType,
    required this.labelVisible,
  });

  final GridType gridType;
  final GridColorType gridColorType;
  final GridColorType labelColorType;
  final GridLabelPositionType labelPositionType;
  final LatLongLabelFormatType labelFormatType;
  final bool labelVisible;
}

// An enum of grid label positions.
enum GridLabelPositionType {
  allSides('AllSides', GridLabelPosition.allSides),
  center('Center', GridLabelPosition.center),
  bottomLeft('BottomLeft', GridLabelPosition.bottomLeft),
  bottomRight('BottomRight', GridLabelPosition.bottomRight),
  topLeft('TopLeft', GridLabelPosition.topLeft),
  topRight('TopRight', GridLabelPosition.topRight),
  geographic('Geographic', GridLabelPosition.geographic);

  const GridLabelPositionType(this.name, this.value);

  final String name;
  final GridLabelPosition value;

  @override
  String toString() => name;
}

// An enum of grid colors.
enum GridColorType {
  red('Red', Colors.red),
  blue('Blue', Colors.blue),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow);

  const GridColorType(this.name, this.value);

  final String name;
  final Color value;

  @override
  String toString() => name;
}

// An enum of label format types.
enum LatLongLabelFormatType {
  decimalDegrees(
    'Decimal Degrees',
    LatitudeLongitudeGridLabelFormat.decimalDegrees,
  ),
  degreesMinutesSeconds(
    'Degrees Minutes Seconds',
    LatitudeLongitudeGridLabelFormat.degreesMinutesSeconds,
  );

  const LatLongLabelFormatType(this.name, this.value);

  final String name;
  final LatitudeLongitudeGridLabelFormat value;

  @override
  String toString() => name;
}

// An enum of grid types.
enum GridType {
  latitudeLongitude('Latitude & Longitude'),
  mgrs('MGRS'),
  utm('UTM'),
  usng('USNG');

  const GridType(this.name);

  final String name;

  Grid get value {
    switch (this) {
      case GridType.latitudeLongitude:
        return LatitudeLongitudeGrid();
      case GridType.mgrs:
        return MgrsGrid();
      case GridType.utm:
        return UtmGrid();
      case GridType.usng:
        return UsngGrid();
    }
  }

  @override
  String toString() => name;
}
