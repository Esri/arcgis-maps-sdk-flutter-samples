import 'dart:typed_data';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../../utils/sample_state_support.dart';

class ShowPortalUserInfo extends StatefulWidget {
  const ShowPortalUserInfo({super.key});

  @override
  State<ShowPortalUserInfo> createState() =>
      _ShowPortalUserInfoState();
}

class _ShowPortalUserInfoState extends State<ShowPortalUserInfo>
    with SampleStateSupport
    implements ArcGISAuthenticationChallengeHandler {
  // This document describes the steps to configure OAuth for your app:
  // https://developers.arcgis.com/documentation/mapping-apis-and-services/security/user-authentication/serverless-native-flow/
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://www.arcgis.com'),
    clientId: 'T0A3SudETrIQndd2',
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),
  );
  // Create a Portal that requires authentication.
  final _portal =
      Portal.arcGISOnline(connection: PortalConnection.authenticated);
  // Create a Future that tracks the loading of the portal.
  Future<void>? _portalLoadFuture;
  // Create variables to store the user and organization thumbnails.
  Uint8List? _userThumbnail;
  Uint8List? _organizationThumbnail;

  @override
  void initState() {
    super.initState();

    // This class implements the ArcGISAuthenticationChallengeHandler interface,
    // which allows it to handle authentication challenges via calls to its
    // handleArcGISAuthenticationChallenge() method.
    ArcGISEnvironment
        .authenticationManager.arcGISAuthenticationChallengeHandler = this;

    // Load the portal (which will trigger an authentication challenge), and then load the thumbnails.
    _portalLoadFuture = _portal.load().then((_) => loadThumbnails());
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
        minimum: const EdgeInsets.symmetric(horizontal: 10),
        // Create a FutureBuilder to respond to the loading of the portal.
        child: FutureBuilder(
            future: _portalLoadFuture,
            builder: (context, snapshot) {
              // If the portal is still loading, display a message.
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text('Authenticating...');
              }

              // If the portal load failed with an error, display the error.
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              // If the portal load succeeded, display the portal information.
              final titleStyle = Theme.of(context).textTheme.titleMedium;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_portal.user?.fullName} Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20.0),
                    _userThumbnail != null
                        ? Image.memory(_userThumbnail!)
                        : const Icon(Icons.person),
                    Text('Full name', style: titleStyle),
                    Text(_portal.user?.fullName ?? ''),
                    Text('Username', style: titleStyle),
                    Text(_portal.user?.username ?? ''),
                    Text('Email', style: titleStyle),
                    Text(_portal.user?.email ?? ''),
                    Text('Description', style: titleStyle),
                    Text(_portal.user?.userDescription ?? ''),
                    Text('Access', style: titleStyle),
                    Text(_portal.user?.access.name ?? ''),
                    const Divider(),
                    _organizationThumbnail != null
                        ? Image.memory(_organizationThumbnail!)
                        : const Icon(Icons.domain),
                    Text('Organization', style: titleStyle),
                    Text(_portal.portalInfo?.organizationName ?? ''),
                    Text('Can find external content', style: titleStyle),
                    Text('${_portal.portalInfo?.canSearchPublic}'),
                    Text('Can share items externally', style: titleStyle),
                    Text('${_portal.portalInfo?.canSharePublic}'),
                    Text('Description', style: titleStyle),
                    Text(_portal.portalInfo?.organizationDescription ?? ''),
                  ],
                ),
              );
            }),
      ),
    );
  }

  // Load the user and organization thumbnails.
  void loadThumbnails() {
    _portal.user?.thumbnail?.loadBytes().then((bytes) {
      setState(() => _userThumbnail = bytes);
    });
    _portal.portalInfo?.thumbnail?.loadBytes().then((bytes) {
      setState(() => _organizationThumbnail = bytes);
    });
  }
}
