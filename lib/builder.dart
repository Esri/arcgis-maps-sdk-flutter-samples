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
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder sampleCatalogBuilder(BuilderOptions options) => SampleCatalogBuilder();

// Generates assets/generated_samples_list.json by combining all the README.metadata.json files.
class SampleCatalogBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$package$': ['assets/generated_samples_list.json'],
  };

  @override
  Future build(BuildStep buildStep) async {
    final assets =
        buildStep.findAssets(Glob('lib/samples/*/README.metadata.json'));
    final metadataFiles = <String>[];
    await for (final input in assets) {
      metadataFiles.add(input.path);
    }
    final output = AssetId(
      buildStep.inputId.package,
      'assets/generated_samples_list.json',
    );
    return buildStep.writeAsString(output, createCatalog(metadataFiles));
  }

  String createCatalog(List<String> metadataFiles) {
    final samples = <String, dynamic>{};
    for (final metadataFilename in metadataFiles) {
      final metadataFile = File(metadataFilename);
      final directoryName =
          metadataFile.parent.path.split('/').last;
      // Get the json string for the sample.
      final sampleJsonContent = jsonDecode(metadataFile.readAsStringSync());
      // Add a key/value pair that is used by the Sample Viewer app.
      sampleJsonContent['key'] = directoryName;
      // Add the sample to the list of samples, using the directory name as the key.
      samples[directoryName] = sampleJsonContent;
    }

    // Sort alphabetically.
    final sortedSamples = {
      for (final k in samples.keys.toList()..sort()) k: samples[k],
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(sortedSamples);
  }
}

Builder sampleWidgetsBuilder(BuilderOptions options) => SampleWidgetsBuilder();

// Generates lib/models/samples_widget_list.dart by enumerating the samples directories
// and creating a map of sample names to their corresponding Widgets.
class SampleWidgetsBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$package$': ['lib/models/samples_widget_list.dart'],
  };

  @override
  Future build(BuildStep buildStep) async {
    final assets =
        buildStep.findAssets(Glob('lib/samples/*/README.metadata.json'));
    final samples = <String>[];
    await for (final sample in assets) {
      samples.add(sample.path);
    }
    final output = AssetId(
      buildStep.inputId.package,
      'lib/models/samples_widget_list.dart',
    );
    return buildStep.writeAsString(output, await createSource(samples));
  }

  Future<String> createSource(List<String> samples) async {
    final buffer = StringBuffer();
    final sortedSampleNames = samples
        .map((filepath) => File(filepath).parent.path.split('/').last)
        .toList()
      ..sort();

    for (final sampleName in sortedSampleNames) {
      buffer.writeln(
        "import 'package:arcgis_maps_sdk_flutter_samples/samples/$sampleName/$sampleName.dart';",
      );
    }

    buffer.writeln(
      '\n// A list of all the Widgets for individual Samples.\n// Used by the Sample Viewer App to display the Widget when a sample is selected.\n// The key is the directory name for the sample which is in snake case. E.g. display_map',
    );

    buffer.writeln('final sampleWidgets = {');
    for (final sampleName in sortedSampleNames) {
      final camelCaseName = snakeToCamel(sampleName);
      buffer.writeln("  '$sampleName': () => const $camelCaseName(),");
    }
    buffer.writeln('};');
    return buffer.toString();
  }

  // Convert a snake case string to camel case.
  String snakeToCamel(String input) {
    final camelCase = input.replaceAllMapped(
      RegExp('(_[a-z])'),
      (Match match) => match.group(0)!.toUpperCase().substring(1),
    );
    var newName = camelCase[0].toUpperCase() + camelCase.substring(1);
    if (newName.contains('Oauth')) {
      newName = newName.replaceFirst('Oauth', 'OAuth');
    }
    if (newName.contains('Ogc')) {
      newName = newName.replaceFirst('Ogc', 'OGC');
    }
    if (newName.contains('Api')) {
      newName = newName.replaceFirst('Api', 'API');
    }
    return newName;
  }
}
