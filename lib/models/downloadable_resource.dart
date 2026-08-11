//
// Copyright 2025 Esri
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

import 'dart:convert';
import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/offline_data.dart';
import 'package:path/path.dart' as path;

/// Represents a resource that can be downloaded for a sample.
class DownloadableResource {
  DownloadableResource({
    required this.portal,
    required this.itemId,
    this.resource,
  });

  factory DownloadableResource.fromJson(
    Map<String, dynamic> json,
    Portal portal,
  ) {
    return DownloadableResource(
      portal: portal,
      itemId: json['itemId'] as String,
      resource: json['resource'] as String?,
    );
  }

  final Portal portal;
  final String itemId;
  final String? resource;

  PortalItem? _portalItem;

  Map<String, dynamic> toJson() {
    return {'itemId': itemId, 'resource': resource};
  }

  /// Returns the PortalItem for this resource, from cache if available or else loaded from the network.
  Future<PortalItem> cachedPortalItem() async {
    // If the PortalItem is already cached in memory, return it.
    if (_portalItem != null) {
      return _portalItem!;
    }

    final serialized = portalItemJsonFile();

    // If the PortalItem JSON is already cached on disk, read it and return the PortalItem.
    if (serialized.existsSync()) {
      final jsonString = await serialized.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _portalItem = PortalItem.fromJson(json);
      return _portalItem!;
    }

    // Not currently cached -- load the PortalItem from the portal and cache it to disk.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: itemId,
    );
    await portalItem.load();
    serialized.writeAsStringSync(jsonEncode(portalItem.toJson()), flush: true);

    // Cache the PortalItem in memory and return it.
    _portalItem = portalItem;
    return _portalItem!;
  }

  File portalItemJsonFile() {
    return File(
      path.join(OfflineDataLocation.instance.location.path, '$itemId.json'),
    );
  }

  Directory downloadingDirectory() {
    return Directory(
      path.join(
        OfflineDataLocation.instance.location.path,
        '$itemId.downloading',
      ),
    );
  }

  Directory downloadedDirectory() {
    return Directory(
      path.join(
        OfflineDataLocation.instance.location.path,
        '$itemId.downloaded',
      ),
    );
  }

  // Whether this resource has been successfully downloaded.
  bool get isDownloaded =>
      portalItemJsonFile().existsSync() && downloadedDirectory().existsSync();
}
