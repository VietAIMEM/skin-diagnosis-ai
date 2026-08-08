import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diagnosis_result.dart';
import '../services/llm/prompt_builder.dart';
import '../utils/extensions.dart';
import 'confidence_bar.dart';

/// Special chat card showing the local model analysis result.
class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({
    super.key,
    required this.result,
    this.onViewDetails,
  });

  final DiagnosisResult result;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.biotech_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Image Analysis',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (result.imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(result.imagePath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Prediction',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${displayNameFor(result.predictedClass)} (${result.predictedClass})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Confidence',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          ConfidenceBar(value: result.confidence),
          const SizedBox(height: 4),
          Text(
            '${result.confidence.asPercent()}%',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Model: ${result.modelDisplayName}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (onViewDetails != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View Detailed Results'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
