// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Run from arcgis-maps-sdk-flutter-samples root directory
/// dart run tool/generate_samples_list.dart
void main() {
  generateSamplesList();
}

/// Compiles all of the individual sample README.metadata.json files into a single JSON asset to feed into the Sample Viewer application.
/// The output is in assets/generated_samples_list.json
void generateSamplesList() {
  final pathSeparator = Platform.pathSeparator;
  final samples = <String, dynamic>{};

  print('Generating samples list....');

  // check for the required directories
  final currentDirectory = Directory.current;
  final samplesDirectory = Directory(
    '${currentDirectory.path}${pathSeparator}lib${pathSeparator}samples',
  );
  final assetsDirectory =
      Directory('${currentDirectory.path}${pathSeparator}assets');

  if (!samplesDirectory.existsSync()) {
    throw FileSystemException(
      'Samples directory does not exist at the provided path',
      samplesDirectory.path,
    );
  }

  if (!assetsDirectory.existsSync()) {
    throw FileSystemException(
      'Assets directory does not exist at the provided path',
      assetsDirectory.path,
    );
  }

  // Get all the individual sample directories.
  final individualSampleDirectories = samplesDirectory.listSync();

  // Iterate through each directory and get the README.metadata.json file for each sample.
  for (final directory in individualSampleDirectories) {
    final directoryName = directory.path.split(pathSeparator).last;
    final metadataFile = (directory as Directory)
        .listSync()
        .firstWhere((file) => file.path.contains('metadata.json')) as File;
    // Get the json string for the sample.
    Map<String, dynamic> sampleJsonContent =
        jsonDecode(metadataFile.readAsStringSync());
    // Add a key/value pair that is used by the Sample Viewer app.
    sampleJsonContent['key'] = directoryName;
    // Add the sample to the list of samples, using the directory name as the key.
    samples[directoryName] = sampleJsonContent;
  }

  // Sort alphabetically.
  final sortedSamples = {
    for (final k in samples.keys.toList()..sort()) k: samples[k],
  };

  // Print list of samples to console.
  for (final key in sortedSamples.keys) {
    print(key);
  }
  print('Total samples: ${sortedSamples.keys.length}');

  // Write the list of sorted samples to the generated_samples_list.json file.
  final samplesJsonFile = File(
    '${assetsDirectory.path}${pathSeparator}generated_samples_list.json',
  );
  const encoder = JsonEncoder.withIndent('  ');
  samplesJsonFile.writeAsStringSync(encoder.convert(sortedSamples));
}
