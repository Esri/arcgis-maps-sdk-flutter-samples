//
// Copyright 2026 Esri
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

class MapBanner extends StatelessWidget {
  const MapBanner({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(10),
          color: ColorScheme.of(context).surface.withValues(alpha: 0.7),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: .center,
                  style: TextTheme.of(context).labelMedium,
                  maxLines: 4,
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
