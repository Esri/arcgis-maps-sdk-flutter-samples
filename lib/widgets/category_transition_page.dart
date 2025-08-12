//
// Copyright 2025 Esri
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
import 'package:go_router/go_router.dart';

/// Custom transition page for category navigation (scale + fade + curve).
class CategoryTransitionPage extends CustomTransitionPage<void> {
  CategoryTransitionPage({required super.child})
    : super(
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(curved),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}
