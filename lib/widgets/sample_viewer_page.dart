
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
import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart' as arcgis_category;
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sample_list_view.dart';

class SampleViewerPage extends StatefulWidget {
  arcgis_category.Category? category;
  SampleViewerPage({super.key});

  @override
  State<SampleViewerPage> createState() => _SampleViewerPageState();
}

class _SampleViewerPageState extends State<SampleViewerPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(applicationTitle),
       
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
    // _filteredSamples = _allSamples;
    if (widget.category != null) {
      setState(() {
         _filteredSamples = getSamplesByCategory(widget.category!);
      });
    }
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

  List<Sample> getSamplesByCategory(arcgis_category.Category category) {
    return _allSamples.where((sample) { 
      return sample.category.toLowerCase() == category.title.toLowerCase();
    }).toList();
  }
}
