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

class AuthenticateWithToken extends StatefulWidget {
  const AuthenticateWithToken({super.key});

  @override
  State<AuthenticateWithToken> createState() => _AuthenticateWithTokenState();
}

class _AuthenticateWithTokenState extends State<AuthenticateWithToken>
    with SampleStateSupport
    implements ArcGISAuthenticationChallengeHandler {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

    // Set this class to the arcGISAuthenticationChallengeHandler property on the authentication manager.
    // This class implements the ArcGISAuthenticationChallengeHandler interface,
    // which allows it to handle authentication challenges via calls to its
    // handleArcGISAuthenticationChallenge() method.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = this;
  }

  @override
  void dispose() {
    // We do not want to handle authentication challenges outside of this sample,
    // so we remove this as the challenge handler.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = null;

    // Log out by removing all credentials.
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() async {
    // Set a portal item map that has a secure layer (traffic).
    // Loading the secure layer will trigger an authentication challenge.
    _mapViewController.arcGISMap = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
        itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
      ),
    );
  }

  @override
  void handleArcGISAuthenticationChallenge(
    ArcGISAuthenticationChallenge challenge,
  ) async {
    // Show a login dialog to handle the authentication challenge.
    await showDialog(
      context: context,
      builder: (context) => LoginWidget(challenge: challenge),
    );
  }
}

// A widget that handles an authentication challenge by prompting the user to log in.
class LoginWidget extends StatefulWidget {
  final ArcGISAuthenticationChallenge challenge;

  const LoginWidget({
    super.key,
    required this.challenge,
  });

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  // Controllers for the username and password text fields.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  // An error message to display.
  String? _error;
  // The result: true if the user logged in, false if the user canceled.
  bool? _result;

  @override
  void dispose() {
    // If the widget was dismissed without a result, the challenge should fail.
    if (_result == null) widget.challenge.continueAndFail();

    // Text editing controllers must be disposed.
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Authentication Required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Show the server URL that is requiring authentication.
              Text(widget.challenge.requestUri.toString()),
              // Text fields for the username and password.
              TextField(
                controller: _usernameController,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                autocorrect: false,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
              const SizedBox(height: 10.0),
              // Buttons to cancel or log in.
              Row(
                children: [
                  ElevatedButton(
                    onPressed: cancel,
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: login,
                    child: const Text('Login'),
                  ),
                ],
              ),
              // Display an error message if there is one.
              Text(
                _error ?? '',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void login() async {
    setState(() => _error = null);

    // Username and password are required.
    final username = _usernameController.text;
    if (username.isEmpty) {
      setState(() => _error = 'Username is required.');
      return;
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password is required.');
      return;
    }

    try {
      // Attempt to create a credential with the provided username and password.
      final credential = await TokenCredential.createWithChallenge(
        widget.challenge,
        username: username,
        password: password,
      );
      if (!mounted) return;

      // If successful, continue with the credential.
      widget.challenge.continueWithCredential(credential);
      Navigator.of(context).pop(_result = true);
    } on ArcGISException catch (e) {
      // If there was an error, display the error message.
      setState(() => _error = e.message);
    }
  }

  void cancel() {
    // If the user cancels, cancel the challenge and dismiss the dialog.
    widget.challenge.cancel();
    Navigator.of(context).pop(_result = false);
  }
}
