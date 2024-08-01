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

class AuthenticateWithOAuth extends StatefulWidget {
  const AuthenticateWithOAuth({super.key});

  @override
  State<AuthenticateWithOAuth> createState() =>
      _AuthenticateWithOAuthState();
}

class _AuthenticateWithOAuthState
    extends State<AuthenticateWithOAuth>
    with SampleStateSupport
    implements ArcGISAuthenticationChallengeHandler {
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/mapping-apis-and-services/security/user-authentication/serverless-native-flow/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    // This class implements the ArcGISAuthenticationChallengeHandler interface,
    // which allows it to handle authentication challenges via calls to its
    // handleArcGISAuthenticationChallenge() method.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = this;

    // A portal item map that has a secure layer (traffic).
    _mapViewController.arcGISMap = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
        itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
      ),
    );
  }

  @override
  void dispose() async {
    // We do not want to handle authentication challenges outside of this sample,
    // so we remove this as the challenge handler.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = null;

    super.dispose();

    // Revoke OAuth tokens and remove all credentials to log out.
    await Future.wait(ArcGISEnvironment
        .authenticationManager.arcGISCredentialStore
        .getCredentials()
        .whereType<OAuthUserCredential>()
        .map((credential) => credential.revokeToken()));
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
      ),
    );
  }

  @override
  void handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge) async {
    try {
      // Initiate the sign in process to the OAuth server.
      final credential = await OAuthUserCredential.create(
          configuration: _oauthUserConfiguration);

      // Sign in was successful, so continue with the provided credential.
      challenge.continueWithCredential(credential);
    } on ArcGISException catch (error) {
      // Sign in was canceled, or there was some other error.
      final e = (error.wrappedException as ArcGISException?) ?? error;
      if (e.errorType == ArcGISExceptionType.commonUserCanceled) {
        challenge.cancel();
      } else {
        challenge.continueAndFail();
      }
    }
  }
}
