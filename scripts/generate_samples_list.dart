// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Run from arcgis-maps-sdk-flutter-samples root directory
/// dart run scripts/generate_samples_list.dart
void main() {
  generateSamplesList();
}

/// Compiles all of the individual sample README.metadata.json files into a single JSON asset to feed into the Sample Viewer application.
/// The output is in assets/generated_samples_list.json
void generateSamplesList() {
  Map<String, dynamic> samples = {};

  print('Generating samples list....');

  // get the lib/samples directory
  final currentDirectory = Directory.current;
  final samplesDirectory = Directory('${currentDirectory.path}/lib/samples');

  if (samplesDirectory.existsSync()) {
    // get all the individual sample directories
    final individualSampleDirectories = samplesDirectory.listSync();

    // iterate through each directory and get the README.metadata.json file for each sample
    for (final directory in individualSampleDirectories) {
      final directoryName = directory.path.split('/').last;
      final metadataFile = (directory as Directory)
          .listSync()
          .firstWhere((file) => file.path.contains('metadata.json')) as File;
      // get the json string for the sample
      Map<String, dynamic> sampleJsonContent =
          jsonDecode(metadataFile.readAsStringSync());
      // add a key/value pair that is used by the Sample Viewer app
      sampleJsonContent['key'] = directoryName;
      // add the sample to the list of samples, using the directory name as the key
      samples[directoryName] = sampleJsonContent;
    }

    // sort alphabetically
    final sortedSamples = {
      for (var k in samples.keys.toList()..sort()) k: samples[k]
    };

    // print list of samples to console
    for (var key in sortedSamples.keys) {
      print(key);
    }
    print('Total samples: ${sortedSamples.keys.length}');

    // write the list of sorted samples to the generated_samples_list.json file
    final assetsDirectory = Directory('${currentDirectory.path}/assets');
    final samplesJsonFile =
        File('${assetsDirectory.path}/generated_samples_list.json');
    if (samplesJsonFile.existsSync()) {
      samplesJsonFile.writeAsStringSync(jsonEncode(sortedSamples));
    }
  } else {
    print('Unable to locate the samples directory.');
  }
}
