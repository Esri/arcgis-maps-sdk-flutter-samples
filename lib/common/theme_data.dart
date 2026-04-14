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

// Light Theme
final sampleViewerLightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  primaryColor: lightColorScheme.primary,

  // Application bar theme
  appBarTheme: AppBarTheme(backgroundColor: lightColorScheme.inversePrimary),

  // Text theme
  textTheme: const TextTheme(labelMedium: TextStyle(color: Colors.deepPurple)),

  // Button themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
    ),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: lightColorScheme.primaryContainer,
  ),

  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      outlineBorder: BorderSide(width: 0),
      border: InputBorder.none,
    ),
    menuStyle: MenuStyle(elevation: WidgetStateProperty.all(6)),
  ),

  // Icon theme
  iconTheme: IconThemeData(color: lightColorScheme.primary),
);

// Dark Theme
final sampleViewerDarkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  primaryColor: darkColorScheme.primary,

  // Application bar theme
  appBarTheme: AppBarTheme(backgroundColor: darkColorScheme.inversePrimary),

  // Text theme - adjusted for dark mode
  textTheme: TextTheme(labelMedium: TextStyle(color: darkColorScheme.primary)),

  // Button themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Colors.black.withValues(alpha: 0.3),
    ),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkColorScheme.primaryContainer,
  ),

  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      outlineBorder: BorderSide(width: 0),
      border: InputBorder.none,
    ),
    menuStyle: MenuStyle(elevation: WidgetStateProperty.all(6)),
  ),

  // Icon theme
  iconTheme: IconThemeData(color: darkColorScheme.primary),
);

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
