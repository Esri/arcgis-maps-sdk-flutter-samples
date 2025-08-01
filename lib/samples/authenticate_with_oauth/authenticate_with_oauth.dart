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
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

class AuthenticateWithOAuth extends StatefulWidget {
  const AuthenticateWithOAuth({super.key});

  @override
  State<AuthenticateWithOAuth> createState() => _AuthenticateWithOAuthState();
}

class _AuthenticateWithOAuthState extends State<AuthenticateWithOAuth>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // Create an OAuthUserConfiguration.
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/security-and-authentication/user-authentication/flows/authorization-code-with-pkce/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );

  @override
  void dispose() {
    // Revoke OAuth tokens and remove all credentials to log out.
    Authenticator.revokeOAuthTokens()
        .catchError((error) {
          // This sample has been disposed, so we can only report errors to the console.
          // ignore: avoid_print
          print('Error revoking tokens: $error');
        })
        .whenComplete(Authenticator.clearCredentials);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add an Authenticator to handle authentication challenges.
      body: Authenticator(
        // Provide the OAuthUserConfiguration to the Authenticator.
        oAuthUserConfigurations: [_oauthUserConfiguration],
        // Add a map view to the widget tree and set a controller.
        child: ArcGISMapView(
          controllerProvider: () => _mapViewController,
          onMapViewReady: onMapViewReady,
        ),
      ),
    );
  }

  void onMapViewReady() {
    // Create a map from a web map that has a secure layer (traffic).
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
      itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
    );
    final map = ArcGISMap.withItem(portalItem);

    // Set the map to map view controller.
    _mapViewController.arcGISMap = map;
  }
}
