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

<<<<<<<< HEAD:lib/common/common.dart
export 'bottom_sheet_settings.dart';
export 'dialogs.dart';
export 'loading_indicator.dart';
export 'theme_data.dart';
========
import 'package:flutter/material.dart';

/// A mixin that overrides `setState` to first check if the widget is mounted.
/// (Calling `setState` on an unmounted widget causes an exception.)
mixin SampleStateSupport<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }
}
>>>>>>>> main:lib/utils/sample_state_support.dart
