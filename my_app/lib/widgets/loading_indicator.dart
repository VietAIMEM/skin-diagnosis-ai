import 'package:flutter/material.dart';

/// Small pulsing loading indicator used in chat bubbles.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
