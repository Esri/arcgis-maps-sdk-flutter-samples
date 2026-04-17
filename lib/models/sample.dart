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

import 'dart:async';

// run `dart run build_runner build` to generate samples_widget_list.dart
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/samples_widget_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class that contains information about each of the samples.
/// The metadata is taken from the sample's README.metadata.json data via generated_samples_list.json.
/// The Widget for each sample is pulled from the samples_widget_list.dart.
class Sample {
  Sample.fromJson(Map<String, dynamic> json)
    : _category = json['category'] as String? ?? '',
      _description = json['description'] as String? ?? '',
      _snippets = List<String>.from(json['snippets'] as List? ?? []),
      _title = json['title'] as String? ?? '',
      _keywords = List<String>.from(json['keywords'] as List? ?? []),
      _key = json['key'] as String? ?? '',
      _downloadableResources = _parseDownloadableResources(
        json['offline_data'] as List? ?? [],
      ),
      _sampleWidget = sampleWidgets[json['key']]!();
  final String _category;
  final String _description;
  final List<String> _snippets;
  final String _title;
  final List<String> _keywords;
  final Widget _sampleWidget;
  final String _key;
  final List<DownloadableResource> _downloadableResources;

  static List<DownloadableResource> _parseDownloadableResources(
    List<dynamic> resources,
  ) {
    return resources
        .whereType<Map<String, dynamic>>()
        .map(DownloadableResource.fromJson)
        .toList();
  }

  String get title => _title;

  String get description => _description;

  String get category => _category;

  List<String> get snippets => _snippets;

  List<String> get keywords => _keywords;

  String get key => _key;

  bool get isFavorite => FavoriteRepository.instance.isFavorite(_key);

  set isFavorite(bool value) =>
      FavoriteRepository.instance.setFavorite(_key, value);

  List<DownloadableResource> get downloadableResources =>
      _downloadableResources;

  /// Returns true if this sample requires downloadable resources.
  bool get hasDownloadableResources => _downloadableResources.isNotEmpty;

  Widget getSampleWidget() => _sampleWidget;
}

/// Repository for managing favorite state of samples, persisted using SharedPreferences.
/// `instance` must be initialized with SharedPreferences before use by calling `initialize()`.
class FavoriteRepository {
  static final instance = FavoriteRepository();

  late SharedPreferences _sharedPreferences;
  late Set<String> _favoriteSampleKeys;
  final _favoriteChangedController =
      StreamController<({String sampleKey, bool value})>.broadcast();

  /// Stream that emits events when a favorite sample is added or removed.
  Stream<({String sampleKey, bool value})> get favoriteChanged =>
      _favoriteChangedController.stream;

  /// Loads the favorite samples from SharedPreferences.
  void initialize(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
    _favoriteSampleKeys =
        (_sharedPreferences.getStringList('favorite_sample_keys') ??
                const <String>[])
            .toSet();
  }

  /// Whether the sample with the given key is marked as a favorite.
  bool isFavorite(String sampleKey) => _favoriteSampleKeys.contains(sampleKey);

  /// Sets the favorite status of the sample, persists the change, and emits an event.
  void setFavorite(String sampleKey, bool value) {
    final hasChanged = value
        ? _favoriteSampleKeys.add(sampleKey)
        : _favoriteSampleKeys.remove(sampleKey);

    if (!hasChanged) {
      return;
    }

    _sharedPreferences.setStringList(
      'favorite_sample_keys',
      _favoriteSampleKeys.toList(),
    );

    _favoriteChangedController.add((sampleKey: sampleKey, value: value));
  }
}
