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

import 'package:flutter/material.dart';

// Light Theme Color Scheme
final lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

// Dark Theme Color Scheme
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: Brightness.dark,
);

// This shared builder ensures light and dark themes stay in sync,
// differing only by their ColorScheme. Any component theme changes
// automatically apply to both modes.
ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,

    // Application bar theme.
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.inversePrimary,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        // Use ColorScheme for disabled states (works in light & dark)
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),

    // Floating Action Button theme.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),

    // Dropdown menu theme.
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        outlineBorder: BorderSide(width: 0),
        border: InputBorder.none,
      ),
      menuStyle: MenuStyle(
        elevation: WidgetStateProperty.all(6),
        backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainer),
      ),
    ),

    // Icon theme.
    iconTheme: IconThemeData(color: colorScheme.primary),

    // Card theme.
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Field theme.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    ),

    // Divider theme.
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),

    // Bottom Sheet theme.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}

// Light theme for the sample viewer app
final sampleViewerLightTheme = _buildTheme(lightColorScheme);

// Dark theme for the sample viewer app
final sampleViewerDarkTheme = _buildTheme(darkColorScheme);

extension CustomTextTheme on TextTheme {
  TextStyle get customLabelStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  TextStyle get categoryCardLabelStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  TextStyle get customErrorStyle => const TextStyle(color: Colors.red);

  TextStyle get customWhiteStyle => const TextStyle(color: Colors.white);
}
