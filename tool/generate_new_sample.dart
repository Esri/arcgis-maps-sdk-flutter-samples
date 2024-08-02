// ignore_for_file: avoid_print

import 'dart:io';

/// Run from arcgis-maps-sdk-flutter-samples root directory.
///
/// Example:
/// dart run tool/generate_new_sample.dart [optional SampleClassName]
void main(List<String> arguments) async {
  var sampleDirectoryName = 'MyNewSample';
  if (arguments.isNotEmpty) {
    sampleDirectoryName = arguments[0];
  }
  createNewSample(sampleDirectoryName);
}

// Create a new sample directory and a sample template.
//
// The sample directory will be created in the lib/samples directory.
// The [sampleCamelName] is expected to be in the camel case format:
// e.g. MyNewSample
//
// The sample directory will be created in the format:
// e.g. my_new_sample
void createNewSample(String sampleCamelName) {
  final ps = Platform.pathSeparator;
  final currentDirectory = Directory.current;
  final sampleSnakeName = camelToSnake(sampleCamelName);
  final sampleRootDirectory =
      Directory('${currentDirectory.path}${ps}lib${ps}samples');
  final sampleDirectory =
      Directory('${sampleRootDirectory.path}$ps$sampleSnakeName');

  if (sampleDirectory.existsSync()) {
    throw FileSystemException(
      'Sample directory already exists at the provided path',
      sampleDirectory.path,
    );
  }

  // Create the sample directory
  try {
    sampleDirectory.createSync();
    print('>Sample directory created at ${sampleDirectory.path}');
  } on Exception catch (_) {
    rethrow;
  }

  // Create the README.md file
  createEmptyReadMeOrCopy(sampleDirectory, sampleCamelName);

  // Create the sample file
  createNewSampleFile(sampleDirectory, sampleSnakeName, sampleCamelName);

  // Add the sample to the samples_widget_list.dart file
  addSampleToSamplesWidgetList(
      sampleRootDirectory, sampleSnakeName, sampleCamelName);
}

// Convert a camel case string to snake case.
String camelToSnake(String input) {
  final snakeCase = input.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (Match match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );
  return snakeCase.toLowerCase();
}

// Create a new sample README.md file,
// or copy the template README.md file
// from the common-samples/designs directory if it exists.
// The common-samples directory is expected to be at the same level
// as the samples directory.
// - /common-samples
// - /arcgis-maps-sdk-flutter-samples
void createEmptyReadMeOrCopy(
    Directory sampleDirectory, String sampleCamelName) {
  final ps = Platform.pathSeparator;
  final templateReadmeFile = File(
      '${Directory.current.parent.path}${ps}common-samples${ps}designs$ps$sampleCamelName${ps}README.md');
  try {
    final sampleReadmeFile = File('${sampleDirectory.path}${ps}README.md');
    if (templateReadmeFile.existsSync()) {
      sampleReadmeFile.writeAsBytesSync(templateReadmeFile.readAsBytesSync());
      print('>A README File created');
    } else {
      print('>A empty README file was created');
      sampleReadmeFile.writeAsStringSync('README-Empty');
    }
  } catch (_) {
    rethrow;
  }
}

// Create a new sample file
void createNewSampleFile(
    Directory sampleDirectory, String sampleSnakeName, String sampleCamelName) {
  final ps = Platform.pathSeparator;
  final templateFile = File(
      '${Directory.current.parent.path}${ps}flutter${ps}internal${ps}lib${ps}sample_skeleton.dart');
  final sampleFile = File('${sampleDirectory.path}$ps$sampleSnakeName.dart');

  sampleFile.createSync();
  sampleFile.writeAsStringSync(copyright);

  if (templateFile.existsSync()) {
    final lines = templateFile.readAsLinesSync();
    var skip = false;
    for (var line in lines) {
      skip = line.startsWith('//') ? true : false;
      if (!skip) {
        final newLine = line.replaceAll('SampleWidget', sampleCamelName);
        sampleFile.writeAsStringSync('$newLine${Platform.lineTerminator}',
            mode: FileMode.append);
      }
    }
  }
  print('>A sample file created');
}

// Add the new sample to the samples_widget_list.dart file
void addSampleToSamplesWidgetList(Directory sampleRootDirectory,
    String sampleSnakeName, String sampleCamelName) {
  final ps = Platform.pathSeparator;
  final samplesWidgetListFile = File(
      '${sampleRootDirectory.parent.path}${ps}models${ps}samples_widget_list.dart');
  final sampleWidgetImport =
      "import 'package:arcgis_maps_sdk_flutter_samples/samples/$sampleSnakeName/$sampleSnakeName.dart';";
  final sampleWidgetMap =
      "  '$sampleSnakeName': () => const $sampleCamelName(),";

  final samplesWidgetListFileLines = samplesWidgetListFile.readAsLinesSync();
  var indexImport = 0;
  for (var i = 0; i <= samplesWidgetListFileLines.length; i++) {
    var line = samplesWidgetListFileLines[i];
    if (line.startsWith('//')) {
      indexImport = i; // starting line for comments
      break;
    }
  }
  samplesWidgetListFileLines.insert(indexImport - 1, sampleWidgetImport);
  final indexEnd = samplesWidgetListFileLines.indexOf('};');
  samplesWidgetListFileLines.insert(indexEnd, sampleWidgetMap);
  //clean up the file first
  samplesWidgetListFile.writeAsStringSync('');

  for (var line in samplesWidgetListFileLines) {
    samplesWidgetListFile.writeAsStringSync('$line${Platform.lineTerminator}',
        mode: FileMode.append);
  }
  print('>An entry is added to the samples_widget_list.dart');
}

const copyright = '''
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
''';
