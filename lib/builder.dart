import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder sampleCatalogBuilder(BuilderOptions options) => SampleCatalogBuilder();

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
          metadataFile.parent.path.split(Platform.pathSeparator).last;
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
