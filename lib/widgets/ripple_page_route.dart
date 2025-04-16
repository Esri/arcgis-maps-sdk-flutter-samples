import 'package:flutter/material.dart';

class RipplePageRoute extends PageRouteBuilder {
  RipplePageRoute({required this.position, required this.child})
    : super(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (context, animation, _, child) {
          final rippleAnim = Tween<double>(
            begin: 0,
            end: MediaQuery.of(context).size.longestSide * 2,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return AnimatedBuilder(
            animation: rippleAnim,
            builder: (context, _) {
              final size = rippleAnim.value;

              return Stack(
                children: [
                  // The child page masked by a circular clip.
                  ClipPath(
                    clipper: _RippleClipper(center: position, radius: size / 2),
                    child: child,
                  ),
                ],
              );
            },
          );
        },
      );
  final Offset position;
  final Widget child;
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
