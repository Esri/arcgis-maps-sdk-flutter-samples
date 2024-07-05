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
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ShowGridSample extends StatefulWidget {
  const ShowGridSample({super.key});

  @override
  State<ShowGridSample> createState() => _ShowGridSampleState();
}

class _ShowGridSampleState extends State<ShowGridSample>
    with SampleStateSupport {
  // create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  final _center = ArcGISPoint(
    x: -7702852.905619,
    y: 6217972.345771,
    spatialReference: SpatialReference.webMercator,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
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
    _onGridChanged(LatitudeLongitudeGrid());
    _onGridColorChanged(Colors.red);
    _onLabelColorChanged(Colors.red);
    _onLabelPositionChanged(GridLabelPosition.allSides);
    _onLabelVisibilityChanged(true);
  }

  // Change the grid based on the given value.
  void _onGridChanged(Grid grid) {
    _mapViewController.grid = grid;
    if (grid is LatitudeLongitudeGrid) {
      grid.labelFormat = LatitudeLongitudeGridLabelFormat.decimalDegrees;
      _mapViewController.setViewpointCenter(_center, scale: 23227.0);
    } else if (grid is UtmGrid) {
      _mapViewController.setViewpointCenter(_center, scale: 10000000.0);
    } else if (grid is UsngGrid || grid is MgrsGrid) {
      _mapViewController.setViewpointCenter(_center, scale: 23227.0);
    }
  }

  // change the grid color based on the given value.
  void _onGridColorChanged(Color color) {
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      for (int i = 0; i < grid.levelCount; i++) {
        final lineSymbol = SimpleLineSymbol(
          color: color,
          width: 1.0,
          style: SimpleLineSymbolStyle.solid,
        );
        grid.setLineSymbol(level: i, lineSymbol: lineSymbol);
      }
    }
  }

  // change the label visibility based on the given value.
  void _onLabelVisibilityChanged(bool value) {
    if (_mapViewController.grid != null) {
      _mapViewController.grid!.labelVisibility = value;
    }
  }

  // change the label color based on the given value.
  void _onLabelColorChanged(Color color) {
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      for (int i = 0; i < grid.levelCount; i++) {
        final textSymbol = TextSymbol(
          color: color,
          size: 14.0,
          horizontalAlignment: HorizontalAlignment.left,
          verticalAlignment: VerticalAlignment.bottom,
        )
          ..haloColor = Colors.black
          ..haloWidth = 5.0;
        grid.setTextSymbol(level: i, textSymbol: textSymbol);
      }
    }
  }

  // change the label format if the grid is LatitudeLongitudeGrid.
  _onLabelFormatChanged(LatitudeLongitudeGridLabelFormat labelFormat) {
    if (_mapViewController.grid is LatitudeLongitudeGrid) {
      final grid = _mapViewController.grid! as LatitudeLongitudeGrid;
      grid.labelFormat = labelFormat;
    }
  }

  // change the label position based on the given value.
  void _onLabelPositionChanged(GridLabelPosition labelPosition) {
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      grid.labelPosition = labelPosition;
    }
  }

  /// Show the grid options dialog.
  Future<void> _showGridOptions() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Grid Options'),
          content: GridOptions(
            onGridChanged: _onGridChanged,
            onGridColorChanged: _onGridColorChanged,
            onLabelColorChanged: _onLabelColorChanged,
            onLabelPositionChanged: _onLabelPositionChanged,
            onLabelFormatChanged: _onLabelFormatChanged,
            onLabelVisibilityChanged: _onLabelVisibilityChanged,
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

///
/// a widget that displays grid options.
///
class GridOptions extends StatefulWidget {
  final Function(Grid) onGridChanged;
  final Function(Color) onGridColorChanged;
  final Function(Color) onLabelColorChanged;
  final Function(GridLabelPosition) onLabelPositionChanged;
  final Function(LatitudeLongitudeGridLabelFormat) onLabelFormatChanged;
  final Function(bool) onLabelVisibilityChanged;

  const GridOptions({
    super.key,
    required this.onGridChanged,
    required this.onGridColorChanged,
    required this.onLabelColorChanged,
    required this.onLabelPositionChanged,
    required this.onLabelFormatChanged,
    required this.onLabelVisibilityChanged,
  });

  @override
  State<GridOptions> createState() => _GridOptionsState();
}

class _GridOptionsState extends State<GridOptions> with SampleStateSupport {
  final grids = ['Latitude & Longitude', 'MGRS', 'UTM', 'USNG'];
  final colors = ['Red', 'Blue', 'Green', 'Yellow'];
  final labelPositions = [
    'AllSides',
    'BottomLeft',
    'BottomRight',
    'Center',
    'Geographic',
    'TopLeft',
    'TopRight'
  ];
  final latitudeLongitudeGridLabelFormats = [
    'Decimal Degrees',
    'Degrees Minutes Seconds'
  ];

  // stateful variables
  String? grid;
  String? gridColor;
  String? labelColor;
  String? labelPosition;
  String? labelFormat;
  var isLabelFormatVisible = true;
  var labelVisible = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListBody(
        children: [
          _buildGridDropdown(),
          isLabelFormatVisible
              ? _buildLatLongLabelFormatDropdown()
              : Container(),
          _buildGridColorDropdown(),
          _buildLabelColorDropdown(),
          _buildLabelPositionDropdown(),
          _buildLabelVisibilityCheckbox(),
        ],
      ),
    );
  }

  // Create a DropdownButtonFormField widget.
  static DropdownButtonFormField _createDropdownButtonFormField({
    required String value,
    required String labelText,
    required List<String> items,
    required Function onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      onChanged: (newValue) {
        onChanged(newValue!);
      },
      decoration: InputDecoration(
        labelText: labelText,
      ),
      items: items.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField _buildGridDropdown() {
    return _createDropdownButtonFormField(
      value: grid ?? grids[0],
      labelText: 'Grid Type',
      items: grids,
      onChanged: (newGrid) {
        _changeGrid(newGrid!);
        setState(() {
          grid = newGrid;
          if (grid == grids[0]) {
            isLabelFormatVisible = true;
          } else {
            isLabelFormatVisible = false;
          }
        });
      },
    );
  }

  DropdownButtonFormField _buildLatLongLabelFormatDropdown() {
    final formField = _createDropdownButtonFormField(
      value: labelFormat ?? latitudeLongitudeGridLabelFormats[0],
      labelText: 'Label Format',
      items: latitudeLongitudeGridLabelFormats,
      onChanged: (newFormat) {
        widget.onLabelFormatChanged(_getLabelFormat(newFormat));
        setState(() => labelFormat = newFormat);
      },
    );
    return formField;
  }

  DropdownButtonFormField _buildGridColorDropdown() {
    return _createDropdownButtonFormField(
      value: gridColor ?? colors[0],
      labelText: 'Grid Color',
      items: colors,
      onChanged: (newColor) {
        widget.onGridColorChanged(_getSelectedColor(newColor!));
        setState(() => gridColor = newColor);
      },
    );
  }

  DropdownButtonFormField _buildLabelColorDropdown() {
    return _createDropdownButtonFormField(
      value: labelColor ?? colors[0],
      labelText: 'Label Color',
      items: colors,
      onChanged: (newColor) {
        widget.onLabelColorChanged(_getSelectedColor(newColor!));
        setState(() => labelColor = newColor);
      },
    );
  }

  DropdownButtonFormField _buildLabelPositionDropdown() {
    return _createDropdownButtonFormField(
      value: labelPosition ?? labelPositions[0],
      labelText: 'Label Position',
      items: labelPositions,
      onChanged: (newLabelPosition) {
        widget.onLabelPositionChanged(_getLabelPosition(newLabelPosition!));
        setState(() => labelPosition = newLabelPosition);
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

  GridLabelPosition _getLabelPosition(String labelPosition) {
    switch (labelPosition) {
      case 'AllSides':
        return GridLabelPosition.allSides;
      case 'Center':
        return GridLabelPosition.center;
      case 'BottomLeft':
        return GridLabelPosition.bottomLeft;
      case 'BottomRight':
        return GridLabelPosition.bottomRight;
      case 'TopLeft':
        return GridLabelPosition.topLeft;
      case 'TopRight':
        return GridLabelPosition.topRight;
      case 'geographic':
        return GridLabelPosition.geographic;
      default:
        return GridLabelPosition.allSides;
    }
  }

  Color _getSelectedColor(String color) {
    switch (color) {
      case 'Red':
        return Colors.red;
      case 'Blue':
        return Colors.blue;
      case 'Green':
        return Colors.green;
      case 'Yellow':
        return Colors.yellow;
      default:
        return Colors.red;
    }
  }

  void _changeGrid(String gridType) {
    Grid? grid;
    switch (gridType) {
      case 'Latitude & Longitude':
        grid = LatitudeLongitudeGrid();
      case 'MGRS':
        grid = MgrsGrid();
      case 'UTM':
        grid = UtmGrid();
      case 'USNG':
        grid = UsngGrid();
      default:
        throw Exception('Invalid grid type');
    }

    // apply the current settings to the grid.
    widget.onGridChanged(grid);
    widget.onLabelFormatChanged(labelFormat != null
        ? _getLabelFormat(labelFormat!)
        : LatitudeLongitudeGridLabelFormat.decimalDegrees);
    widget.onGridColorChanged(
        gridColor != null ? _getSelectedColor(gridColor!) : Colors.red);
    widget.onLabelColorChanged(
        labelColor != null ? _getSelectedColor(labelColor!) : Colors.red);
    widget.onLabelPositionChanged(labelPosition != null
        ? _getLabelPosition(labelPosition!)
        : GridLabelPosition.allSides);
    widget.onLabelVisibilityChanged(labelVisible);
  }

  LatitudeLongitudeGridLabelFormat _getLabelFormat(String labelFormat) {
    switch (labelFormat) {
      case 'Decimal Degrees':
        return LatitudeLongitudeGridLabelFormat.decimalDegrees;
      case 'Degrees Minutes Seconds':
        return LatitudeLongitudeGridLabelFormat.degreesMinutesSeconds;
      default:
        return LatitudeLongitudeGridLabelFormat.decimalDegrees;
    }
  }
}
