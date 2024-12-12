import 'package:flutter/material.dart';

///
/// A widget that displays a circular progress indicator when [isVisible] is true.
/// - [isVisible] : A boolean value to determine the visibility of the loading 
///                 indicator.
class LoadingIndicator extends StatelessWidget {
  final bool isVisible;

  const LoadingIndicator({required this.isVisible, super.key});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: const SizedBox.expand(
        child: ColoredBox(
          color: Colors.white30,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}