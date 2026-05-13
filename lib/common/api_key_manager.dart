//
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
//

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/foundation.dart';

class ApiKeyManager {
  ApiKeyManager._();

  // The API key provided at build time using `--dart-define`.
  static const _buildTimeApiKey = String.fromEnvironment('API_KEY');

  // Whether the active API key is a session-only override.
  static final isUsingOverride = ValueNotifier(false);

  // Applies the build-time API key and clears any session-only override state.
  static void applyBuildTimeApiKey() {
    ArcGISEnvironment.apiKey = _buildTimeApiKey;
    isUsingOverride.value = false;
  }

  // Applies a session-only API key override.
  // Returns false when the entered key is empty after trimming pasted whitespace.
  static bool applyOverride(String apiKey) {
    final trimmedApiKey = apiKey.trim();
    if (trimmedApiKey.isEmpty) return false;

    ArcGISEnvironment.apiKey = trimmedApiKey;
    isUsingOverride.value = true;

    return true;
  }
}
