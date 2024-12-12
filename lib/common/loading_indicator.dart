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
