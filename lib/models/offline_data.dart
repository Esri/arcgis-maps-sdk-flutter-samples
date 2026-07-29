//
// Copyright 2026 Esri
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
import 'package:arcgis_maps_sdk_flutter_samples/common/download_util.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class OfflineDataLocation {
  // Private constructor to enforce singleton pattern.
  OfflineDataLocation._();

  static final instance = OfflineDataLocation._();

  /// Initializes the offline data location by obtaining the application documents directory.
  Future<void> initialize() async {
    _location = await getApplicationDocumentsDirectory();
  }

  /// The directory where offline data is stored.
  Directory get location => _location;

  late final Directory _location;
}

class OfflineData {
  /// Creates an [OfflineData] instance from a JSON list of downloadable resources.
  OfflineData.fromJson(List<dynamic> json) {
    downloadableResources = json
        .map(
          (e) =>
              DownloadableResource.fromJson(e as Map<String, dynamic>? ?? {}),
        )
        .toList(growable: false);
  }

  /// The list of downloadable resources for this offline data.
  List<DownloadableResource> downloadableResources = [];

  /// Returns whether all downloadable resources are present in the offline data location.
  bool allResourcesDownloaded() {
    final basePath = OfflineDataLocation.instance.location.path;
    return downloadableResources.every(
      (r) => File(path.join(basePath, r.downloadable)).existsSync(),
    );
  }

  /// Downloads the resources to the offline data location.
  ///
  /// [requestCancelToken] is used to handle cancellation of the download.
  /// [onProgress] is a callback that provides the download progress as an integer percentage.
  Future<void> downloadResources({
    required RequestCancelToken requestCancelToken,
    void Function(int progress)? onProgress,
  }) async {
    final itemIds = downloadableResources.map((r) => r.itemId).toList();
    final basePath = OfflineDataLocation.instance.location.path;
    final destinationFiles = downloadableResources
        .map((r) => File(path.join(basePath, r.downloadable)))
        .toList();

    await downloadSampleDataWithProgress(
      itemIds: itemIds,
      destinationFiles: destinationFiles,
      requestCancelToken: requestCancelToken,
      onProgress: onProgress,
    );
  }

  /// Cleans up downloaded files and extracted directories for this offline data.
  ///
  /// Deletes:
  /// - The downloaded file (ZIP or non-ZIP)
  /// - The extracted directory (for ZIP files only)
  void cleanupFiles() {
    final basePath = OfflineDataLocation.instance.location.path;
    try {
      for (final resource in downloadableResources) {
        final file = File(path.join(basePath, resource.downloadable));
        if (file.existsSync()) {
          file.deleteSync();
        }

        // For ZIP files, also delete the extracted directory.
        final isZip = resource.downloadable.toLowerCase().endsWith('.zip');
        if (isZip) {
          // Use path.withoutExtension to match the extraction directory naming.
          final extractionDirName = path.withoutExtension(
            resource.downloadable,
          );
          final extractionDir = Directory(
            path.join(basePath, extractionDirName),
          );
          if (extractionDir.existsSync()) {
            extractionDir.deleteSync(recursive: true);
          }
        }
      }
    } on FileSystemException catch (e) {
      // Ignore errors during cleanup - file may not exist or may be locked.
      debugPrint('Cleanup warning: ${e.message}');
    }
  }
}
