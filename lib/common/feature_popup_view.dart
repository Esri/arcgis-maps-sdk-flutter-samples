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
