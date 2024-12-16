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

import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

/// A mixin that overrides `setState` to first check if the widget is mounted.
/// (Calling `setState` on an unmounted widget causes an exception.)
mixin SampleStateSupport<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  /// Shows an alert dialog with the given [message].
  void showMessageDialog(String message, {String title = 'Info', bool showOK = false}) {
    if (mounted) {
      showAlertDialog(context,  message, title: title, displayOkButton: showOK);
    }
  }
}
