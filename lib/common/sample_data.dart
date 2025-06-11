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
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

/// Download sample data for the provided list of Portal Item IDs.
Future<void> downloadSampleData(List<String> portalItemIds) async {
  const portal = 'https://arcgis.com';
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

    final request = await _fetchData(portal, itemId);
    file.createSync(recursive: true);
    file.writeAsBytesSync(request.bodyBytes, flush: true);

    if (itemName.contains('.zip')) {
      // If the data is a zip we need to extract it.
      await extractZipArchive(file);
    }
  }
}

Future<void> extractZipArchive(File archiveFile) async {
  // Save all files to a directory with the filename without the zip extension in the same directory as the zip file.
  final pathWithoutExt = archiveFile.path.replaceFirst(RegExp(r'.zip$'), '');
  final dir = Directory.fromUri(Uri.parse(pathWithoutExt));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  await ZipFile.extractToDirectory(zipFile: archiveFile, destinationDir: dir);
}

/// Fetch data from the provided Portal and PortalItem ID and return the response.
Future<Response> _fetchData(String portal, String itemId) async {
  return get(Uri.parse('$portal/sharing/rest/content/items/$itemId/data'));
}

/// Fetch the Sample data from the provided PortalItem ID.
/// Parameters:
/// - [itemId]: The ID of the Portal Item to download.
/// - [file]: The file to write the downloaded data to.
/// - [onProgress] is called with a value from 0.0 to 1.0 as the download progresses.
Future<void> downloadSampleDataWithProgress({
  required String itemId,
  required File file, 
  void Function(double progress)? onProgress,
}) async {
  const portal = 'https://arcgis.com';
  // Use the shared client instance
  final request = Request(
    'GET',
    Uri.parse('$portal/sharing/rest/content/items/$itemId/data'),
  );
  final response = await _sharedHttpClient.send(request);

  final contentLength = response.contentLength ?? 0;
  var received = 0;

  // Open file for writing
  final sink = file.openWrite();

  final completer = Completer<void>();
  response.stream.listen(
    (chunk) {
      sink.add(chunk); // Write chunk directly to file
      received += chunk.length;
      if (onProgress != null && contentLength > 0) {
        onProgress(received / contentLength);
      }
    },
    onDone: () async {
      await sink.close();
      completer.complete();
    },
    onError: (e) async {
      await sink.close();
      completer.completeError(e);
    },
    cancelOnError: true,
  );
  return completer.future;
}

// Use a single static instance of Client for all HTTP requests.
final Client _sharedHttpClient = Client();
