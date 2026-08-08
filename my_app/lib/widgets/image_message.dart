import 'dart:io';

import 'package:flutter/material.dart';

/// Displays an image inside a chat bubble.
class ImageMessage extends StatelessWidget {
  const ImageMessage({
    super.key,
    required this.path,
    this.height,
    this.width,
  });

  final String path;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        height: height ?? 180,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height ?? 180,
          width: width ?? 200,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_rounded),
        ),
      ),
    );
  }
}
