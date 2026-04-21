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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom transition page to ripple out from a given screen offset.
class RippleTransitionPage extends CustomTransitionPage<void> {
  RippleTransitionPage({required this.position, required super.child})
    : super(
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, _, child) {
          final screenSize = MediaQuery.sizeOf(context);
          final diagonal = sqrt(
            pow(screenSize.width, 2) + pow(screenSize.height, 2),
          );

          final rippleAnim =
              Tween<double>(
                begin: 0,
                end: diagonal, // ensures ripple reaches all corners.
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return AnimatedBuilder(
            animation: rippleAnim,
            builder: (context, _) {
              final size = rippleAnim.value;

              return SizedBox.expand(
                child: ClipRRect(
                  child: ClipPath(
                    clipper: _RippleClipper(center: position, radius: size),
                    child: child,
                  ),
                ),
              );
            },
          );
        },
      );

  final Offset position;
}

class _RippleClipper extends CustomClipper<Path> {
  _RippleClipper({required this.center, required this.radius});
  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_RippleClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}
