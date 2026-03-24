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

class AddDynamicEntityLayer extends StatefulWidget {
  const AddDynamicEntityLayer({super.key});

  @override
  State<AddDynamicEntityLayer> createState() => _AddDynamicEntityLayerState();
}

class _AddDynamicEntityLayerState extends State<AddDynamicEntityLayer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // ValueNotifier for status text.
  final _statusTextNotifier = ValueNotifier('Status: Not Connected');

  // Connection Status Notifier

  // Dynamic entity settings state
  bool _showsTrackLine = true;
  bool _showsPreviousObservations = true;

  // Maximum observations.
  double _maximumObservations = 5;

  // Dynamic Entity objects.
  ArcGISStreamService? _streamService;
  DynamicEntityLayer? _dynamicEntityLayer;

  // Connection status (for button label and banner).
  final _connectionStatusNotifier = ValueNotifier<ConnectionStatus>(
    ConnectionStatus.disconnected,
  );

  @override
  void dispose() {
    _statusTextNotifier.dispose();
    _connectionStatusNotifier.dispose();
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
                    onTap: onTap,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Connect/Disconnect Elevated Button.
                    ValueListenableBuilder<ConnectionStatus>(
                      valueListenable: _connectionStatusNotifier,
                      builder: (context, status, _) {
                        final isConnected =
                            status == ConnectionStatus.connected;
                        final isConnecting =
                            status == ConnectionStatus.connecting;

                        return ElevatedButton(
                          onPressed: (_ready && !isConnecting)
                              ? _toggleConnection
                              : null,
                          child: Text(isConnected ? 'Disconnect' : 'Connect'),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: _ready ? _showDynamicEntitySettings : null,
                      child: const Text('Dynamic Entity Settings'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
            // Display a banner with the current status at the top.
            SafeArea(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _statusTextNotifier,
                          builder: (context, statusText, child) {
                            return Text(
                              statusText,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISStreets);
    _mapViewController.arcGISMap = map;

    // Set initial viewpoint to Sandy, Utah.
    _mapViewController.setViewpoint(
      Viewpoint.fromCenter(
        ArcGISPoint(x: -12452361.486, y: 4949774.965),
        scale: 200_000,
      ),
    );

    // Create a stream service using a simulated live data coming from snowplows near Sandy, Utah.
    final service = ArcGISStreamService.withUri(
      Uri.parse(
        'https://realtimegis2016.esri.com:6443/arcgis/rest/services/SandyVehicles/StreamServer',
      ),
    );

    // Filter incoming observations, where objects are moving i.e. speed > 0.
    final filter = ArcGISStreamServiceFilter();
    filter.whereClause = 'speed > 0';
    service.filter = filter;

    // Purge retention set to 5 minutes.
    service.purgeOptions.maximumDuration = 5 * 60;

    // Create the dynamic entity layer and add it to the map.
    final layer = DynamicEntityLayer(service);
    map.operationalLayers.add(layer);

    // Store references for settings + connect/disconnect.
    _streamService = service;
    _dynamicEntityLayer = layer;

    // Initialize UI state from layer defaults.
    // This is so that settings reflects actual layer state.
    _showsTrackLine = layer.trackDisplayProperties.showTrackLine;
    _showsPreviousObservations =
        layer.trackDisplayProperties.showPreviousObservations;
    _maximumObservations = layer.trackDisplayProperties.maximumObservations
        .toDouble();

    // Sync status banner + button label.
    _syncStatusFromService();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void onTap(Offset offset) {
    //TODO(1): Add Callout Tap.
    // Do something with a tap.
    // ignore: avoid_print
    print('Tapped at $offset');
  }

  void _syncStatusFromService() {
    final service = _streamService;
    if (service == null) {
      _connectionStatusNotifier.value = ConnectionStatus.disconnected;
      _statusTextNotifier.value = 'Status: Not Connected';
      return;
    }

    final status = service.connectionStatus;
    _connectionStatusNotifier.value = status;
    _statusTextNotifier.value = 'Status: ${status.name}';
  }

  Future<void> _toggleConnection() async {
    final service = _streamService;
    if (service == null) {
      _statusTextNotifier.value = 'Status: Stream service not initialized';
      return;
    }

    try {
      _connectionStatusNotifier.value = ConnectionStatus.connecting;
      _statusTextNotifier.value = 'Status: Connecting';

      if (service.connectionStatus == ConnectionStatus.connected) {
        await service.disconnect();
      } else {
        await service.connect();
      }
    } catch (_) {
      _connectionStatusNotifier.value = ConnectionStatus.failed;
      _statusTextNotifier.value = 'Status: Failed';
      return;
    }

    _syncStatusFromService();
  }

  // Dynamic Entity settings modal sheet.
  void _showDynamicEntitySettings() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dynamic Entity Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Toggle: Track Lines
                  SwitchListTile(
                    title: const Text('Track Lines'),
                    value: _showsTrackLine,
                    onChanged: (value) {
                      setModalState(() => _showsTrackLine = value);

                      // Apply to layer if available
                      final layer = _dynamicEntityLayer;
                      if (layer != null) {
                        layer.trackDisplayProperties.showTrackLine = value;
                      }
                    },
                  ),

                  // Toggle: Previous Observations
                  SwitchListTile(
                    title: const Text('Previous Observations'),
                    value: _showsPreviousObservations,
                    onChanged: (value) {
                      setModalState(() => _showsPreviousObservations = value);

                      final layer = _dynamicEntityLayer;
                      if (layer != null) {
                        layer.trackDisplayProperties.showPreviousObservations =
                            value;
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  // Slider: Observations per track (1-16)
                  _buildLabeledSlider(
                    label: 'Observations per track',
                    value: _maximumObservations,
                    min: 1,
                    max: 16,
                    divisions: 15,
                    onChanged: (value) {
                      setModalState(() => _maximumObservations = value);

                      final layer = _dynamicEntityLayer;
                      if (layer != null) {
                        layer.trackDisplayProperties.maximumObservations = value
                            .toInt();
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  // Purge button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Purge All Observations'),
                      onPressed: () async {
                        final service = _streamService;
                        if (service != null) {
                          try {
                            await service.purgeAll();
                          } catch (_) {
                            //TODO(2): Add Snackbar to show all observations purged
                          }
                        }

                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Builds a labeled slider widget.
  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(0)}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
