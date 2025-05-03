import 'package:flutter/material.dart';
import 'test_debug_button.dart';

class TestButtonWrapper extends StatelessWidget {
  final Widget child;

  const TestButtonWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wrap with Material to ensure Overlay is available for tooltip
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          child, // Application content
          const TestDebugButton(), // Debug button yang akan muncul/hilang setiap 30 detik
        ],
      ),
    );
  }
}
