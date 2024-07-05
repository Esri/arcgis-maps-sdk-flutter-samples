import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ShowPortalUserInfoSample extends StatefulWidget {
  const ShowPortalUserInfoSample({super.key});

  @override
  State<ShowPortalUserInfoSample> createState() =>
      _ShowPortalUserInfoSampleState();
}

class _ShowPortalUserInfoSampleState extends State<ShowPortalUserInfoSample>
    with SampleStateSupport
    implements ArcGISAuthenticationChallengeHandler {
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/mapping-apis-and-services/security/user-authentication/serverless-native-flow/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'lgAdHkYZYlwwfAhC',
    redirectUri: Uri.parse('my-ags-app://auth'),
  );
  final _portal =
      Portal.arcGISOnline(connection: PortalConnection.authenticated);
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();

    // This class implements the ArcGISAuthenticationChallengeHandler interface,
    // which allows it to handle authentication challenges via calls to its
    // handleArcGISAuthenticationChallenge() method.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = this;

    _loadFuture = _portal.load();
  }

  @override
  void dispose() async {
    // We do not want to handle authentication challenges outside of this sample,
    // so we remove this as the challenge handler.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = null;

    // Revoke OAuth tokens and remove all credentials to log out.
    await Future.wait(ArcGISEnvironment
        .authenticationManager.arcGISCredentialStore
        .getCredentials()
        .whereType<OAuthUserCredential>()
        .map((credential) => credential.revokeToken()));
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();

    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text('Authenticating...');
              }

              if (snapshot.hasError) {
                return Center(
                  //fixme
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              return Column(
                children: [
                  //fixme
                  Text('User: ${_portal.user?.fullName}'),
                  Text('Access: ${_portal.user?.access}'),
                ],
              );
            }),
      ),
    );
  }
}
