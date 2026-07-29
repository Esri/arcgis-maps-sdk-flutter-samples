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
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
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
    return downloadableResources.every(
      (resource) => File(
        path.join(
          OfflineDataLocation.instance.location.path,
          resource.downloadable,
        ),
      ).existsSync(),
    );
  }
}
