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

class AuthenticateWithTokenSample extends StatefulWidget {
  const AuthenticateWithTokenSample({super.key});

  @override
  State<AuthenticateWithTokenSample> createState() =>
      _AuthenticateWithTokenSampleState();
}

class _AuthenticateWithTokenSampleState
    extends State<AuthenticateWithTokenSample>
    with SampleStateSupport
    implements ArcGISAuthenticationChallengeHandler {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  void initState() {
    super.initState();

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
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() async {
    // Set a portal item map that has a secure layer (traffic).
    _mapViewController.arcGISMap = ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
        itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
      ),
    );
  }

  @override
  void handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(child: LoginWidget(challenge: challenge)),
    );
  }
}

//fixme comments
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool? _result;
  String? _error;

  @override
  void dispose() {
    if (_result == null) widget.challenge.continueAndFail();

    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Authentication Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(widget.challenge.requestUri.toString()),
            TextField(
              controller: _usernameController,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Username',
              ),
            ),
            TextField(
              controller: _passwordController,
              autocorrect: false,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
            ),
            const SizedBox(height: 10.0),
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
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  void login() async {
    setState(() => _error = null);

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
      final credential = await TokenCredential.createWithChallenge(
        widget.challenge,
        username: username,
        password: password,
      );
      if (!mounted) return;

      widget.challenge.continueWithCredential(credential);
      Navigator.of(context).pop(_result = true);
    } on ArcGISException catch (e) {
      setState(() => _error = e.message);
    }
  }

  void cancel() {
    widget.challenge.cancel();
    Navigator.of(context).pop(_result = false);
  }
}
