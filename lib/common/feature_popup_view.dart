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
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';

// Widget to display the details of a single Feature.
class FeaturePopupView extends StatelessWidget {
  const FeaturePopupView({required this.feature, this.onClose, super.key});

  // The feature to display.
  final Feature feature;

  // Optional function to call when the popup is closed.
  final void Function()? onClose;

  @override
  Widget build(BuildContext context) {
    // Create a PopupDefinition with a title based on the feature name.
    final popupDefinition = PopupDefinition.withGeoElement(feature);
    popupDefinition.title = feature.attributes['name'] as String? ?? '';

    return PopupView(
      popup: Popup(geoElement: feature, popupDefinition: popupDefinition),
      onClose: onClose,
    );
  }
}
