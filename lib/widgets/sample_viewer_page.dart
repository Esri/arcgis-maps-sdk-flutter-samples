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

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const applicationTitle = 'ArcGIS Maps SDK for Flutter Samples';

/// A page that displays a list of sample categories.
class SampleViewerPage extends StatefulWidget {
  const SampleViewerPage({super.key, this.category, this.isSearchable = true});

  final SampleCategory? category;
  final bool isSearchable;

  @override
  State<SampleViewerPage> createState() => _SampleViewerPageState();
}

class _SampleViewerPageState extends State<SampleViewerPage> {
  final _allSamples = <Sample>[];
  final _searchFocusNode = FocusNode();
  final _textEditingController = TextEditingController();
  var _filteredSamples = <Sample>[];
  var _ready = false;
  var _searchHasFocus = false;

  final List<String> _searchPrefixes = [
    'Try',
    'Look for',
    'Search',
    'Explore',
    'Type to explore',
    'Check out',
    'Discover',
    'Start typing',
    'Tap to search',
  ];

  final List<String> _questionPrefixes = [
    'Need help with',
    'Find out about',
    'Interested in',
    'Dig into',
    'Want to learn',
    'How about',
    "Let's explore",
  ];
  final int _maxHintLength = 50; // limit keywords to short strings.

  List<String> _hintMessages = [];
  int _currentHintIndex = 0;
  late Timer _hintTimer;

  @override
  void initState() {
    super.initState();
    loadSamples();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus != _searchHasFocus) {
        setState(() => _searchHasFocus = _searchFocusNode.hasFocus);
      }
    });

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      if (_hintMessages.isNotEmpty &&
          !_searchHasFocus &&
          _textEditingController.text.isEmpty) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hintMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer.cancel();
    _textEditingController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            (widget.category != null && widget.category != SampleCategory.all)
                ? Text(widget.category!.title)
                : const Text(applicationTitle),
      ),
      body: Column(
        children: [
          Visibility(
            visible: widget.isSearchable,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _textEditingController,
                onChanged: onSearchChanged,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  suffixIcon: IconButton(
                    icon: Icon(_searchHasFocus ? Icons.cancel : Icons.search),
                    onPressed: onSearchSuffixPressed,
                  ),
                ),
              ),
            ),
          ),
          if (_ready)
            Expanded(
              child: Listener(
                onPointerDown:
                    (_) => FocusManager.instance.primaryFocus?.unfocus(),
                child:
                    _filteredSamples.isEmpty &&
                            _textEditingController.text.isEmpty &&
                            widget.isSearchable &&
                            _hintMessages.isNotEmpty
                        ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _hintMessages[_currentHintIndex],
                            key: ValueKey(_currentHintIndex),
                          ),
                        )
                        : SampleListView(samples: _filteredSamples),
              ),
            )
          else
            const Center(child: Text('Loading samples...')),
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

  Future<void> loadSamples() async {
    final jsonString = await rootBundle.loadString(
      'assets/generated_samples_list.json',
    );
    final sampleData = jsonDecode(jsonString) as Map<String, dynamic>;
    for (final s in sampleData.entries) {
      _allSamples.add(Sample.fromJson(s.value));
    }

    if (widget.category != null) {
      _filteredSamples = getSamplesByCategory(widget.category);
    }

    generateSearchHints();

    setState(() => _ready = true);
  }

  void onSearchChanged(String searchText) {
    var results = <Sample>[];
    // restore the initial list of samples if the search text is empty
    if (searchText.isEmpty) {
      if (widget.category == null) {
        results = [];
      } else if (widget.category == SampleCategory.all) {
        results = _allSamples;
      } else {
        results = getSamplesByCategory(widget.category);
      }
    } else {
      if (widget.category == null || widget.category == SampleCategory.all) {
        results =
            _allSamples.where((sample) {
              final lowerSearchText = searchText.toLowerCase();
              return sample.title.toLowerCase().contains(lowerSearchText) ||
                  sample.category.toLowerCase().contains(lowerSearchText) ||
                  sample.keywords.any(
                    (keyword) =>
                        keyword.toLowerCase().contains(lowerSearchText),
                  );
            }).toList();
        // if the category is not null, the only samples within the category are searched
      } else {
        results =
            getSamplesByCategory(widget.category).where((sample) {
              final lowerSearchText = searchText.toLowerCase();
              return sample.title.toLowerCase().contains(lowerSearchText) ||
                  sample.keywords.any(
                    (keyword) =>
                        keyword.toLowerCase().contains(lowerSearchText),
                  );
            }).toList();
      }
    }
    setState(() => _filteredSamples = results);
  }

  List<Sample> getSamplesByCategory(SampleCategory? category) {
    if (category == null) {
      return [];
    }
    if (category.title == SampleCategory.all.title) {
      return _allSamples;
    }

    return _allSamples.where((sample) {
      return sample.category.toLowerCase() == category.title.toLowerCase();
    }).toList();
  }

  void generateSearchHints() {
    final uniqueHints = <String>{};
    final random = Random();

    for (final sample in _allSamples) {
      final title = sample.title;

      // Generate a hint from title (if short).
      if (title.length <= _maxHintLength) {
        final useQuestion = random.nextBool();
        final prefix = useQuestion
            ? _questionPrefixes[random.nextInt(_questionPrefixes.length)]
            : _searchPrefixes[random.nextInt(_searchPrefixes.length)];
        final hint = useQuestion ? '$prefix "$title"?' : '$prefix "$title".';
        uniqueHints.add(hint);
      }

      // Generate hints from short keywords.
      for (final keyword in sample.keywords) {
        if (keyword.length <= _maxHintLength) {
          final useQuestion = random.nextBool();
          final prefix = useQuestion
              ? _questionPrefixes[random.nextInt(_questionPrefixes.length)]
              : _searchPrefixes[random.nextInt(_searchPrefixes.length)];
          final hint = useQuestion ? '$prefix "$keyword"?' : '$prefix "$keyword".';
          uniqueHints.add(hint);
        }
      }

      if (uniqueHints.length >= 20) break;
    }

    final hintsList = uniqueHints.toList()..shuffle();

    _hintMessages = [
      'Type to explore samples.',
      ...hintsList.take(6),
    ];
  }
}
