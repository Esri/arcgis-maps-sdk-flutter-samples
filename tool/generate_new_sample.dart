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
  sampleDirectory.createSync();
  print('>Sample directory created at ${sampleDirectory.path}');

  // Create the README.md file
  createEmptyReadMeOrCopy(sampleDirectory, sampleCamelName);

  // Create the sample file
  createNewSampleFile(sampleDirectory, sampleSnakeName, sampleCamelName);

  // Add the sample to the samples_widget_list.dart file
  addSampleToSamplesWidgetList(sampleRootDirectory);
}

// Convert a camel case string to snake case.
String camelToSnake(String input) {
  final snakeCase = input.replaceAllMapped(
    RegExp('([a-z])([A-Z])'),
    (Match match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
  );
  return snakeCase.toLowerCase();
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
  return newName;
}

// Create a new sample README.md file,
// or copy the template README.md file
// from the common-samples/designs directory if it exists.
// The common-samples directory is expected to be at the same level
// as the samples directory.
// - /common-samples
// - /arcgis-maps-sdk-flutter-samples
void createEmptyReadMeOrCopy(
  Directory sampleDirectory,
  String sampleCamelName,
) {
  final ps = Platform.pathSeparator;
  final templateReadmeFile = File(
    '${Directory.current.parent.path}${ps}common-samples${ps}designs$ps$sampleCamelName${ps}README.md',
  );
  final sampleReadmeFile = File('${sampleDirectory.path}${ps}README.md');
  if (templateReadmeFile.existsSync()) {
    sampleReadmeFile.writeAsBytesSync(templateReadmeFile.readAsBytesSync());
    print('>A README FIle was created was from a template');
  } else {
    print('>An empty README file was created');
    sampleReadmeFile.writeAsStringSync('README-Empty');
  }
}

// Create a new sample file
void createNewSampleFile(
  Directory sampleDirectory,
  String sampleSnakeName,
  String sampleCamelName,
) {
  final ps = Platform.pathSeparator;
  final templateFile = File(
    '${Directory.current.parent.path}${ps}flutter${ps}internal${ps}lib${ps}sample_skeleton.dart',
  );
  final sampleFile = File('${sampleDirectory.path}$ps$sampleSnakeName.dart');

  sampleFile.createSync();
  sampleFile.writeAsStringSync(copyright);

  if (templateFile.existsSync()) {
    final lines = templateFile.readAsLinesSync();
    for (final line in lines) {
      if (!line.startsWith('//')) {
        final newLine = line.replaceAll('SampleWidget', sampleCamelName);
        sampleFile.writeAsStringSync(
          '$newLine${Platform.lineTerminator}',
          mode: FileMode.append,
        );
      }
    }
  }
  print('>A sample file $sampleCamelName.dart created');
}

// Regenerate the samples_widget_list.dart file
void addSampleToSamplesWidgetList(Directory sampleRootDirectory) {
  final ps = Platform.pathSeparator;
  final samplesWidgetListFile = File(
    '${sampleRootDirectory.parent.path}${ps}models${ps}samples_widget_list.dart',
  );

  final buffer = StringBuffer();
  final sortedSampleNames = sampleRootDirectory
      .listSync()
      .whereType<Directory>()
      .map((entity) => entity.path.split(ps).last)
      .toList()
    ..sort();

  for (final sampleName in sortedSampleNames) {
    buffer.writeln(
      "import 'package:arcgis_maps_sdk_flutter_samples/samples/$sampleName/$sampleName.dart';",
    );
  }

  buffer.writeln('\nfinal sampleWidgets = {');
  for (final sampleName in sortedSampleNames) {
    final camelCaseName = snakeToCamel(sampleName);
    buffer.writeln("  '$camelCaseName': () => const $camelCaseName(),");
  }
  buffer.writeln('};');
  samplesWidgetListFile.writeAsStringSync(buffer.toString());

  // Run dart format on the file
  Process.runSync('dart', ['format', samplesWidgetListFile.path]);
  print('>The samples_widget_list.dart regenerated');
}

final copyright = '''
// Copyright ${DateTime.now().year} Esri
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
