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

class ShowGridSample extends StatefulWidget {
  const ShowGridSample({super.key});

  @override
  State<ShowGridSample> createState() => _ShowGridSampleState();
}

class _ShowGridSampleState extends State<ShowGridSample> {
  // create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  final _center = ArcGISPoint(
      x: -7702852.905619,
      y: 6217972.345771,
      spatialReference: SpatialReference.webMercator);

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

    // Set the initial grid type.
    _onGridTypeChanged(LatitudeLongitudeGrid());
    _onGridColorTypeChanged(Colors.red);
    _onLabelColorTypeChanged(Colors.red);
    _onLabelPositionTypeChanged(GridLabelPosition.allSides);
    _onLabelVisibilityChanged(true);
  }

  // Change the grid type based on the given value.
  void _onGridTypeChanged(Grid grid) {
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
  void _onGridColorTypeChanged(Color color) {
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
  void _onLabelColorTypeChanged(Color color) {
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

  // change the label position based on the given value.
  void _onLabelPositionTypeChanged(GridLabelPosition labelPosition) {
    if (_mapViewController.grid != null) {
      final grid = _mapViewController.grid!;
      grid.labelPosition = labelPosition;
    }
  }

  /// Show the grid options dialog.
  void _showGridOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Grid Options'),
          content: GridOptions(
            onGridTypeChanged: _onGridTypeChanged,
            onGridColorTypeChanged: _onGridColorTypeChanged,
            onLabelColorTypeChanged: _onLabelColorTypeChanged,
            onLabelPositionTypeChanged: _onLabelPositionTypeChanged,
            onLabelVisibilityChanged: _onLabelVisibilityChanged,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
  final Function(Grid) onGridTypeChanged;
  final Function(Color) onGridColorTypeChanged;
  final Function(Color) onLabelColorTypeChanged;
  final Function(GridLabelPosition) onLabelPositionTypeChanged;
  final Function(bool) onLabelVisibilityChanged;

  GridOptions({
    Key? key,
    required this.onGridTypeChanged,
    required this.onGridColorTypeChanged,
    required this.onLabelColorTypeChanged,
    required this.onLabelPositionTypeChanged,
    required this.onLabelVisibilityChanged,
  }) : super(key: key);

  @override
  State<GridOptions> createState() => _GridOptionsState();
}

class _GridOptionsState extends State<GridOptions> {
  final gridTypes = ['Latitude & Longitude', 'MGRS', 'UTM', 'USNG'];
  final colorTypes = ['Red', 'Blue', 'Green', 'Yellow'];
  final labelPositionTypes = [
    'AllSides',
    'BottomLeft',
    'BottomRight',
    'Center',
    'Geographic',
    'TopLeft',
    'TopRight'
  ];

  // stateful variables
  String? gridType;
  String? gridColorType;
  String? labelColorType;
  String? labelPositionType;
  bool labelVisible = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListBody(
        children: <Widget>[
          _buildGridTypeDropdown(),
          _buildGridColorTypeDropdown(),
          _buildLabelColorTypeDropdown(),
          _buildLabelPositionTypeDropdown(),
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
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: (String? newValue) {
        onChanged(newValue!);
      },
      decoration: InputDecoration(
        labelText: labelText,
      ),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  DropdownButtonFormField _buildGridTypeDropdown() {
    return _createDropdownButtonFormField(
      value: gridTypes[0],
      labelText: 'Grid Type',
      items: gridTypes,
      onChanged: (String? newValue) {
        widget.onGridTypeChanged(_getGrid(newValue!));
        setState(() => gridType = newValue);
      },
    );
  }

  DropdownButtonFormField _buildGridColorTypeDropdown() {
    return _createDropdownButtonFormField(
      value: colorTypes[0],
      labelText: 'Grid Color',
      items: colorTypes,
      onChanged: (String? newValue) {
        widget.onGridColorTypeChanged(_getSelectedColor(newValue!));
        setState(() => gridColorType = newValue);
      },
    );
  }

  DropdownButtonFormField _buildLabelColorTypeDropdown() {
    return _createDropdownButtonFormField(
      value: colorTypes[0],
      labelText: 'Label Color',
      items: colorTypes,
      onChanged: (String? newValue) {
        widget.onLabelColorTypeChanged(_getSelectedColor(newValue!));
        setState(() => labelColorType = newValue);
      },
    );
  }

  DropdownButtonFormField _buildLabelPositionTypeDropdown() {
    return _createDropdownButtonFormField(
      value: labelPositionTypes[0],
      labelText: 'Label Position',
      items: labelPositionTypes,
      onChanged: (String? newValue) {
        widget.onLabelPositionTypeChanged(_getLabelPosition(newValue!));
        setState(() => labelPositionType = newValue);
      },
    );
  }

  Widget _buildLabelVisibilityCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: labelVisible,
          onChanged: (bool? value) {
            widget.onLabelVisibilityChanged(value!);
            setState(
              () => labelVisible = value,
            );
          },
        ),
        const Text('Labels Visible')
      ],
    );
  }

  GridLabelPosition _getLabelPosition(String labelPositionType) {
    switch (labelPositionType) {
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

  Color _getSelectedColor(String colorType) {
    switch (colorType) {
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

  Grid _getGrid(String gridType) {
    switch (gridType) {
      case 'Latitude & Longitude':
        return LatitudeLongitudeGrid()
          ..labelFormat = LatitudeLongitudeGridLabelFormat.decimalDegrees;
      case 'MGRS':
        return MgrsGrid();
      case 'UTM':
        return UtmGrid();
      case 'USNG':
        return UsngGrid();
      default:
        throw Exception('Invalid grid type');
    }
  }
}
