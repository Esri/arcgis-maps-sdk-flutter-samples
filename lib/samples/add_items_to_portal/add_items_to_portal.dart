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

import 'dart:convert';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class AddItemsToPortal extends StatefulWidget {
  const AddItemsToPortal({super.key});

  @override
  State<AddItemsToPortal> createState() => _AddItemsToPortalState();
}

class _AddItemsToPortalState extends State<AddItemsToPortal>
    with SampleStateSupport {
  // Create an OAuthUserConfiguration.
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/security-and-authentication/user-authentication/flows/authorization-code-with-pkce/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );

  // An authenticated portal to log in to.
  final _portal = Portal.arcGISOnline(connection: .authenticated);

  // The portal item to be added and deleted.
  PortalItem? _portalItem;

  // A flag indicating whether the portal has been loaded and authenticated.
  var _portalLoaded = false;

  // A flag indicating whether an operation (add or delete) is in progress.
  var _operationInProgress = false;

  // A message to display the status of the workflow.
  var _message = '';

  // The Sample Viewer uses an API Key to provide access in most samples. In this sample,
  // we need to set it aside so that only OAuth authentication is used. The key will be
  // restored when this sample is disposed.
  late String _sampleViewerApiKey;

  @override
  void initState() {
    super.initState();

    // Temporarily set aside the Sample Viewer application API Key so that portal authentication
    // gets used for this sample. Store the key to be reset on dispose.
    _sampleViewerApiKey = ArcGISEnvironment.apiKey;
    ArcGISEnvironment.apiKey = '';
  }

  @override
  void dispose() {
    // Revoke OAuth tokens and remove all credentials to log out.
    Authenticator.revokeOAuthTokens()
        .catchError((Object error) {
          // This sample has been disposed, so we can only report errors to the console.
          // ignore: avoid_print
          print('Error revoking tokens: $error');
        })
        .whenComplete(Authenticator.clearCredentials)
        .ignore();

    // Restore the Sample Viewer application API Key.
    ArcGISEnvironment.apiKey = _sampleViewerApiKey;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Wrap the controls in an Authenticator to handle the OAuth workflow.
        child: Authenticator(
          oAuthUserConfigurations: [_oauthUserConfiguration],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A button to load the portal and start the authentication workflow.
                ElevatedButton(
                  onPressed: !_portalLoaded && !_operationInProgress
                      ? _authenticatePortal
                      : null,
                  child: const Text('Authenticate Portal'),
                ),
                // A button to add the CSV item.
                ElevatedButton(
                  onPressed:
                      _portalLoaded &&
                          _portalItem == null &&
                          !_operationInProgress
                      ? _addItem
                      : null,
                  child: const Text('Add Item'),
                ),
                // A button to delete the item that was added.
                ElevatedButton(
                  onPressed:
                      _portalLoaded &&
                          _portalItem != null &&
                          !_operationInProgress
                      ? _deleteItem
                      : null,
                  child: const Text('Delete Item'),
                ),
                const SizedBox(height: 40),
                // The current status message.
                Text(_message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticatePortal() async {
    // Disable the controls while the portal is loading.
    setState(() => _operationInProgress = true);

    try {
      // Load the portal to trigger the OAuth workflow.
      await _portal.load();

      setState(() {
        _portalLoaded = true;
        _message = 'Signed in as ${_portal.user!.username}';
      });
    } on ArcGISException catch (error) {
      // Display authentication errors.
      showExceptionDialog('Portal authentication failed', error);
    }

    // Re-enable the controls after authentication finishes.
    setState(() => _operationInProgress = false);
  }

  Future<void> _addItem() async {
    // Disable the controls while the item is being added.
    setState(() => _operationInProgress = true);

    try {
      // Create a CSV portal item.
      final item = PortalItem.withPortalAndType(portal: _portal, type: .csv);
      item.title = 'Sample CSV Item';

      // Sample CSV content to be uploaded with the portal item.
      const csvData = '''
City,Lat,Long
Paris,48.8566,2.3522
London,51.5074,-0.1278
''';

      // Add the portal item.
      await _portal.user!.addPortalItem(
        item,
        contentParams: PortalItemContentParameters.withData(
          data: utf8.encode(csvData),
          filename: 'cities.csv',
        ),
      );

      setState(() {
        _portalItem = item;
        _message = 'Added item ${item.itemId}';
      });
    } on ArcGISException catch (error) {
      // Display errors adding to the portal.
      showExceptionDialog('Unable to add item', error);
    }

    // Re-enable the controls after the upload finishes.
    setState(() => _operationInProgress = false);
  }

  Future<void> _deleteItem() async {
    // Disable the controls while the item is deleted.
    setState(() => _operationInProgress = true);

    try {
      // Delete the portal item created by the Add Item action.
      await _portal.user!.deletePortalItem(_portalItem!);

      setState(() {
        _portalItem = null;
        _message = 'Portal item deleted';
      });
    } on ArcGISException catch (error) {
      // Display deletion errors from the portal.
      showExceptionDialog('Unable to delete item', error);
    }

    // Re-enable the controls after deletion finishes.
    setState(() => _operationInProgress = false);
  }
}
