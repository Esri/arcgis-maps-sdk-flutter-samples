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
import 'package:path_provider/path_provider.dart';

const portal = 'https://arcgis.com';

/// Download sample data for the provided list of Portal Item IDs.
Future<void> downloadSampleData(List<String> portalItemIds) async {
  // Location where files are saved to on the device. Persists while the app persists.
  final appDirPath = (await getApplicationDocumentsDirectory()).absolute.path;

  for (final itemId in portalItemIds) {
    // Create a portal item to ensure it exists and load to access properties.
    final portalItem = PortalItem.withUri(
      Uri.parse('$portal/home/item.html?id=$itemId'),
    );
    if (portalItem == null) continue;

    await portalItem.load();
    final itemName = portalItem.name;
    final filePath = '$appDirPath/$itemName';
    final file = File(filePath);
    if (file.existsSync()) continue;

    final data = await portalItem.fetchData();
    file.createSync(recursive: true);
    file.writeAsBytesSync(data, flush: true);

    if (itemName.contains('.zip')) {
      // If the data is a zip we need to extract it.
      await extractZipArchive(file);
    }
  }
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

/// Fetch the Sample data from the provided PortalItem ID.
/// Parameters:
/// - [itemId]: The ID of the Portal Item to download.
/// - [destinationFile]: The file to write the downloaded data to.
/// - [onProgress] is called with a value from 0.0 to 1.0 as the download progresses.
Future<ResponseInfo> downloadSampleDataWithProgress({
  required String itemId,
  required File destinationFile,
  void Function(double progress)? onProgress,
}) async {
  final requestUri = Uri.parse(
    '$portal/sharing/rest/content/items/$itemId/data',
  );
  final response = await ArcGISHttpClient.download(
    requestUri,
    destinationFile.uri,
    requestInfo: RequestInfo(
      onReceiveProgress: (bytesReceived, totalBytes) {
        if (onProgress != null) {
          onProgress(truncateTo2Decimals(bytesReceived / (totalBytes ?? 1)));
        }
      },
    ),
  );
  return response;
}

/// Truncate a double to two decimal digits (does not round).
double truncateTo2Decimals(double value) {
  return (value * 100).truncate() / 100;
}
