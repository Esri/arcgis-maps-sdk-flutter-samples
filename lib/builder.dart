import 'package:build/build.dart';

Builder copyBuilder(BuilderOptions options) => CopyBuilder();

class CopyBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    // Each [buildStep] has a single input.
    var inputId = buildStep.inputId;

    // Create a new target [AssetId] based on the old one.
    var contents = await buildStep.readAsString(inputId);

    var copy = inputId.addExtension('.copy');

    // Write out the new asset.
    await buildStep.writeAsString(copy, '// Copied from $inputId\n$contents');
  }

  @override
  final buildExtensions = const {
    '.txt': ['.txt.copy'],
  };
}
