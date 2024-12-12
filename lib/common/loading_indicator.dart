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
/// A widget that displays a circular progress indicator when [visible] is true.
/// - [visible] : A boolean value to determine the visibility of the loading 
///                 indicator.
class LoadingIndicator extends StatelessWidget {
  final bool visible;

  const LoadingIndicator({required this.visible, super.key});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: const SizedBox.expand(
        child: ColoredBox(
          color: Colors.white30,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
