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

import 'dart:async';
import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_archive/flutter_archive.dart';

const portal = 'https://arcgis.com';

/// Fetch the Sample data from the provided PortalItem ID.
/// Parameters:
/// - [itemIds]: A list of Portal Item IDs to be downloaded.
/// - [destinationFiles]: A list of files where the downloaded data will be written.
/// - [onProgress] is called with a value from 0.0 to 1.0 as the download progresses.
Future<List<ResponseInfo>> downloadSampleDataWithProgress({
  required List<String> itemIds,
  required List<File> destinationFiles,
  void Function(double progress)? onProgress,
}) async {
  final responses = <ResponseInfo>[];
  final totalItems = itemIds.length;

  for (var i = 0; i < itemIds.length; i++) {
    final itemId = itemIds[i];
    final destinationFile = destinationFiles[i];
    if (onProgress != null) onProgress(0);

    final requestUri = Uri.parse(
      '$portal/sharing/rest/content/items/$itemId/data',
    );
    final response = await ArcGISHttpClient.download(
      requestUri,
      destinationFile.uri,
      requestInfo: RequestInfo(
        onReceiveProgress: (bytesReceived, totalBytes) {
          if (onProgress != null) {
            // Calculate progress: completed items + current item progress
            final completedItems = i;
            final currentItemProgress = truncateTo2Decimals(
              bytesReceived / (totalBytes ?? 1),
            );
            final overallProgress =
                (completedItems + currentItemProgress) / totalItems;
            onProgress(truncateTo2Decimals(overallProgress));
          }
        },
      ),
    );

    if (destinationFile.path.contains('.zip')) {
      // If the data is a zip we need to extract it.
      await extractZipArchive(destinationFile);
    }
    print("download into: ${destinationFile.absolute.path}");

    responses.add(response);
  }

  return responses;
}

/// Truncate a double to two decimal digits (does not round).
double truncateTo2Decimals(double value) {
  return (value * 100).truncate() / 100;
}

/// Extract the contents of a zip archive to a directory
/// with the same name as the zip file (without the .zip extension).
/// Parameters:
/// - [archiveFile]: The zip file to extract.
Future<void> extractZipArchive(File archiveFile) async {
  // Save all files to a directory with the filename without the zip extension in the same directory as the zip file.
  final pathWithoutExt = archiveFile.path.replaceFirst(RegExp(r'.zip$'), '');
  final dir = Directory.fromUri(Uri.parse(pathWithoutExt));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  print('>>>>>> extract directory: ${dir.path}');
  await ZipFile.extractToDirectory(zipFile: archiveFile, destinationDir: dir);
}
