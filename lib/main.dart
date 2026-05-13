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

import 'dart:convert';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/api_key_manager.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/theme_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/router_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Initialize Flutter before reading preferences and bundled sample metadata.
  WidgetsFlutterBinding.ensureInitialized();

  // Use the build-time API key by default. The About screen can set a
  // session-only override later without revealing the active key.
  ApiKeyManager.applyBuildTimeApiKey();

  // (Optional) Supply a license key using the --dart-define-from-file command line argument.
  const licenseKey = String.fromEnvironment('LICENSE_KEY');
  const advancedEditingExtension = String.fromEnvironment(
    'ADVANCED_EDITING_EXTENSION',
  );
  const analysisExtension = String.fromEnvironment('ANALYSIS_EXTENSION');
  if (licenseKey.isNotEmpty &&
      advancedEditingExtension.isNotEmpty &&
      analysisExtension.isNotEmpty) {
    ArcGISEnvironment.setLicenseUsingKey(
      licenseKey,
      extensions: [advancedEditingExtension, analysisExtension],
    );
  }

  final prefs = await SharedPreferences.getInstance();
  FavoriteRepository.instance.initialize(prefs);

  final jsonString = await rootBundle.loadString(
    'assets/generated_samples_list.json',
  );
  final sampleData = jsonDecode(jsonString) as Map<String, dynamic>;

  final allSamples = List<Sample>.unmodifiable(
    sampleData.values.whereType<Map<String, dynamic>>().map(Sample.fromJson),
  );

  final router = routerConfig(allSamples);

  runApp(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        return locale;
      },
      theme: sampleViewerLightTheme,
      darkTheme: sampleViewerDarkTheme,
    ),
  );
}
