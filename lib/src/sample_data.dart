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

import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

/// Download sample data for the provided list of Portal Item IDs.
Future<void> downloadSampleData(List<String> portalItemIds) async {
  const portal = 'https://arcgis.com';
  // location where files are saved to on the device. Persists while the app persists.
  final appDirPath = (await getApplicationDocumentsDirectory()).absolute.path;

  for (final itemId in portalItemIds) {
    // create a portal item to ensure it exists and load to access properties
    final portalItem =
        PortalItem.withUri(Uri.parse('$portal/home/item.html?id=$itemId'));
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
      // if the data is a zip we need to extract it
      // save all files to the device app directory in a directory with the item name without the zip extension
      final nameWithoutExt = itemName.replaceFirst(RegExp(r'.zip$'), '');
      final dir = Directory.fromUri(Uri.parse('$appDirPath/$nameWithoutExt'));
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      await ZipFile.extractToDirectory(zipFile: file, destinationDir: dir);
    }
  }
}

/// Fetch data from the provided Portal and PortalItem ID and return the response.
Future<Response> _fetchData(String portal, String itemId) async {
  return await get(
      Uri.parse('$portal/sharing/rest/content/items/$itemId/data'));
}
