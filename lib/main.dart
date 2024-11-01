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
import 'package:arcgis_maps_sdk_flutter_samples/widgets/about_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/sample_list_view.dart';

void main() {
  // Supply your apiKey using the --dart-define-from-file command line argument.
  const apiKey = String.fromEnvironment('API_KEY');
  // Alternatively, replace the above line with the following and hard-code your apiKey here:
  // const apiKey = 'your_api_key_here';
  if (apiKey.isEmpty) {
    throw Exception('apiKey undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }

  runApp(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SampleViewerApp(),
    ),
  );
}

class SampleViewerApp extends StatefulWidget {
  const SampleViewerApp({super.key});

  @override
  State<SampleViewerApp> createState() => _SampleViewerAppState();
}

class _SampleViewerAppState extends State<SampleViewerApp> {
  final _allSamples = <Sample>[];
  final _searchFocusNode = FocusNode();
  final _textEditingController = TextEditingController();
  var _filteredSamples = <Sample>[];
  bool _ready = false;
  bool _searchHasFocus = false;

  @override
  void initState() {
    super.initState();
    loadSamples();
    _searchFocusNode.addListener(
      () {
        if (_searchFocusNode.hasFocus != _searchHasFocus) {
          setState(() => _searchHasFocus = _searchFocusNode.hasFocus);
        }
      },
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'ArcGIS Maps SDK for Flutter Samples';

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              useSafeArea: true,
              builder: (context) {
                return FractionallySizedBox(
                  heightFactor: 0.5,
                  child: Column(
                    children: [
                      AppBar(
                        title: const Text('About'),
                        backgroundColor:
                            Theme.of(context).colorScheme.inversePrimary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30.0),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        child: const AboutInfo(title: title),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _textEditingController,
              onChanged: onSearchChanged,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _searchHasFocus ? Icons.cancel : Icons.search,
                  ),
                  onPressed: onSearchSuffixPressed,
                ),
              ),
            ),
          ),
          _ready
              ? Expanded(
                  child: Listener(
                    onPointerDown: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: SampleListView(samples: _filteredSamples),
                  ),
                )
              : const Center(
                  child: Text('Loading samples...'),
                ),
        ],
      ),
    );
  }

  void onSearchSuffixPressed() {
    if (_searchHasFocus) {
      _textEditingController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      onSearchChanged('');
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  void loadSamples() async {
    final jsonString =
        await rootBundle.loadString('assets/generated_samples_list.json');
    final sampleData = jsonDecode(jsonString);
    for (final s in sampleData.entries) {
      _allSamples.add(Sample.fromJson(s.value));
    }
    _filteredSamples = _allSamples;
    setState(() => _ready = true);
  }

  void onSearchChanged(String searchText) {
    final List<Sample> results;
    if (searchText.isEmpty) {
      results = _allSamples;
    } else {
      results = _allSamples.where(
        (sample) {
          final lowerSearchText = searchText.toLowerCase();
          return sample.title.toLowerCase().contains(lowerSearchText) ||
              sample.category.toLowerCase().contains(lowerSearchText) ||
              sample.keywords.any(
                (keyword) => keyword.toLowerCase().contains(lowerSearchText),
              );
        },
      ).toList();
    }

    setState(() => _filteredSamples = results);
  }
}
