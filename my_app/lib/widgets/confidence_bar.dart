import 'package:flutter/material.dart';

import '../utils/extensions.dart';

/// A horizontal confidence bar.
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: effectiveColor,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Row with a label and a confidence bar (used in detailed results).
class LabeledConfidenceBar extends StatelessWidget {
  const LabeledConfidenceBar({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ConfidenceBar(value: value, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            '${value.asPercent()}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
