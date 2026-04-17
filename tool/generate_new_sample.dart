// As a command line tool, we want to use print for output
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Run from arcgis-maps-sdk-flutter-samples root directory.
///
/// Example:
/// dart run tool/generate_new_sample.dart [optional SampleClassName] [optional Category]
Future<void> main(List<String> arguments) async {
  var sampleCamelName = 'MyNewSample';
  var category = 'Maps';

  if (arguments.isNotEmpty) {
    sampleCamelName = arguments[0];
  }
  if (arguments.length >= 2 && arguments[1].trim().isNotEmpty) {
    category = arguments[1].trim();
  }

  final sampleSnakeName = camelToSnake(sampleCamelName);

  // 1) Create sample folder + template files
  final sampleDirectory = createNewSample(sampleCamelName);

  // 2) Create a 1px placeholder png with snake_case name
  create1pxPng(sampleDirectory, sampleSnakeName);

  // 3) Fix README image reference (CamelCase.png -> snake_case.png)
  updateHeroImageTarget(sampleDirectory, sampleSnakeName);

  // 4) Run README scripts (generate metadata, validate)
  await runReadmeScriptsBestEffort(sampleSnakeName, category);

  // 5) Run build_runner so sample is picked up by sample_runner / generated JSON
  await runBuildRunner();

  print('\n✅ Done.');
  print('Next: update your VS Code [launch.json] to:');
  print('  --dart-define=SAMPLE=$sampleSnakeName');
}

// Create a new sample directory and a sample template.
//
// The sample directory will be created in the lib/samples directory.
// The [sampleCamelName] is expected to be in the camel case format:
// e.g. MyNewSample
//
// The sample directory will be created in the format:
// e.g. my_new_sample
Directory createNewSample(String sampleCamelName) {
  final ps = Platform.pathSeparator;
  final currentDirectory = Directory.current;
  final sampleSnakeName = camelToSnake(sampleCamelName);

  final sampleRootDirectory = Directory(
    '${currentDirectory.path}${ps}lib${ps}samples',
  );
  final sampleDirectory = Directory(
    '${sampleRootDirectory.path}$ps$sampleSnakeName',
  );

  if (sampleDirectory.existsSync()) {
    throw FileSystemException(
      'Sample directory already exists at the provided path',
      sampleDirectory.path,
    );
  }

  // Create the sample directory
  sampleDirectory.createSync();
  print('> Sample directory created at ${sampleDirectory.path}');

  // Create the README.md file
  createEmptyReadMeOrCopy(sampleDirectory, sampleCamelName);

  // Create the sample file
  createNewSampleFile(sampleDirectory, sampleSnakeName, sampleCamelName);

  return sampleDirectory;
}

// Convert a camel case string to snake case.
String camelToSnake(String input) {
  final snakeCase = input.replaceAllMapped(
    RegExp('([a-z])([0-9A-Z])'),
    (match) => '${match.group(1)}_${match.group(2)!.toLowerCase()}',
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
    print('> A README file was created from a template');
  } else {
    print('> An empty README file was created');
    sampleReadmeFile.writeAsStringSync('README-Empty');
  }
}

// Create a new sample file.
void createNewSampleFile(
  Directory sampleDirectory,
  String sampleSnakeName,
  String sampleCamelName,
) {
  final ps = Platform.pathSeparator;
  final templateFile = File(
    '${Directory.current.path}${ps}lib${ps}utils${ps}sample_skeleton.dart',
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

  print('> A sample file $sampleSnakeName.dart created');
}

// Creates a 1x1 transparent PNG named "sampleSnakeName.png" next to README.md.
void create1pxPng(Directory sampleDirectory, String sampleSnakeName) {
  final ps = Platform.pathSeparator;
  final pngFile = File('${sampleDirectory.path}$ps$sampleSnakeName.png');

  if (pngFile.existsSync()) {
    print('> PNG already exists: ${pngFile.path}');
    return;
  }

  // 1x1 transparent PNG
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
  pngFile.writeAsBytesSync(base64Decode(base64Png));
  print('> Placeholder PNG created: ${pngFile.path}');
}

// Replaces occurrences of "SampleCamelName.jpg" with "sampleSnakeName.png" in README.md.
void updateHeroImageTarget(Directory sampleDirectory, String sampleSnakeName) {
  final ps = Platform.pathSeparator;
  final readmeFile = File('${sampleDirectory.path}${ps}README.md');

  if (!readmeFile.existsSync()) return;

  final content = readmeFile.readAsStringSync();

  // Capture:
  // 1) alt text ("Image of ...")
  // 2) target inside (...) (e.g., display-map.png)
  // 3) optional title part (rare, but harmless):  "some title"
  final re = RegExp(
    r'!\[(Image of[^\]]*)\]\(([^)"\s]+)(\s+"[^"]*")?\)',
    caseSensitive: false,
  );

  final updated = content.replaceFirstMapped(re, (m) {
    final alt = m.group(1)!; // keep
    final title = m.group(3) ?? ''; // keep if present
    final newTarget = '$sampleSnakeName.png';
    return '![$alt]($newTarget$title)';
  });

  readmeFile.writeAsStringSync(updated);
}

// Run Readme scripts to generate metadata.json
Future<void> runReadmeScriptsBestEffort(
  String sampleSnakeName,
  String category,
) async {
  const scriptPath = 'tool/readme_scripts/readme_scripts_runner.dart';
  final args = <String>['run', scriptPath, sampleSnakeName, category];

  print('> Running README scripts (best effort): dart ${args.join(' ')}');

  final exitCode = await runCommand('dart', args, allowFailure: true);

  if (exitCode != 0) {
    print(
      '⚠️ README scripts reported issues (exit $exitCode). Continuing so the sample is runnable.',
    );
    print(
      '   Fix README/metadata style issues before PR; CI will still catch these.',
    );
  }
}

// Deletes stale cache before running build_runner.
Future<void> runBuildRunner() async {
  final buildArgs = [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ];
  final cleanArgs = ['run', 'build_runner', 'clean'];

  print('> Running build_runner: dart ${cleanArgs.join(' ')}');
  await runCommand('dart', cleanArgs);

  print('> Running build_runner: dart ${buildArgs.join(' ')}');
  await runCommand('dart', buildArgs);
}

// Run Command with stdout/stderr streaming and `ProcessException` on non-zero exit code for clearer failures.
Future<int> runCommand(
  String executable,
  List<String> args, {
  bool allowFailure = false,
}) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: Directory.current.path,
    runInShell: true,
  );

  if (result.stdout.toString().trim().isNotEmpty) stdout.write(result.stdout);
  if (result.stderr.toString().trim().isNotEmpty) stderr.write(result.stderr);

  if (!allowFailure && result.exitCode != 0) {
    throw ProcessException(
      executable,
      args,
      'Command failed with exit code ${result.exitCode}',
      result.exitCode,
    );
  }

  return result.exitCode;
}

final copyright =
    '''
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
