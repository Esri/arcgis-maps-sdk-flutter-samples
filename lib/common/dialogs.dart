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

///
/// Shows an alert dialog with a message.
/// - [context]: The context in which the dialog is shown.
/// - [message]: The message to display in the dialog.
/// - [title]: (Optional) The title of the dialog.
/// - [showOK]: (Optional) A boolean value to determine if the dialog should show an OK button.

Future<void> showAlertDialog(
  BuildContext context,
  String message, {
  String title = 'Alert',
  bool showOK = false,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      content: Text(message),
      actions: showOK
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ]
          : null,
    ),
  );
}
