import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/category_card.dart';
import 'package:flutter/material.dart';

class AnimatedCategoryCard extends StatelessWidget {

  const AnimatedCategoryCard({
    required this.category,
    required this.onClick,
    super.key,
  });
  final SampleCategory category;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: CategoryCard(
        category: category,
        onClick: onClick,
      ),
    );
  }
}
