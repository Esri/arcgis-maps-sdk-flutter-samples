// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image/image.dart' as img;

/// Run from arcgis-maps-sdk-flutter-samples root directory
///
/// Example:
/// dart run tool/generate_new_sample.dart Add3dTilesLayer
void main(List<String> arguments) async {
  var sampleDirectoryName = 'MyNewSample';
  if (arguments.isNotEmpty) {
    sampleDirectoryName = arguments[0];
  }
  createNewSampleDirectory(sampleDirectoryName);
}

// Create a new sample directory
// The sample directory will be created in the lib/samples directory
// The sampleName is expected to be in the camel case format  e.g. MyNewSample
// The sample directory will be created in the format my_new_sample
void createNewSampleDirectory(String sampleCamelName) {
  final currentDirectory = Directory.current;
  final sampleSnakeName = camelToSnake(sampleCamelName);
  final sampleRootDirectory = Directory('${currentDirectory.path}/lib/samples');
  final sampleDirectory =
      Directory('${sampleRootDirectory.path}/${sampleSnakeName}');

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

  // Create a blank PNG file
  createEmptyPNGFile(sampleDirectory, sampleSnakeName);

  // Create the sample file
  createNewSampleFile(sampleDirectory, sampleSnakeName, sampleCamelName);
}

// Convert a camel case string to snake case.
String camelToSnake(String input) {
  final snakeCase = input.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (Match match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );
  return snakeCase.toLowerCase();
}

// Create a new sample README.md file
void createEmptyReadMeOrCopy(
    Directory sampleDirectory, String sampleCamelName) {
  final templateReadmeFile = File(
      '${Directory.current.parent.path}/common-samples/designs/${sampleCamelName}/README.md');
  try {
    final sampleReadmeFile = File('${sampleDirectory.path}/README.md');
    if (templateReadmeFile.existsSync()) {
      sampleReadmeFile.writeAsBytesSync(templateReadmeFile.readAsBytesSync());
      print('>A README File created');
    } else {
      print('>A empty README file was created');
      sampleReadmeFile.writeAsStringSync('README-Empty');
    }
  } catch (e) {
    rethrow;
  }
}

// Create a new blank PNG file
void createEmptyPNGFile(Directory sampleDirectory, String sampleSnakeName) {
  try {
    final image = img.Image(height: 600, width: 300);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final png = img.encodePng(image);
    final file = File(
        '${sampleDirectory.path}${Platform.pathSeparator}${sampleSnakeName}.png');
    file.writeAsBytesSync(png);
    print('>A blank PNG file created with dimensions 600x300.');
  } on Exception catch (e) {
    rethrow;
  }
}

// Create a new sample file
void createNewSampleFile(
    Directory sampleDirectory, String sampleSnakeName, String sampleCamelName) {
  final templateFile = File(
      '${Directory.current.parent.path}/flutter/internal/lib/sample_skeleton.dart');
  print(templateFile.path);
  print(templateFile.existsSync());
  final sampleFile = File('${sampleDirectory.path}/$sampleSnakeName.dart');
  print(sampleFile.path);
  print(sampleFile.existsSync());

  sampleFile.createSync();
  sampleFile.writeAsStringSync(copyright);

  if (templateFile.existsSync()) {
    final lines = templateFile.readAsLinesSync();
    var skip = false;
    for (var line in lines) {
      skip = line.startsWith('//') ? true : false;
      if (!skip) {
        final newLine = line.replaceAll('SampleWidget', sampleCamelName);
        sampleFile.writeAsStringSync('$newLine\n', mode: FileMode.append);
      }
    }
  }
  print('>A sample file created');
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
