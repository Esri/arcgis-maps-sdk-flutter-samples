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

import 'package:arcgis_maps/arcgis_maps.dart';

/// Represents a resource that can be downloaded for a sample.
class DownloadableResource {
  DownloadableResource({
    required this.portal,
    required this.itemId,
    required this.downloadable,
    this.resource,
  });

  factory DownloadableResource.fromJson(
    Map<String, dynamic> json,
    Portal portal,
  ) {
    return DownloadableResource(
      portal: portal,
      itemId: json['itemId'] as String,
      downloadable: json['downloadable'] as String,
      resource: json['resource'] as String?,
    );
  }

  final Portal portal;
  final String itemId;
  final String downloadable;
  final String? resource;

  PortalItem? _portalItem;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'downloadable': downloadable,
      'resource': resource,
    };
  }

  Future<PortalItem> cachedPortalItem() async {
    if (_portalItem != null) {
      return _portalItem!;
    }

    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: itemId,
    );
    await portalItem.load();
    //fixme save the portalItem JSON to OfflineDataLocation and look for it there before loading from network.

    _portalItem = portalItem;
    return _portalItem!;
  }
}
