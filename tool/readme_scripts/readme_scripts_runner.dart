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

// As a command line tool, we want to use print for output
// ignore_for_file: avoid_print

import 'dart:io';

const checkmark = '\u2713';
const crossmark = '\u2716';
const lReadme = 'readme.md';
const lMetadata = 'readme.metadata.json';
const samplesDir = 'lib/samples';
final failedChecks = <FailedCheck>[];

/// Pass in the directory to a sample to run the checks
/// dart run tool/readme_scripts/readme_scripts_runner.dart display_map
/// Or pass -all to run the checks on all samples
/// dart run tool/readme_scripts/readme_scripts_runner.dart -all
/// If creating a new metadata file from an existing readme, pass in the category as the second arg:
/// dart run tool/readme_scripts/readme_scripts_runner.dart display_map "Maps"
/// The list of valid categories can be found at common-samples/designs/categories.md
void main(List<String> args) {
  final sampleDirectories = <Directory>[];
  String? currentDirPath;
  String? readmeFile;
  String? metadataFile;
  String? category;

  print('** Checking for sample files **');

  if (args.isNotEmpty) {
    Directory? directory;
    if (args[0] == '-all') {
      // If -all flag passed, check all samples.
      directory = Directory(samplesDir);
      checkIfDirExists(directory);
      sampleDirectories.addAll(directory.listSync().whereType<Directory>());
    } else {
      // Use provided sample e.g. display_map.
      directory = Directory('$samplesDir/${args[0]}');
      checkIfDirExists(directory);
      sampleDirectories.add(directory);
    }
    if (args.length == 2) {
      // If category provided as second arg use it.
      category = args[1];
    } else {
      // Else use empty string.
      category = '';
    }
  } else {
    print(
      'Invalid arguments, please provide the path to a valid sample directory.',
    );
    exit(1);
  }

  var returnCode = 0;

  for (final dir in sampleDirectories) {
    // Loop through the list of sample directories.
    currentDirPath = dir.path;
    print('\nCurrent sample: $currentDirPath');
    final sampleFiles = getSampleFilePaths(dir);
    if (sampleFiles.isEmpty) {
      print('No files identified, please check the provided path.');
      exit(1);
    }
    for (final filePath in sampleFiles) {
      // Loop through each file in the sample directory.
      final pathParts = filePath.split(Platform.pathSeparator);
      final filename = pathParts.last;
      final lFilename = filename.toLowerCase();

      // Skip any files that aren't the readme or metadata files.
      if (lFilename != lReadme && lFilename != lMetadata) {
        continue;
      }

      if (lFilename == lReadme) {
        // Exit if readme filename capitalization is incorrect.
        if (filename != 'README.md') {
          print(
            'Error: readme file has wrong capitalization in filename. Should be: README.md',
          );
          returnCode++;
        }
        // Get the readme file.
        readmeFile = filename;
      }

      if (lFilename == lMetadata) {
        // Exit if metadata filename capitalization is incorrect.
        if (filename != 'README.metadata.json') {
          print(
            'Error: metadata file has wrong capitalization in filename. Should be: README.metadata.json',
          );
          returnCode++;
        }
        // Get the metadata file.
        metadataFile = filePath;
      }
    }

    // Check the readme exists.
    if (readmeFile == null) {
      print(
        'Error: README.md does not exist. Please create and re-run the script.',
      );
      failedChecks.add(
        FailedCheck(
          name: 'README does not exist for $currentDirPath',
          result: null,
        ),
      );
      break;
    }

    // Run readme checks.
    // Check filename capitalization.
    // Run the markdown linter style checker on the readme.
    returnCode += runMdlStyleChecker(currentDirPath);

    // Run the readme content check.
    returnCode += runReadmeCheck(currentDirPath);

    // If the metadata file doesn't exist, create it from the readme.
    if (metadataFile == null) {
      returnCode += createMetadataFromReadme(currentDirPath, category);
      // Run the metadata content check.
      returnCode += runMetadataCheck(currentDirPath);
    } else {
      // Run the metadata content check.
      returnCode += runMetadataCheck(currentDirPath);
    }

    // Reset files.
    readmeFile = null;
    metadataFile = null;
  }

  if (failedChecks.isNotEmpty) {
    print('\n**********\n**** Failures: \n**********\n');
    printFailedChecks();
  } else {
    print('\nAll checks passed!');
  }
  exit(returnCode);
}

void checkIfDirExists(Directory directory) {
  if (!directory.existsSync()) {
    print('The directory does not exist: ${directory.path}.');
    exit(1);
  }
}

List<String> getSampleFilePaths(Directory directory) {
  // return the files in the individual sample directory
  return directory.listSync().whereType<File>().map((f) => f.path).toList();
}

void printScriptOutput(String name, ProcessResult result) {
  final stdout = result.stdout;
  final stderr = result.stderr;
  if (stdout == '' && stderr == '') {
    print('$checkmark $name passed.');
  } else {
    print('$crossmark $name failed.');
    failedChecks.add(FailedCheck(name: name, result: result));
  }
}

void printFailedChecks() {
  for (final check in failedChecks) {
    print('**** ${check.name} ****');
    final stdout = check.result?.stdout;
    final stderr = check.result?.stderr;
    if (stdout != null && stdout != '') {
      print(stdout);
    }
    if (stderr != null && stderr != '') {
      print(stderr);
    }
  }
}

int runMdlStyleChecker(String dirPath) {
  print('**** Running mdl (markdown linter) style checker ****');
  final result = Process.runSync('mdl', [
    '--style',
    './tool/readme_scripts/style.rb',
    '$dirPath/README.md',
  ]);

  printScriptOutput('mdl style check', result);

  return result.exitCode;
}

int runReadmeCheck(String dirPath) {
  print('**** README checker ****');
  final result = Process.runSync('python3', [
    './tool/readme_scripts/readme_checker.py',
    '-s',
    dirPath,
  ]);
  printScriptOutput('README checker', result);
  return result.exitCode;
}

int createMetadataFromReadme(String dirPath, String category) {
  print('**** Creating README.metadata.json from README.md ****');
  final result = Process.runSync('python3', [
    './tool/readme_scripts/create_metadata_from_README.py',
    '-s',
    dirPath,
    '-c',
    category,
  ]);
  printScriptOutput('create readme from metadata script', result);
  return result.exitCode;
}

int runMetadataCheck(String dirPath) {
  print('**** Metadata checker ****');
  final result = Process.runSync('python3', [
    './tool/readme_scripts/metadata_checker.py',
    '-s',
    dirPath,
  ]);
  printScriptOutput('Metadata checker', result);
  return result.exitCode;
}

class FailedCheck {
  FailedCheck({required this.name, required this.result});
  String name;
  ProcessResult? result;
}
