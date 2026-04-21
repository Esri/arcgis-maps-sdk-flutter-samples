//
// Copyright 2025 Esri
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

/// Defines a handler for the token authentication challenge callback used by samples
/// that require token authentication for accessing data.
class TokenChallengeHandler implements ArcGISAuthenticationChallengeHandler {
  TokenChallengeHandler(this.username, this.password);
  final String username;
  final String password;

  @override
  Future<void> handleArcGISAuthenticationChallenge(
    ArcGISAuthenticationChallenge challenge,
  ) async {
    final credential = await TokenCredential.createWithChallenge(
      challenge,
      username: username,
      password: password,
    );
    challenge.continueWithCredential(credential);
  }
}
