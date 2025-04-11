import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/category_card.dart';
import 'package:flutter/material.dart';

class TapScaleCard extends StatefulWidget {

  const TapScaleCard({required this.category, required this.onClick, super.key});
  final SampleCategory category;
  final VoidCallback onClick;

  @override
  State<TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<TapScaleCard> with SingleTickerProviderStateMixin {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onClick();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: CategoryCard(
          category: widget.category,
          onClick: widget.onClick,
        ),
      ),
    );
  }
}
