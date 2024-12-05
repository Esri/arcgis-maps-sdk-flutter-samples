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

Builder sampleWidgetsBuilder(BuilderOptions options) => SampleWidgetsBuilder();

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
    final ps = Platform.pathSeparator;
    final buffer = StringBuffer();
    final sortedSampleNames = samples
        .map((filepath) => File(filepath).parent.path.split(ps).last)
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

    // Run dart format on the buffer
    final formatProcess = await Process.start('dart', ['format']);
    formatProcess.stdin.writeln(buffer.toString());
    formatProcess.stdin.close();
    final output = await formatProcess.stdout.transform(utf8.decoder).join();

    return output;
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
