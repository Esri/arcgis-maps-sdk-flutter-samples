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
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class CreateAndSaveMap extends StatefulWidget {
  const CreateAndSaveMap({super.key});

  @override
  State<CreateAndSaveMap> createState() => _CreateAndSaveMapState();
}

//fixme sync up readme

// A convenience class to record the selection state of a map layer.
class LayerRecord {
  LayerRecord({required this.layer});

  final ArcGISMapImageLayer layer;
  bool selected = false;
}

class _CreateAndSaveMapState extends State<CreateAndSaveMap>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The map that will be created and saved.
  ArcGISMap? _map;

  // The portal to save to.
  final _portal = Portal.arcGISOnline(connection: .authenticated);

  // Create an OAuthUserConfiguration.
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/security-and-authentication/user-authentication/flows/authorization-code-with-pkce/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );
  // Set aside the API Key so that it does not interfere with portal authentication.
  late String _rememberedApiKey;

  // Layers that can be added to the map.
  final _layerRecords = [
    LayerRecord(
      layer: ArcGISMapImageLayer.withUri(
        Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer',
        ),
      ),
    ),
    LayerRecord(
      layer: ArcGISMapImageLayer.withUri(
        Uri.parse(
          'https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer',
        ),
      ),
    ),
  ];

  // Controllers to capture title, tags, and description.
  final _titleController = TextEditingController(text: 'My web map');
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Folders from the portal where the map can be saved.
  var _folders = <PortalFolder>[];
  PortalFolder? _selectedFolder;

  // Available basemap styles.
  static const _basemapStyles = <BasemapStyle>[
    .arcGISStreets,
    .arcGISImagery,
    .arcGISTopographic,
    .arcGISOceans,
  ];
  var _selectedBasemapStyle = _basemapStyles.first;

  // A flag to indicate whether the settings bottom sheet is visible.
  var _settingsVisible = false;

  // A flag to indicate whether the map view is ready.
  var _ready = false;

  @override
  void initState() {
    super.initState();

    // Set aside the API Key so that portal authentication is used.
    _rememberedApiKey = ArcGISEnvironment.apiKey;
    ArcGISEnvironment.apiKey = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();

    // Revoke OAuth tokens and remove all credentials to log out.
    Authenticator.revokeOAuthTokens()
        .catchError((Object error) {
          // This sample has been disposed, so we can only report errors to the console.
          // ignore: avoid_print
          print('Error revoking tokens: $error');
        })
        .whenComplete(Authenticator.clearCredentials)
        .ignore();

    // Restore the API Key.
    ArcGISEnvironment.apiKey = _rememberedApiKey;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add an Authenticator to handle authentication challenges.
                  child: Authenticator(
                    // Provide the OAuthUserConfiguration to the Authenticator.
                    oAuthUserConfigurations: [_oauthUserConfiguration],
                    // Add a map view to the widget tree and set a controller.
                    child: ArcGISMapView(
                      controllerProvider: () => _mapViewController,
                      onMapViewReady: onMapViewReady,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to show the Settings bottom sheet.
                    ElevatedButton(
                      onPressed: _map != null
                          ? () => setState(() => _settingsVisible = true)
                          : null,
                      child: const Text('Settings'),
                    ),
                    // A button to save the configured map to the portal.
                    ElevatedButton(
                      onPressed: _map != null ? _saveMap : null,
                      child: const Text('Save to Portal'),
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
      // The Settings bottom sheet.
      bottomSheet: _settingsVisible ? _buildSettings(context) : null,
    );
  }

  Future<void> onMapViewReady() async {
    try {
      // Load the portal, which will trigger the authentication process.
      await _portal.load();

      // Create a map using the selected basemap style.
      _map = ArcGISMap.withBasemapStyle(_selectedBasemapStyle);

      // Add the map to the map view.
      _mapViewController.arcGISMap = _map;

      // Fetch the user's content from the portal.
      final content = await _portal.user!.fetchContent();

      if (!mounted) return;

      // Set the available folders to select from in the settings.
      setState(() {
        _folders = content.folders;
        _selectedFolder = _folders.firstOrNull;
      });
    } on ArcGISException catch (e) {
      if (!mounted) return;

      showExceptionDialog('Portal sign-in failed', e);
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Widget _buildSettings(BuildContext context) {
    return BottomSheetSettings(
      title: 'Settings',
      onCloseIconPressed: () => setState(() => _settingsVisible = false),
      settingsWidgets: (context) => [
        // A dropdown to select the basemap style.
        DropdownButtonFormField(
          initialValue: _selectedBasemapStyle,
          decoration: const InputDecoration(labelText: 'Basemap'),
          items: _basemapStyles
              .map(
                (style) =>
                    DropdownMenuItem(value: style, child: Text(style.name)),
              )
              .toList(),
          onChanged: (style) => style != null ? _updateBasemap(style) : null,
        ),
        // Checkboxes to select operational layers.
        for (final layerRecord in _layerRecords)
          CheckboxListTile(
            title: Text(layerRecord.layer.name),
            value: layerRecord.selected,
            onChanged: (selected) =>
                _selectLayer(layerRecord, selected ?? false),
          ),
        // Text field to enter the map title.
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        // Text field to enter the map tags.
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(labelText: 'Tags'),
        ),
        // Text field to enter the map description.
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 2,
        ),
        // Dropdown to select the folder to save the map in.
        DropdownButtonFormField(
          initialValue: _selectedFolder,
          decoration: const InputDecoration(labelText: 'Folder'),
          items: [
            const DropdownMenuItem<PortalFolder>(child: Text('Root folder')),
            ..._folders.map(
              (folder) =>
                  DropdownMenuItem(value: folder, child: Text(folder.title)),
            ),
          ],
          onChanged: (folder) => setState(() => _selectedFolder = folder),
        ),
      ],
    );
  }

  void _updateBasemap(BasemapStyle style) {
    // Replace the map basemap when the selection changes.
    setState(() => _selectedBasemapStyle = style);
    _map!.basemap = Basemap.withStyle(_selectedBasemapStyle);
  }

  void _selectLayer(LayerRecord layerRecord, bool selected) {
    // Update the selection state of the layer record.
    setState(() => layerRecord.selected = selected);

    // Update the operational layers to reflect the current selection.
    _map!.operationalLayers.clear();
    _map!.operationalLayers.addAll(
      _layerRecords
          .where((layerRecord) => layerRecord.selected)
          .map((layerRecord) => layerRecord.layer),
    );
  }

  Future<void> _saveMap() async {
    // Disable the UI while the map is being saved.
    setState(() => _ready = false);

    try {
      // Attempt to save the map as a new web map item in the selected folder.
      await _map!.saveAs(
        portal: _portal,
        title: _titleController.text.trim(),
        folder: _selectedFolder,
        description: _descriptionController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
      );
      if (!mounted) return;

      // Notify the user that the map has been successfully saved.
      showAlertDialog(context, 'Portal item saved', title: 'Saved').ignore();
    } on ArcGISException catch (e) {
      if (!mounted) return;

      // An error occurred while attempting to save the map.
      showExceptionDialog('Save failed', e);
    }

    // Restore the UI.
    setState(() => _ready = true);
  }
}
