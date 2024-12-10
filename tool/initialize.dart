//
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

import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  await runDart(['pub', 'upgrade']);
  await runDart(['run', 'arcgis_maps', 'install']);
  await runDart(
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
  );
  await runDart(['format', 'lib/models/samples_widget_list.dart']);
  print('> Initialization complete.');
}

Future<void> runDart(List<String> arguments) async {
  final command = 'dart ${arguments.join(' ')}';
  final executable = Platform.environment['DART'] ?? 'dart';
  final process = await Process.start(executable, arguments);
  final exitCode = await process.exitCode;
  await process.stdout.map(utf8.decode).forEach(print);
  await process.stderr.map(utf8.decode).forEach(print);
  print('> "$command" succeeded\n');
  if (exitCode != 0) {
    throw Exception('"$command" failed with exit code "$exitCode"');
  }
}
