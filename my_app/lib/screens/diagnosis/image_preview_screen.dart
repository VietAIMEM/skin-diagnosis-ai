import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Shows the selected image and lets the user start local inference.
class ImagePreviewScreen extends ConsumerStatefulWidget {
  const ImagePreviewScreen({super.key, this.args});

  final Object? args;

  @override
  ConsumerState<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends ConsumerState<ImagePreviewScreen> {
  late final String _imagePath;
  bool _busy = false;

  String get _imagePathFromArgs {
    if (widget.args is String) return widget.args as String;
    if (widget.args is Map<String, dynamic>) {
      return (widget.args as Map<String, dynamic>)['path'] as String? ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _imagePath = _imagePathFromArgs;
  }

  Future<void> _analyze() async {
    if (_busy) return;
    setState(() => _busy = true);
    final option = ref.read(analysisModelProvider);
    try {
      await ref
          .read(chatProvider.notifier)
          .analyzeImage(_imagePath, option);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Preview')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text('Unable to load image.'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy) ...[
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Running local analysis...'),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _analyze,
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Analyze Image'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
