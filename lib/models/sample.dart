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

import 'package:arcgis_maps_sdk_flutter_samples/models/samples_widget_list.dart';
import 'package:flutter/material.dart';

/// Class that contains information about each of the samples.
/// The metadata is taken from the sample's README.metadata.json data via generated_samples_list.json.
/// The Widget for each sample is pulled from the samples_widget_list.dart.
class Sample {
  final String _category;
  final String _description;
  final List<String> _snippets;
  final String _title;
  final List<String> _keywords;
  final Widget _sampleWidget;

  Sample.fromJson(Map<String, dynamic> json)
      : _category = json['category'],
        _description = json['description'],
        _snippets = List<String>.from(json['snippets']),
        _title = json['title'],
        _keywords = List<String>.from(json['keywords']),
        _sampleWidget = sampleWidgets[json['key']]!() ?? const Placeholder();

  String get title => _title;

  String get description => _description;

  String get category => _category;

  List<String> get snippets => _snippets;

  List<String> get keywords => _keywords;

  Widget getSampleWidget() => _sampleWidget;
}
