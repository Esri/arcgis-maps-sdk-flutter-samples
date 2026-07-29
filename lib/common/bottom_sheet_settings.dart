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

import 'dart:math';

import 'package:flutter/material.dart';

///
/// The widget has a column layout with a title and a close icon button on the top.
/// The rest of area will be filled with the widgets returned by the [settingsWidgets] function.
///  - [onCloseIconPressed] is called when the close icon is pressed.
///  - [settingsWidgets] is a list of widgets to display in the container.
///  - optional [padding] can be provided to customize the padding of the container.
///  - optional [title] can be provided to customize the title of the container.
///    If not provided, the default title is "Settings".
class BottomSheetSettings extends StatelessWidget {
  const BottomSheetSettings({
    required this.onCloseIconPressed,
    required this.settingsWidgets,
    this.padding,
    this.title,
    super.key,
  });
  final VoidCallback onCloseIconPressed;
  final List<Widget> Function(BuildContext) settingsWidgets;
  final EdgeInsets? padding;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? bottomSheetPadding(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          children: [
            Row(
              children: [
                Text(
                  title ?? 'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCloseIconPressed,
                ),
              ],
            ),
            // Display the setting widgets.
            ...settingsWidgets(context),
          ],
        ),
      ),
    );
  }
}

EdgeInsets bottomSheetPadding(BuildContext context) {
  return EdgeInsets.fromLTRB(
    20,
    5,
    20,
    max(
      20,
      5 +
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
    ),
  );
}
