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

// ignore_for_file: avoid_print

import 'dart:io';

const checkmark = '\u2713';
const lReadme = 'readme.md';
const lMetadata = 'readme.metadata.json';

/// Pass in the directory to a sample to run the checks
/// dart run readme_scripts_runner.dart "path/to/samples/display_map"
/// If creating a new metadata file from an existing readme, pass in the category as the second arg:
/// dart run readme_scripts_runner.dart "path/to/samples/display_map" "Maps"
/// The list of valid categories can be found at common-samples/designs/categories.md
void main(List<String> args) {
  var filePaths = <String>[];
  String? dirPath;
  String? readmeFile;
  String? metadataFile;
  String? category;
  print('** Checking for sample files **');

  // get all the files in the provided path
  if (args.isNotEmpty) {
    dirPath = args[0];
    if (args.length == 2) {
      category = args[1];
    } else {
      category = '';
    }
    final directory = Directory(dirPath);
    if (directory.existsSync()) {
      filePaths = getFilePaths(directory);
      if (filePaths.isEmpty) {
        print('No files identified, please check the provided path.');
        exit(1);
      }
    } else {
      print('The directory does not exist: $dirPath.');
      exit(1);
    }
  } else {
    print('Invalid arguments, please provide the path to a sample directory.');
    exit(1);
  }

  var returnCode = 0;

  for (final filePath in filePaths) {
    final pathParts = filePath.split(Platform.pathSeparator);
    final filename = pathParts.last;
    final lFilename = filename.toLowerCase();

    // skip any files that aren't the readme or metadata files
    if (lFilename != lReadme && lFilename != lMetadata) {
      continue;
    }

    if (lFilename == lReadme) {
      // exit if readme filename capitalization is incorrect
      if (filename != 'README.md') {
        print(
            'Error: readme file has wrong capitalization in filename. Should be: README.md');
        returnCode++;
      }
      // get the readme file
      readmeFile = filename;
    }

    // get the metadata file
    if (lFilename == lMetadata) {
      // exit if metadata filename capitalization is incorrect
      if (filename != 'README.metadata.json') {
        print(
            'Error: metadata file has wrong capitalization in filename. Should be: README.metadata.json');
        returnCode++;
      }
      metadataFile = filePath;
    }
  }

  // check the readme exists
  if (readmeFile == null) {
    print(
        'Error: README.md does not exist. Please create and re-run the script.');
    returnCode++;
  }

  // Run readme checks
  // check filename capitalization
  // run the markdown linter style checker on the readme
  returnCode += runMdlStyleChecker(dirPath);

  // run the readme content check
  returnCode += runReadmeCheck(dirPath);

  // if the metadata file doesn't exist, create it from the readme
  if (metadataFile == null) {
    returnCode += createMetadataFromReadme(dirPath, category);
    // run the metadata content check
    returnCode += runMetadataCheck(dirPath);
  } else {
    // run the metadata content check
    returnCode += runMetadataCheck(dirPath);
  }

  if (returnCode != 0) {
    exit(returnCode);
  } else {
    exit(0);
  }
}

int createMetadataFromReadme(String dirPath, String category) {
  print('**** Creating README.metadata.json from README.md ****');
  var result = Process.runSync('python3',
      ['create_metadata_from_README.py', '-s', dirPath, '-c', category]);
  printScriptOutput('create readme from metadata script', result);
  return result.exitCode;
}

List<String> getFilePaths(Directory directory) {
  final files = <String>[];
  final directoryContents = directory.listSync();
  for (final file in directoryContents) {
    if (file is File) {
      files.add(file.path);
    }
  }
  return files;
}

void printScriptOutput(String name, ProcessResult result) {
  final stdout = result.stdout;
  final stderr = result.stderr;
  if (stdout != '') {
    print(stdout);
  }
  if (stderr != '') {
    print(stderr);
  }
  if (stdout == '' && stderr == '') {
    print('$checkmark $name passed.');
  }
}

int runMdlStyleChecker(String dirPath) {
  print('**** Running mdl (markdown linter) style checker ****');
  var result =
      Process.runSync('mdl', ['--style', 'style.rb', '$dirPath/README.md']);

  printScriptOutput('mdl style check', result);

  return result.exitCode;
}

int runReadmeCheck(String dirPath) {
  print('**** README checker ****');
  var result = Process.runSync('python3', ['readme_checker.py', '-s', dirPath]);
  printScriptOutput('README checker', result);
  return result.exitCode;
}

int runMetadataCheck(String dirPath) {
  print('**** Metadata checker ****');
  var result =
      Process.runSync('python3', ['metadata_checker.py', '-s', dirPath]);
  printScriptOutput('Metadata checker', result);
  return result.exitCode;
}
