import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

/// Extension to create theme-aware CalloutStyle for ArcGIS MapView callouts.
///
/// Ensures callouts automatically adapt to light/dark mode using Material 3
/// ColorScheme values instead of hard-coded Colors.white/black.
extension ThemedCalloutStyle on CalloutStyle {
  /// Creates a CalloutStyle that respects the current theme's ColorScheme.
  ///
  /// Usage:
  /// ```dart
  /// _mapViewController.callout.showAt(
  ///   point,
  ///   detail: 'Address text',
  ///   style: CalloutStyle.themed(context),
  /// );
  /// ```
  static CalloutStyle themed(
    BuildContext context, {
    EdgeInsets? contentPadding,
    Offset? offset,
    double? maxWidth,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CalloutStyle(
      // Use elevated surface color for better visual hierarchy
      backgroundColor: colorScheme.surfaceContainerHigh,

      // Border color with theme-aware opacity
      borderColor: colorScheme.outline.withValues(alpha: 0.3),
      borderRadius: 12,

      // Text styles that respect theme colors
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      detailTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),

      // Layout properties (use provided values or sensible defaults)
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      offset: offset ?? const Offset(0, -35),
      maxWidth: maxWidth ?? 300,
      minWidth: 100,
    );
  }
}
