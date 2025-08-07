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

class AuthenticateWithToken extends StatefulWidget {
  const AuthenticateWithToken({super.key});

  @override
  State<AuthenticateWithToken> createState() => _AuthenticateWithTokenState();
}

class _AuthenticateWithTokenState extends State<AuthenticateWithToken>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  void dispose() {
    // Log out by removing all credentials.
    Authenticator.clearCredentials();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Add an Authenticator to handle authentication challenges.
      body: Authenticator(
        // Add a map view to the widget tree and set a controller.
        child: ArcGISMapView(
          controllerProvider: () => _mapViewController,
          onMapViewReady: onMapViewReady,
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Set a portal item map that has a secure layer (traffic).
    // Loading the secure layer will trigger an authentication challenge.
    _mapViewController.arcGISMap = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
        itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
      ),
    );
  }
}
