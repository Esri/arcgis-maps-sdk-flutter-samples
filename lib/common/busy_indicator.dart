import 'package:flutter/material.dart';

// This is a widget that is meant to sit atop the widget stack to indicate
// that the system is doing something without blocking user interaction.
// The widget consists of a [CircularProgressIndicator] and a very short [Text]
// label.
class BusyIndicator extends StatelessWidget {
  const BusyIndicator({
    required this.labelText,
    required this.visible,
    super.key,
  });

  final String labelText;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          width: 110,
          height: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(backgroundColor: Colors.white),
              ),
              Text(labelText),
            ],
          ),
        ),
      ),
    );
  }
}
