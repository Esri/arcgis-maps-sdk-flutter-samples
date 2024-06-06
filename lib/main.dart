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
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/sample_list_view.dart';

void main() {
  // Supply your apiKey using the --dart-define-from-file command line argument
  const apiKey = String.fromEnvironment('API_KEY');
  // Alternatively, replace the above line with the following and hard-code your apiKey here:
  // const apiKey = 'your_api_key_here';
  if (apiKey.isEmpty) {
    throw Exception('apiKey undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }
  runApp(const SampleViewerApp());
}

class SampleViewerApp extends StatefulWidget {
  const SampleViewerApp({super.key});

  @override
  State<SampleViewerApp> createState() => _SampleViewerAppState();
}

class _SampleViewerAppState extends State<SampleViewerApp> {
  final _samples = <Sample>[];
  bool _ready = false;

  @override
  void initState() {
    loadSamples();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    const title = 'ArcGIS Maps SDK for Flutter Samples';

    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(backgroundColor: colorScheme.inversePrimary),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: _ready
            ? SampleListView(samples: _samples)
            : const Center(child: Text('Loading samples...')),
      ),
    );
  }

  void loadSamples() async {
    final jsonString =
        await rootBundle.loadString('assets/generated_samples_list.json');
    final sampleData = jsonDecode(jsonString);
    for (final s in sampleData.entries) {
      _samples.add(Sample.fromJson(s.value));
    }
    setState(() => _ready = true);
  }
}
