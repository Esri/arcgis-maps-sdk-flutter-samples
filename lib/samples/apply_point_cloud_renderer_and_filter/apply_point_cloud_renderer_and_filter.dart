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
import 'package:material_ui/material_ui.dart';

class ApplyPointCloudRendererAndFilter extends StatefulWidget {
  const ApplyPointCloudRendererAndFilter({super.key});

  @override
  State<ApplyPointCloudRendererAndFilter> createState() =>
      _ApplyPointCloudRendererAndFilterState();
}

class _ApplyPointCloudRendererAndFilterState
    extends State<ApplyPointCloudRendererAndFilter>
    with SampleStateSupport {
  // Use a local scene view because changing point cloud renderers and filters
  // is only supported in local scenes.
  final _localSceneViewController = ArcGISLocalSceneView.createController();

  // Create the point cloud layer from the Sonoma Area 1 scene service.
  final _pointCloudLayer = PointCloudLayer.withUri(
    Uri.parse(
      'https://tiles.arcgis.com/tiles/z2tnIkrLQ2BRzr6P/arcgis/rest/services/SONOMA_AREA1_LiDAR_RGB/SceneServer',
    ),
  );

  // Keep one instance of each renderer so its point size can be updated in
  // place and preserved when switching renderers.
  late final _renderers = _createRenderers();

  // Store the classification value filter when it is active.
  PointCloudValueFilter? _valueFilter;

  // Store the lidar return filter when it is active.
  PointCloudReturnFilter? _returnFilter;

  // Store the scan direction bitfield filter when it is active.
  PointCloudBitfieldFilter? _bitfieldFilter;

  // Track the renderer selected in the settings sheet.
  var _selectedRenderer = _RendererType.rgb;

  // Track the point size selected in the settings sheet.
  var _pointSize = 1.0;

  // Track whether selected classification values are included or excluded.
  var _valueFilterMode = PointCloudValueFilterMode.include;

  // Track the selected LAS classification codes.
  final _selectedClassCodes = <double>{};

  // Track the selected lidar return types.
  final _selectedReturnTypes = <PointCloudReturnType>{};

  // Track the selected scan direction condition.
  var _scanDirectionFilter = _ScanDirectionFilter.none;

  // Track whether the settings sheet is visible.
  var _settingsVisible = false;

  // Track whether the layer has loaded and the controls can be used.
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
                  // Add a local scene view and set its controller.
                  child: ArcGISLocalSceneView(
                    controllerProvider: () => _localSceneViewController,
                    onLocalSceneViewReady: onLocalSceneViewReady,
                  ),
                ),
                // Show the renderer and filter settings.
                ElevatedButton(
                  onPressed: _ready
                      ? () => setState(() => _settingsVisible = true)
                      : null,
                  child: const Text('Renderer and Filter Settings'),
                ),
              ],
            ),
            // Prevent interaction while the point cloud layer is loading.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // Display the renderer and filter controls in a settings sheet.
      bottomSheet: _settingsVisible
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: _PointCloudSettingsSheet(
                selectedRenderer: _selectedRenderer,
                pointSize: _pointSize,
                valueFilterMode: _valueFilterMode,
                selectedClassCodes: _selectedClassCodes,
                selectedReturnTypes: _selectedReturnTypes,
                scanDirectionFilter: _scanDirectionFilter,
                onRendererChanged: _updateRenderer,
                onPointSizeChanged: _updatePointSize,
                onValueFilterModeChanged: _updateValueFilterMode,
                onClassCodeChanged: _updateClassCodeFilter,
                onClearValueFilter: _clearValueFilter,
                onReturnTypeChanged: _updateReturnFilter,
                onClearReturnFilter: _clearReturnFilter,
                onScanDirectionFilterChanged: _updateBitfieldFilter,
                onClearBitfieldFilter: _clearBitfieldFilter,
                onClose: () => setState(() => _settingsVisible = false),
              ),
            )
          : null,
    );
  }

  Future<void> onLocalSceneViewReady() async {
    // Apply the custom RGB renderer before adding the layer to the scene.
    _pointCloudLayer.renderer = _renderers[_selectedRenderer];

    // Create a scene in local viewing mode to allow renderer and filter
    // changes after the point cloud layer is displayed.
    final scene = ArcGISScene.withViewingModeAndBasemapStyle(
      viewingMode: SceneViewingMode.local,
      basemapStyle: BasemapStyle.arcGISImagery,
    );

    // Position the camera above the Sonoma point cloud data.
    scene.initialViewpoint = Viewpoint.withPointScaleCamera(
      center: ArcGISPoint(x: 0, y: 0),
      scale: 1,
      camera: Camera.withLatLong(
        latitude: 38.204,
        longitude: -122.706,
        altitude: 8000,
        heading: 0,
        pitch: 45,
        roll: 0,
      ),
    );

    // Add world elevation to provide terrain beneath the point cloud.
    scene.baseSurface.elevationSources.add(
      ArcGISTiledElevationSource.withUri(
        Uri.parse(
          'https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer',
        ),
      ),
    );

    // Add the point cloud layer and display the scene in the local scene view.
    scene.operationalLayers.add(_pointCloudLayer);
    _localSceneViewController.arcGISScene = scene;

    // Load the layer before enabling renderer and filter controls.
    await _pointCloudLayer.load();
    setState(() => _ready = true);
  }

  Map<_RendererType, PointCloudRenderer> _createRenderers() {
    // Create an RGB renderer using the layer's RGB attribute.
    final rgbRenderer = PointCloudRgbRenderer(attributeName: 'RGB');

    // Create a stretch renderer using elevation color stops.
    final stretchRenderer = PointCloudStretchRenderer(
      attributeName: 'ELEVATION',
      stops: [
        PointCloudColorStop(
          color: const Color.fromARGB(255, 31, 79, 255),
          value: 0,
        ),
        PointCloudColorStop(
          color: const Color.fromARGB(255, 33, 163, 102),
          value: 30,
        ),
        PointCloudColorStop(
          color: const Color.fromARGB(255, 229, 57, 53),
          value: 90,
        ),
      ],
    );

    // Create a class breaks renderer using elevation ranges.
    final classBreaksRenderer = PointCloudClassBreaksRenderer(
      attributeName: 'ELEVATION',
      classBreaks: [
        PointCloudColorClassBreak(
          color: const Color.fromARGB(255, 96, 67, 151),
          minValue: 0,
          maxValue: 20,
        ),
        PointCloudColorClassBreak(
          color: const Color.fromARGB(255, 65, 145, 136),
          minValue: 20,
          maxValue: 40,
        ),
        PointCloudColorClassBreak(
          color: const Color.fromARGB(255, 216, 155, 77),
          minValue: 40,
          maxValue: 3.402823466e38,
        ),
      ],
    );

    // Create a unique value renderer using all standard LAS class codes.
    final classificationColors = [
      const Color.fromARGB(255, 139, 178, 194),
      const Color.fromARGB(255, 212, 223, 160),
      const Color.fromARGB(255, 168, 208, 141),
      const Color.fromARGB(255, 112, 173, 71),
      const Color.fromARGB(255, 47, 107, 47),
      const Color.fromARGB(255, 200, 62, 62),
      const Color.fromARGB(255, 187, 185, 220),
      const Color.fromARGB(255, 187, 225, 228),
      const Color.fromARGB(255, 155, 191, 177),
      const Color.fromARGB(255, 75, 85, 99),
      const Color.fromARGB(255, 107, 114, 128),
      const Color.fromARGB(255, 209, 213, 219),
      const Color.fromARGB(255, 245, 158, 11),
      const Color.fromARGB(255, 234, 179, 8),
      const Color.fromARGB(255, 124, 58, 237),
      const Color.fromARGB(255, 236, 72, 153),
      const Color.fromARGB(255, 139, 90, 43),
      const Color.fromARGB(255, 17, 24, 39),
    ];
    final uniqueValueRenderer = PointCloudUniqueValueRenderer(
      attributeName: 'CLASS_CODE',
      uniqueValues: [
        // LAS classification codes start at 1, while list indices start at 0.
        for (var index = 0; index < classificationColors.length; index++)
          PointCloudColorUniqueValue(
            color: classificationColors[index],
            values: ['${index + 1}'],
          ),
      ],
    );

    // Apply the same density and splat size settings to every renderer.
    final renderers = <_RendererType, PointCloudRenderer>{
      _RendererType.rgb: rgbRenderer,
      _RendererType.stretch: stretchRenderer,
      _RendererType.classBreaks: classBreaksRenderer,
      _RendererType.uniqueValue: uniqueValueRenderer,
    };
    for (final renderer in renderers.values) {
      renderer.pointsPerInch = 25;
      renderer.sizeAlgorithm = PointCloudSplatAlgorithm(
        scaleFactor: _pointSize,
      );
    }
    return renderers;
  }

  void _updateRenderer(_RendererType rendererType) {
    // Apply the selected renderer to the point cloud layer.
    setState(() => _selectedRenderer = rendererType);
    final renderer = _renderers[rendererType]!;

    // Synchronize the selected point size before displaying this renderer.
    final sizeAlgorithm = renderer.sizeAlgorithm;
    if (sizeAlgorithm is PointCloudSplatAlgorithm) {
      sizeAlgorithm.scaleFactor = _pointSize;
    }
    _pointCloudLayer.renderer = renderer;
  }

  void _updatePointSize(double pointSize) {
    // Update the current renderer's splat scale factor in place.
    setState(() => _pointSize = pointSize);
    final sizeAlgorithm = _pointCloudLayer.renderer?.sizeAlgorithm;
    if (sizeAlgorithm is PointCloudSplatAlgorithm) {
      sizeAlgorithm.scaleFactor = pointSize;
    }
  }

  void _updateValueFilterMode(PointCloudValueFilterMode mode) {
    // Update the value filter mode without replacing the filter.
    setState(() => _valueFilterMode = mode);
    _valueFilter?.mode = mode;
  }

  void _updateClassCodeFilter(double classCode, bool selected) {
    // Update the selected classification codes.
    setState(() {
      selected
          ? _selectedClassCodes.add(classCode)
          : _selectedClassCodes.remove(classCode);
    });

    // Create and add the value filter on first use.
    if (_valueFilter == null) {
      _valueFilter = PointCloudValueFilter(
        attributeName: 'CLASS_CODE',
        values: [],
        mode: _valueFilterMode,
      );
      _pointCloudLayer.filters.add(_valueFilter!);
    }
    _valueFilter!.values
      ..clear()
      ..addAll(_selectedClassCodes);
  }

  void _clearValueFilter() {
    // Remove only the classification value filter.
    if (_valueFilter != null) {
      _pointCloudLayer.filters.remove(_valueFilter);
      _valueFilter = null;
    }
    setState(_selectedClassCodes.clear);
  }

  void _updateReturnFilter(PointCloudReturnType returnType, bool selected) {
    // Update the selected lidar return types.
    setState(() {
      selected
          ? _selectedReturnTypes.add(returnType)
          : _selectedReturnTypes.remove(returnType);
    });

    // Remove an empty return filter because an empty filter hides all points.
    if (_selectedReturnTypes.isEmpty) {
      _clearReturnFilter();
      return;
    }

    // Create and add the return filter on first use.
    if (_returnFilter == null) {
      _returnFilter = PointCloudReturnFilter(
        attributeName: 'RETURNS',
        includedReturns: [],
      );
      _pointCloudLayer.filters.add(_returnFilter!);
    }
    _returnFilter!.includedReturns
      ..clear()
      ..addAll(_selectedReturnTypes);
  }

  void _clearReturnFilter() {
    // Remove only the lidar return filter.
    if (_returnFilter != null) {
      _pointCloudLayer.filters.remove(_returnFilter);
      _returnFilter = null;
    }
    setState(_selectedReturnTypes.clear);
  }

  void _updateBitfieldFilter(_ScanDirectionFilter scanDirectionFilter) {
    // Clear the filter when no scan direction condition is selected.
    if (scanDirectionFilter == _ScanDirectionFilter.none) {
      _clearBitfieldFilter();
      return;
    }

    // Create and add the bitfield filter on first use.
    if (_bitfieldFilter == null) {
      _bitfieldFilter = PointCloudBitfieldFilter(
        attributeName: 'FLAGS',
        requiredClearBits: [],
        requiredSetBits: [],
      );
      _pointCloudLayer.filters.add(_bitfieldFilter!);
    }

    // Require scan direction flag bit 6 to be set or clear.
    _bitfieldFilter!.requiredSetBits
      ..clear()
      ..addAll(scanDirectionFilter == _ScanDirectionFilter.set ? [6] : []);
    _bitfieldFilter!.requiredClearBits
      ..clear()
      ..addAll(scanDirectionFilter == _ScanDirectionFilter.clear ? [6] : []);
    setState(() => _scanDirectionFilter = scanDirectionFilter);
  }

  void _clearBitfieldFilter() {
    // Remove only the scan direction bitfield filter.
    if (_bitfieldFilter != null) {
      _pointCloudLayer.filters.remove(_bitfieldFilter);
      _bitfieldFilter = null;
    }
    setState(() => _scanDirectionFilter = _ScanDirectionFilter.none);
  }
}

enum _RendererType {
  rgb('RGB'),
  stretch('Stretch'),
  classBreaks('Class breaks'),
  uniqueValue('Unique value');

  const _RendererType(this.label);

  final String label;
}

enum _ScanDirectionFilter {
  none('None'),
  set('Required set'),
  clear('Required clear');

  const _ScanDirectionFilter(this.label);

  final String label;
}

class _PointCloudSettingsSheet extends StatelessWidget {
  const _PointCloudSettingsSheet({
    required this.selectedRenderer,
    required this.pointSize,
    required this.valueFilterMode,
    required this.selectedClassCodes,
    required this.selectedReturnTypes,
    required this.scanDirectionFilter,
    required this.onRendererChanged,
    required this.onPointSizeChanged,
    required this.onValueFilterModeChanged,
    required this.onClassCodeChanged,
    required this.onClearValueFilter,
    required this.onReturnTypeChanged,
    required this.onClearReturnFilter,
    required this.onScanDirectionFilterChanged,
    required this.onClearBitfieldFilter,
    required this.onClose,
  });

  // The renderer selected in the settings sheet.
  final _RendererType selectedRenderer;

  // The scale factor used to draw each point.
  final double pointSize;

  // Whether selected classification values are included or excluded.
  final PointCloudValueFilterMode valueFilterMode;

  // The selected LAS classification codes.
  final Set<double> selectedClassCodes;

  // The selected lidar return types.
  final Set<PointCloudReturnType> selectedReturnTypes;

  // The selected scan direction condition.
  final _ScanDirectionFilter scanDirectionFilter;

  // Called when a renderer is selected.
  final ValueChanged<_RendererType> onRendererChanged;

  // Called when the point size changes.
  final ValueChanged<double> onPointSizeChanged;

  // Called when the classification filter mode changes.
  final ValueChanged<PointCloudValueFilterMode> onValueFilterModeChanged;

  // Called when a classification code is selected or cleared.
  final void Function(double, bool) onClassCodeChanged;

  // Called to remove the classification value filter.
  final VoidCallback onClearValueFilter;

  // Called when a lidar return type is selected or cleared.
  final void Function(PointCloudReturnType, bool) onReturnTypeChanged;

  // Called to remove the lidar return filter.
  final VoidCallback onClearReturnFilter;

  // Called when the scan direction condition changes.
  final ValueChanged<_ScanDirectionFilter> onScanDirectionFilterChanged;

  // Called to remove the scan direction bitfield filter.
  final VoidCallback onClearBitfieldFilter;

  // Called to close the settings sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Present all renderer and filter controls in a scrollable settings sheet.
    return BottomSheetSettings(
      onCloseIconPressed: onClose,
      settingsWidgets: (context) => [
        const Text('Renderer'),
        DropdownButton<_RendererType>(
          value: selectedRenderer,
          isExpanded: true,
          items: _RendererType.values
              .map(
                (renderer) => DropdownMenuItem(
                  value: renderer,
                  child: Text(renderer.label),
                ),
              )
              .toList(),
          onChanged: (renderer) {
            if (renderer != null) onRendererChanged(renderer);
          },
        ),
        Text('Point size: ${pointSize.toStringAsFixed(1)}'),
        Slider(
          value: pointSize,
          min: 0.5,
          max: 5,
          divisions: 9,
          onChanged: onPointSizeChanged,
        ),
        const Divider(),
        const Text('Classification value filter'),
        DropdownButton<PointCloudValueFilterMode>(
          value: valueFilterMode,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: PointCloudValueFilterMode.include,
              child: Text('Include selected'),
            ),
            DropdownMenuItem(
              value: PointCloudValueFilterMode.exclude,
              child: Text('Exclude selected'),
            ),
          ],
          onChanged: (mode) {
            if (mode != null) onValueFilterModeChanged(mode);
          },
        ),
        _FilterCheckbox(
          label: 'Ground',
          value: selectedClassCodes.contains(2),
          onChanged: (selected) => onClassCodeChanged(2, selected),
        ),
        _FilterCheckbox(
          label: 'High vegetation',
          value: selectedClassCodes.contains(5),
          onChanged: (selected) => onClassCodeChanged(5, selected),
        ),
        _FilterCheckbox(
          label: 'Building',
          value: selectedClassCodes.contains(6),
          onChanged: (selected) => onClassCodeChanged(6, selected),
        ),
        TextButton(
          onPressed: onClearValueFilter,
          child: const Text('Clear value filter'),
        ),
        const Divider(),
        const Text('Lidar return filter'),
        for (final returnType in PointCloudReturnType.values)
          _FilterCheckbox(
            label: _returnTypeLabel(returnType),
            value: selectedReturnTypes.contains(returnType),
            onChanged: (selected) => onReturnTypeChanged(returnType, selected),
          ),
        TextButton(
          onPressed: onClearReturnFilter,
          child: const Text('Clear return filter'),
        ),
        const Divider(),
        const Text('Scan direction flag'),
        DropdownButton<_ScanDirectionFilter>(
          value: scanDirectionFilter,
          isExpanded: true,
          items: _ScanDirectionFilter.values
              .map(
                (filter) =>
                    DropdownMenuItem(value: filter, child: Text(filter.label)),
              )
              .toList(),
          onChanged: (filter) {
            if (filter != null) onScanDirectionFilterChanged(filter);
          },
        ),
        TextButton(
          onPressed: onClearBitfieldFilter,
          child: const Text('Clear bitfield filter'),
        ),
      ],
    );
  }

  static String _returnTypeLabel(PointCloudReturnType returnType) {
    // Convert each return type to its display label.
    return switch (returnType) {
      PointCloudReturnType.firstOfMany => 'First of many',
      PointCloudReturnType.last => 'Last',
      PointCloudReturnType.lastOfMany => 'Last of many',
      PointCloudReturnType.single => 'Single',
    };
  }
}

class _FilterCheckbox extends StatelessWidget {
  const _FilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  // The text displayed beside the checkbox.
  final String label;

  // Whether the checkbox is selected.
  final bool value;

  // Called when the checkbox selection changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Display a compact checkbox for a filter value.
    return CheckboxListTile(
      title: Text(label),
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (selected) => onChanged(selected ?? false),
    );
  }
}
