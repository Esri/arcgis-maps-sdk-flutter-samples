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

final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

final sampleViewerTheme = ThemeData(
  // color scheme
  primaryColor: colorScheme.primary,
  primaryColorLight: Colors.deepPurple[200],
  disabledColor: Colors.grey,
  colorScheme: colorScheme,

  // application bar theme
  appBarTheme: AppBarTheme(backgroundColor: colorScheme.inversePrimary),

  // text theme
  textTheme: const TextTheme(labelMedium: TextStyle(color: Colors.deepPurple)),

  // button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: colorScheme.primaryContainer,
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: const InputDecorationTheme(
      outlineBorder: BorderSide(width: 0),
    ),
    menuStyle: MenuStyle(elevation: WidgetStateProperty.all(6)),
  ),

  // icon theme
  iconTheme: IconThemeData(color: colorScheme.primary),
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
