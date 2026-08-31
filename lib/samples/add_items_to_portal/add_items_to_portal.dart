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
  // Configure OAuth authentication for ArcGIS Online.
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );

  // Create an authenticated portal for the user's content.
  final _portal = Portal.arcGISOnline(connection: .authenticated);

  // Keep the item reference so the same item can be deleted later.
  PortalItem? _portalItem;

  //fixme comments
  var _portalLoaded = false;

  var _operationInProgress = false;

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
    // Wrap the controls in an Authenticator to handle the OAuth workflow.
    return Authenticator(
      oAuthUserConfigurations: [_oauthUserConfiguration],
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              // Load the portal and start the authentication workflow.
              ElevatedButton(
                onPressed: _portalLoaded || _operationInProgress
                    ? null
                    : _authenticatePortal,
                child: const Text('Authenticate Portal'),
              ),
              // Add the CSV item after the portal user is authenticated.
              ElevatedButton(
                onPressed: _portalLoaded && !_operationInProgress
                    ? _addItem
                    : null,
                child: const Text('Add Item'),
              ),
              // Delete the item that was added by this sample.
              ElevatedButton(
                onPressed: _portalItem != null && !_operationInProgress
                    ? _deleteItem
                    : null,
                child: const Text('Delete Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _authenticatePortal() async {
    // Disable the controls while the portal is loading.
    setState(() => _operationInProgress = true);

    try {
      // Load the portal to trigger the OAuth sign-in page.
      await _portal.load();
      setState(() => _portalLoaded = true);
      showMessageDialog('Signed in as ${_portal.user!.username}.');
    } on ArcGISException catch (error) {
      // Display authentication errors from the portal.
      showExceptionDialog('Portal authentication failed', error);
    }

    // Re-enable the controls after authentication finishes.
    setState(() => _operationInProgress = false);
  }

  Future<void> _addItem() async {
    // Disable the controls while the item is uploaded.
    setState(() => _operationInProgress = true);

    try {
      // Create a CSV portal item.
      final item = PortalItem.withPortalAndType(portal: _portal, type: .csv);
      item.title = 'Sample CSV Item';
      const csvData = '''
City,Lat,Long
Paris,48.8566,2.3522
London,51.5074,-0.1278
''';

      // Add the CSV content and load the returned item properties.
      await _portal.user!.addPortalItem(
        item,
        contentParams: PortalItemContentParameters.withData(
          data: utf8.encode(csvData),
          filename: 'cities.csv',
        ),
      );
      setState(() => _portalItem = item);
      showMessageDialog(
        'The CSV item was added to your portal.',
        title: 'Item added',
      );
    } on ArcGISException catch (error) {
      // Display upload errors from the portal.
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
      setState(() => _portalItem = null);
      showMessageDialog(
        'The CSV item was deleted from your portal.',
        title: 'Item deleted',
      );
    } on ArcGISException catch (error) {
      // Display deletion errors from the portal.
      showExceptionDialog('Unable to delete item', error);
    }

    // Re-enable the controls after deletion finishes.
    setState(() => _operationInProgress = false);
  }
}
