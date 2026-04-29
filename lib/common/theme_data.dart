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

// Dark Theme Color Scheme with softer surfaces.
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: .dark,
  // Surfaces for Material-style soft dark tones.
  surface: const Color(0xFF2C2C2E),
  surfaceContainerLowest: const Color(0xFF1C1C1E),
  surfaceContainerLow: const Color(0xFF232326),
  surfaceContainer: const Color(0xFF2C2C2E),
  surfaceContainerHigh: const Color(0xFF36363A),
  surfaceContainerHighest: const Color(0xFF42424A),
);

// This shared builder ensures light and dark themes stay in sync.
ThemeData _buildTheme(ColorScheme colorScheme) {
  return ThemeData(
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,

    scaffoldBackgroundColor: colorScheme.surface,

    // Application bar theme.
    appBarTheme: AppBarTheme(backgroundColor: colorScheme.inversePrimary),

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

    // Floating Action Button theme.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),

    // Icon theme for dropdown arrows and other icons.
    iconTheme: IconThemeData(
      color: colorScheme.onSurface,  // Light: dark grey, Dark: light grey
      size: 24,
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
      textStyle: TextStyle(color: colorScheme.onSurface),
    ),

    // Controls DropdownButton menu appearance.
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
      ),
    ),

    // Text selection theme (affects dropdown selected items).
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primaryContainer,
      selectionHandleColor: colorScheme.primary,
    ),

    // Progress Indicator theme.
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      circularTrackColor: colorScheme.surfaceContainerHighest,
      linearMinHeight: 6,
    ),

    // Dialog theme with surface background color.
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHigh,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// Light theme for the sample viewer app
final sampleViewerLightTheme = _buildTheme(lightColorScheme);

// Dark theme for the sample viewer app
final sampleViewerDarkTheme = _buildTheme(darkColorScheme);

extension CustomTextTheme on TextTheme {
  TextStyle get customLabelStyle =>
      const TextStyle(fontSize: 18, fontWeight: .bold, color: Colors.white);

  TextStyle get categoryCardLabelStyle =>
      const TextStyle(fontSize: 16, fontWeight: .bold, color: Colors.white);

  TextStyle get customErrorStyle => const TextStyle(color: Colors.red);

  TextStyle get customWhiteStyle => const TextStyle(color: Colors.white);
}

