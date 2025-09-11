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

import 'dart:convert';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/samples_widget_list.dart';
import 'package:arcgis_maps_sdk_flutter_samples/router_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Run an individual sample outside of the Sample Viewer App.
void main() async {
  // Supply your apiKey using the --dart-define-from-file command line argument.
  const apiKey = String.fromEnvironment('API_KEY');
  // Alternatively, replace the above line with the following and hard-code your apiKey here:
  // const apiKey = ''; // Your API Key here.
  ArcGISEnvironment.apiKey = apiKey;

  // Supply the directory name of a sample via the --dart-define command line argument
  // e.g. --dart-define=SAMPLE=display_map
  const sampleFolderName = String.fromEnvironment('SAMPLE');
  // Alternatively, replace sample below with the directory name of the individual sample in snake case
  // const sample = 'display_map';

  final jsonString = await rootBundle.loadString(
    'assets/generated_samples_list.json',
  );
  final sampleData = jsonDecode(jsonString) as Map<String, dynamic>;
  final allSamples = List<Sample>.unmodifiable(
    sampleData.values.whereType<Map<String, dynamic>>().map(Sample.fromJson),
  );
  final sample = allSamples.firstWhere((s) {
    return s.key == sampleFolderName;
  });
  
  final initialRoute = sample.hasDownloadableResources
      ? '/${sample.key}/resources'
      : '/${sample.key}/live';
  
  final router = routerConfigWithSample(sample, initialRoute);
  
  runApp(
    MaterialApp.router(
      routerConfig: router,
      theme: sampleViewerTheme,
    ),
  );
}
