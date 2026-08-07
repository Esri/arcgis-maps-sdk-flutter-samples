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
import 'package:arcgis_maps_sdk_flutter_samples/models/offline_data.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart' as path;

/// Fetch the Sample data from the provided PortalItem ID.
/// Parameters:
/// - [itemIds]: A list of Portal Item IDs to be downloaded.
/// - [destinationFiles]: A list of files where the downloaded data will be written.
/// - [requestCancelToken]: downloads can be cancelled via this token.
/// - [onProgress] is called with a value from 0 to 100 as the download progresses.
Future<List<ResponseInfo>> downloadSampleDataWithProgress({
  required OfflineData offlineData,
  required RequestCancelToken requestCancelToken,
  void Function(int progress)? onProgress,
}) async {
  var currentProgress = 0;
  final responses = <ResponseInfo>[];
  final totalItems = offlineData.downloadableResources.length;
  if (totalItems == 0) {
    onProgress?.call(100);
    return <ResponseInfo>[];
  }

  onProgress?.call(currentProgress);

  final portalItems = await Future.wait(
    offlineData.downloadableResources.map((r) => r.cachedPortalItem()),
  );

  final zipFiles = <File>[];
  final basePath = OfflineDataLocation.instance.location.path;
  for (var i = 0; i < portalItems.length; i++) {
    final portalItem = portalItems[i];
    final destinationFile = File(path.join(basePath, portalItem.name));

    final requestUri = Uri.parse('${portalItem.uri}/data');

    final response = await ArcGISHttpClient.download(
      requestUri,
      destinationFile.uri,
      requestInfo: RequestInfo(
        requestCancelToken: requestCancelToken,
        onReceiveProgress: (bytesReceived, totalBytes) {
          if (onProgress != null) {
            // Calculate progress: completed items + current item progress
            final completedItems = i;
            final currentItemProgress = bytesReceived / (totalBytes ?? 1);
            final overallProgress =
                (completedItems + currentItemProgress) / totalItems;

            final nextProgress = (overallProgress * 100).round();
            if (nextProgress != currentProgress) {
              currentProgress = nextProgress;
              onProgress(nextProgress);
            }
          }
        },
      ),
    );

    if (destinationFile.path.contains('.zip')) {
      zipFiles.add(destinationFile);
    }
    responses.add(response);
  }

  // Decompress any zip files received.
  await Future.wait(zipFiles.map(extractZipArchive));

  onProgress?.call(100);
  return responses;
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
  await ZipFile.extractToDirectory(zipFile: archiveFile, destinationDir: dir);
}
