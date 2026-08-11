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
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// On-disk layout
//
// Root directory:
// ${ApplicationDocumentsDirectory}/OfflineDataLocation/
//
// Downloadable resources in the root directory:
//
//   Serialized PortalItem JSON:
//   ${portalItem.itemId}.json
//
//   While downloading is in progress:
//   ${portalItem.itemId}.downloading/
//
//   Downloaded resources:
//     If single file:
//     ${portalItem.itemId}.downloaded/${portalItem.name}
//     If zip file:
//     ${portalItem.itemId}.downloaded/ (all extracted files)

class OfflineDataLocation {
  // Private constructor to enforce singleton pattern.
  OfflineDataLocation._();

  static final instance = OfflineDataLocation._();

  /// Initializes the offline data location by obtaining the application documents directory.
  Future<void> initialize() async {
    if (_location != null) {
      return;
    }

    final documents = await getApplicationDocumentsDirectory();
    final location = Directory(
      path.join(documents.path, 'OfflineDataLocation'),
    );
    if (!location.existsSync()) {
      location.createSync(recursive: true);
    }
    _location = location;
  }

  /// The directory where offline data is stored.
  Directory get location => _location!;

  Directory? _location;
}

class OfflineData {
  /// Creates an [OfflineData] instance from a JSON list of downloadable resources.
  OfflineData.fromJson(List<dynamic> json, Portal portal) {
    _downloadableResources = json
        .whereType<Map<String, dynamic>>()
        .map((json) => DownloadableResource.fromJson(json, portal))
        .toList(growable: false);
  }

  List<DownloadableResource> _downloadableResources = [];

  /// Whether this offline data has any downloadable resources.
  bool get hasDownloadableResources => _downloadableResources.isNotEmpty;

  /// Whether all downloadable resources are present in the offline data location.
  bool get allResourcesDownloaded =>
      _downloadableResources.every((resource) => resource.isDownloaded);

  /// Downloads the resources to the offline data location.
  ///
  /// [requestCancelToken] is used to handle cancellation of the download.
  /// [onProgress] is a callback that provides the download progress as an integer percentage.
  Future<void> downloadResources({
    required RequestCancelToken requestCancelToken,
    void Function(int progress)? onProgress,
  }) async {
    var currentProgress = 0;
    onProgress?.call(currentProgress);

    var completedItems = 0;
    for (final resource in _downloadableResources) {
      final portalItem = await resource.cachedPortalItem();

      // Compose the request URI for downloading the item's file contents.
      final requestUri = Uri.parse('${portalItem.uri}/data');

      // Prepare a temporary "downloading" directory for use during the download.
      final downloadingDir = resource.downloadingDirectory();
      if (downloadingDir.existsSync()) {
        downloadingDir.deleteSync(recursive: true);
      }
      downloadingDir.createSync(recursive: true);

      // Identify the destination within the downloading directory.
      final destinationFile = File(
        path.join(downloadingDir.path, portalItem.name),
      );

      // Download it!
      await ArcGISHttpClient.download(
        requestUri,
        destinationFile.uri,
        requestInfo: RequestInfo(
          requestCancelToken: requestCancelToken,
          onReceiveProgress: (bytesReceived, totalBytes) {
            // Calculate progress: completed items + current item progress
            final currentItemProgress = bytesReceived / (totalBytes ?? 1);
            final overallProgress =
                (completedItems + currentItemProgress) /
                _downloadableResources.length;

            final nextProgress = (overallProgress * 100).round();
            if (nextProgress != currentProgress) {
              currentProgress = nextProgress;
              onProgress?.call(currentProgress);
            }
          },
        ),
      );

      // Now that the download has completed successfully, prepare the final "downloaded" directory.
      // (This prevents partial downloads from being mistaken for completed downloads.)
      final downloadedDir = resource.downloadedDirectory();
      if (downloadedDir.existsSync()) {
        downloadedDir.deleteSync(recursive: true);
      }

      if (destinationFile.path.contains('.zip')) {
        // Zip files: extract to the downloaded directory and delete the temporary.
        await ZipFile.extractToDirectory(
          zipFile: destinationFile,
          destinationDir: downloadedDir,
        );
        downloadingDir.deleteSync(recursive: true);
      } else {
        // Non-zip files: rename the temporary directory to the final downloaded directory.
        downloadingDir.renameSync(downloadedDir.path);
      }

      ++completedItems;
    }

    onProgress?.call(100);
  }

  /// Cleans up downloaded files and extracted directories for this offline data.
  void cleanupFiles() {
    try {
      for (final resource in _downloadableResources) {
        final portalItemJsonFile = resource.portalItemJsonFile();
        if (portalItemJsonFile.existsSync()) {
          portalItemJsonFile.deleteSync();
        }
        final downloadingDir = resource.downloadingDirectory();
        if (downloadingDir.existsSync()) {
          downloadingDir.deleteSync(recursive: true);
        }
        final downloadedDir = resource.downloadedDirectory();
        if (downloadedDir.existsSync()) {
          downloadedDir.deleteSync(recursive: true);
        }
      }
    } on FileSystemException catch (e) {
      // Ignore errors during cleanup - file may not exist or may be locked.
      debugPrint('Cleanup warning: ${e.message}');
    }
  }

  /// Returns the expected file paths of the downloaded resources after extraction.
  ///
  /// For ZIP resources, returns the path to the resource inside the extracted directory.
  /// For non-ZIP resources, returns the direct file path.
  Future<List<String>> downloadedFilePaths() async {
    return Future.wait(
      _downloadableResources.map((r) async {
        final portalItem = await r.cachedPortalItem();
        final downloadedDir = r.downloadedDirectory();

        if (portalItem.name.toLowerCase().endsWith('.zip')) {
          // For ZIP files, return the path to the resource inside the extracted directory.
          return r.resource != null
              ? path.join(downloadedDir.path, r.resource)
              : downloadedDir.path;
        } else {
          // For non-ZIP files, return the direct file path.
          return path.join(downloadedDir.path, portalItem.name);
        }
      }),
    );
  }
}
